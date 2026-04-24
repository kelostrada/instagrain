defmodule Instagrain.Feed do
  @moduledoc """
  The Feed context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Instagrain.Repo

  alias Instagrain.Feed.Hashtag
  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Comment
  alias Instagrain.Feed.Post.CommentLike
  alias Instagrain.Feed.Post.Like
  alias Instagrain.Feed.Post.Resource
  alias Instagrain.Feed.Post.Impression
  alias Instagrain.Feed.PostHashtag
  alias Instagrain.Feed.Post.Save
  alias Instagrain.Feed.Location
  alias Instagrain.Notifications

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(current_user_id, page \\ 0, seed \\ nil) do
    page_size = 3
    seed = seed || (:rand.uniform() |> Float.to_string())
    total_before = page * page_size

    following_ids = following_user_ids(current_user_id)
    {liked_tag_ids, liked_location_ids} = interest_signals(current_user_id)

    if following_ids == [] do
      # Cold-start: user follows no one → feed is pure discovery, with interest boost
      feed_query(current_user_id, seed, :discovery, liked_tag_ids, liked_location_ids)
      |> offset(^total_before)
      |> limit(^page_size)
      |> Repo.all()
      |> preload_and_process(current_user_id)
    else
      # Every 5th post is a discovery post from non-followed users
      slots = Enum.map(0..(page_size - 1), fn i -> rem(total_before + i, 5) == 4 end)
      discovery_on_page = Enum.count(slots, & &1)
      followed_on_page = page_size - discovery_on_page

      discovery_before = div(total_before, 5)
      followed_before = total_before - discovery_before

      followed =
        feed_query(current_user_id, seed, :followed, liked_tag_ids, liked_location_ids)
        |> offset(^followed_before)
        |> limit(^followed_on_page)
        |> Repo.all()

      discovery =
        feed_query(current_user_id, seed, :discovery, liked_tag_ids, liked_location_ids)
        |> offset(^discovery_before)
        |> limit(^discovery_on_page)
        |> Repo.all()

      interleave(slots, followed, discovery)
      |> preload_and_process(current_user_id)
    end
  end

  defp interleave(slots, followed, discovery) do
    {result, _, _} =
      Enum.reduce(slots, {[], followed, discovery}, fn is_discovery?, {acc, f, d} ->
        {primary, fallback} = if is_discovery?, do: {d, f}, else: {f, d}

        case {primary, fallback} do
          {[post | rest], _} ->
            if is_discovery?, do: {[post | acc], f, rest}, else: {[post | acc], rest, d}

          {[], [post | rest]} ->
            if is_discovery?, do: {[post | acc], rest, d}, else: {[post | acc], f, rest}

          {[], []} ->
            {acc, f, d}
        end
      end)

    Enum.reverse(result)
  end

  defp following_user_ids(current_user_id) do
    Repo.all(from f in "follows", where: f.user_id == ^current_user_id, select: f.follow_id)
  end

  # Pulls hashtag + location ids from the user's most recently liked posts, to seed
  # content-similarity boosts in the discovery feed. Capped to keep the IN-list short.
  defp interest_signals(current_user_id) do
    recent_liked_post_ids =
      from(l in Like,
        where: l.user_id == ^current_user_id,
        order_by: [desc: l.inserted_at],
        limit: 50,
        select: l.post_id
      )
      |> Repo.all()

    if recent_liked_post_ids == [] do
      {[], []}
    else
      tag_ids =
        from(ph in PostHashtag,
          where: ph.post_id in ^recent_liked_post_ids,
          select: ph.hashtag_id,
          distinct: true
        )
        |> Repo.all()

      location_ids =
        from(p in Post,
          where: p.id in ^recent_liked_post_ids and not is_nil(p.location_id),
          select: p.location_id,
          distinct: true
        )
        |> Repo.all()

      {tag_ids, location_ids}
    end
  end

  defp feed_query(current_user_id, seed, source, liked_tag_ids, liked_location_ids) do
    base =
      from(p in Post,
        left_join: l in Like,
        on: l.post_id == p.id and l.user_id == ^current_user_id,
        left_join: s in Save,
        on: s.post_id == p.id and s.user_id == ^current_user_id,
        left_join: f in "follows",
        on: f.follow_id == p.user_id and f.user_id == ^current_user_id,
        left_join: imp in Impression,
        on: imp.post_id == p.id and imp.user_id == ^current_user_id,
        where: p.user_id != ^current_user_id,
        select: %{
          p
          | liked_by_current_user?: not is_nil(l.post_id),
            saved_by_current_user?: not is_nil(s.post_id)
        }
      )

    base =
      case source do
        :followed -> from([_p, _l, _s, f, _imp] in base, where: not is_nil(f.follow_id))
        :discovery -> from([_p, _l, _s, f, _imp] in base, where: is_nil(f.follow_id))
      end

    apply_scoring(base, seed, source, liked_tag_ids, liked_location_ids)
  end

  # Score formula combines: deterministic randomness (per-user seed), recency,
  # engagement (likes + comments), impression-penalty, and a content-interest
  # boost (matching hashtags + location) when the user has liked things before.
  defp apply_scoring(query, seed, source, liked_tag_ids, liked_location_ids) do
    {rand_weight, recency_weight, engagement_weight, engagement_cap} =
      case source do
        :followed -> {10, 3, 2, 8}
        :discovery -> {15, 2, 3, 12}
      end

    # Interest boost: only meaningful for discovery; for followed we already trust the follow signal
    {tag_boost, location_boost} =
      case source do
        :discovery -> {4, 6}
        :followed -> {2, 2}
      end

    tag_ids = if liked_tag_ids == [], do: [-1], else: liked_tag_ids
    loc_ids = if liked_location_ids == [], do: [-1], else: liked_location_ids

    order_by(query, [p, _l, _s, _f, imp],
      desc:
        fragment(
          """
          (('x' || left(md5(CAST(? AS text) || ?), 8))::bit(32)::int::float / 2147483647.0 * ?)
          + (EXTRACT(EPOCH FROM (? - NOW())) / 86400.0 + 7) * ?
          + LEAST(LN(GREATEST(? + COALESCE((SELECT COUNT(*) FROM post_comments WHERE post_id = ?), 0), 1) + 1) * ?, ?)
          - (COALESCE(?, 0) * 3)
          + LEAST(COALESCE((SELECT COUNT(*) FROM post_hashtags WHERE post_id = ? AND hashtag_id = ANY(?)), 0), 3) * ?
          + (CASE WHEN ? = ANY(?) THEN 1 ELSE 0 END) * ?
          """,
          p.id,
          ^seed,
          ^rand_weight,
          p.inserted_at,
          ^recency_weight,
          p.likes,
          p.id,
          ^engagement_weight,
          ^engagement_cap,
          imp.view_count,
          p.id,
          ^tag_ids,
          ^tag_boost,
          p.location_id,
          ^loc_ids,
          ^location_boost
        )
    )
  end

  @doc """
  Records impressions for a list of posts shown to a user.
  Uses upsert to increment view_count on repeat views.

  `weight` controls how much each impression counts (default 1).
  Use higher weight for direct post views (e.g., 3).
  """
  def record_impressions(user_id, post_ids, weight \\ 1)
  def record_impressions(_user_id, [], _weight), do: {0, nil}

  def record_impressions(user_id, post_ids, weight) when is_list(post_ids) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(post_ids, fn post_id ->
        %{
          user_id: user_id,
          post_id: post_id,
          view_count: weight,
          last_seen_at: now,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(
      Impression,
      entries,
      on_conflict:
        from(imp in Impression,
          update: [
            set: [
              view_count: fragment("? + ?", imp.view_count, ^weight),
              last_seen_at: ^now,
              updated_at: ^now
            ]
          ]
        ),
      conflict_target: [:user_id, :post_id]
    )
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(post_id, current_user_id) do
    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      where: p.id == ^post_id,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      }
    )
    |> Repo.one!()
    |> Repo.preload([:user, :resources, :location, comments: [:user, :comment_likes]])
    |> then(fn post ->
      comments =
        Enum.map(post.comments, fn comment ->
          %{
            comment
            | liked_by_current_user?:
                Enum.any?(comment.comment_likes, fn like ->
                  like.user_id == current_user_id
                end)
          }
        end)

      %{post | comments: comments}
    end)
  end

  @doc """
  Returns the list of user posts paginated

  ## Examples

      iex> list_user_posts(1, 2)
      [%Post{}, ...]

  """
  def list_user_posts(user_id, current_user_id, page \\ 0, limit \\ 9) do
    offset = limit * page

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      where: p.user_id == ^user_id,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: {:desc, p.inserted_at},
      offset: ^offset,
      limit: ^limit
    )
    |> Repo.all()
    |> Repo.preload([:resources, :user, :location, comments: [:user, :comment_likes]])
    |> Enum.map(fn post ->
      comments =
        Enum.map(post.comments, fn comment ->
          %{
            comment
            | liked_by_current_user?:
                Enum.any?(comment.comment_likes, fn like ->
                  like.user_id == current_user_id
                end)
          }
        end)

      %{post | comments: comments}
    end)
  end

  @doc """
  Returns the list of saved posts by user paginated

  ## Examples

      iex> list_saved_posts(1, 2)
      [%Post{}, ...]

  """
  def list_saved_posts(current_user_id, page \\ 0, limit \\ 9) do
    offset = limit * page

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: {:desc, s.inserted_at},
      offset: ^offset,
      limit: ^limit
    )
    |> Repo.all()
    |> Repo.preload([:resources, :user, :location, comments: [:user, :comment_likes]])
    |> Enum.map(fn post ->
      comments =
        Enum.map(post.comments, fn comment ->
          %{
            comment
            | liked_by_current_user?:
                Enum.any?(comment.comment_likes, fn like ->
                  like.user_id == current_user_id
                end)
          }
        end)

      %{post | comments: comments}
    end)
  end

  @doc """
  Returns the list of other posts from the same poster

  ## Examples

      iex> list_other_posts(post)
      [%Post{}, ...]

  """
  def search_posts_by_caption(query, current_user_id, limit \\ 20) do
    pattern = "%#{query}%"

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      where: ilike(p.caption, ^pattern),
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: {:desc, p.inserted_at},
      limit: ^limit
    )
    |> Repo.all()
    |> Repo.preload([:resources, :user, :location, comments: [:user, :comment_likes]])
  end

  def list_explore_posts(current_user_id, seed, page \\ 0, limit \\ 18) do
    offset = limit * page

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: fragment("md5(? || ?)", p.id, ^seed),
      offset: ^offset,
      limit: ^limit
    )
    |> Repo.all()
    |> preload_and_process(current_user_id)
  end

  def list_other_posts(%Post{id: id, user_id: user_id}, limit \\ 6) do
    from(p in Post,
      where: p.user_id == ^user_id and p.id != ^id,
      order_by: {:desc, p.inserted_at},
      limit: ^limit
    )
    |> Repo.all()
    |> Repo.preload([:resources, :comments])
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:post, Post.changeset(%Post{}, attrs))
    |> Multi.run(:hashtags, fn _repo, %{post: post} ->
      sync_hashtags(post)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} -> {:ok, post}
      {:error, :post, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    Multi.new()
    |> Multi.update(:post, Post.changeset(post, attrs))
    |> Multi.run(:hashtags, fn _repo, %{post: updated_post} ->
      # Remove old hashtag links and decrement counts
      old_hashtag_ids =
        Repo.all(from ph in PostHashtag, where: ph.post_id == ^post.id, select: ph.hashtag_id)

      if old_hashtag_ids != [] do
        Repo.delete_all(from ph in PostHashtag, where: ph.post_id == ^post.id)
        Repo.update_all(from(h in Hashtag, where: h.id in ^old_hashtag_ids), inc: [post_count: -1])
      end

      sync_hashtags(updated_post)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} -> {:ok, post}
      {:error, :post, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    # Decrement hashtag counts before deletion (junction rows auto-delete via on_delete)
    hashtag_ids =
      Repo.all(from ph in PostHashtag, where: ph.post_id == ^post.id, select: ph.hashtag_id)

    if hashtag_ids != [] do
      Repo.update_all(from(h in Hashtag, where: h.id in ^hashtag_ids), inc: [post_count: -1])
    end

    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Returns the list of post_resources.

  ## Examples

      iex> list_post_resources()
      [%Resource{}, ...]

  """
  def list_post_resources do
    Repo.all(Resource)
  end

  @doc """
  Gets a single resource.

  Raises `Ecto.NoResultsError` if the Resource does not exist.

  ## Examples

      iex> get_resource!(123)
      %Resource{}

      iex> get_resource!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource!(id), do: Repo.get!(Resource, id)

  @doc """
  Creates a resource.

  ## Examples

      iex> create_resource(%{field: value})
      {:ok, %Resource{}}

      iex> create_resource(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource.

  ## Examples

      iex> update_resource(resource, %{field: new_value})
      {:ok, %Resource{}}

      iex> update_resource(resource, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource.

  ## Examples

      iex> delete_resource(resource)
      {:ok, %Resource{}}

      iex> delete_resource(resource)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.

  ## Examples

      iex> change_resource(resource)
      %Ecto.Changeset{data: %Resource{}}

  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  @doc """
  Creates a like, updates post.
  """
  def like(post_id, user_id) do
    Multi.new()
    |> Multi.insert(:like, Like.changeset(%Like{}, %{post_id: post_id, user_id: user_id}))
    |> Multi.update_all(
      :post_update,
      from(p in Post, where: p.id == ^post_id),
      inc: [likes: 1]
    )
    |> Multi.one(:post, from(p in Post, where: p.id == ^post_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} ->
        Notifications.create(%{
          user_id: post.user_id,
          actor_id: user_id,
          type: "like",
          post_id: post.id
        })

        {:ok, %{post | liked_by_current_user?: true}}

      error ->
        error
    end
  end

  def unlike(post_id, user_id) do
    Multi.new()
    |> Multi.delete_all(
      :delete_like,
      from(l in Like, where: l.post_id == ^post_id and l.user_id == ^user_id)
    )
    |> Multi.update_all(
      :post_update,
      from(p in Post, where: p.id == ^post_id),
      inc: [likes: -1]
    )
    |> Multi.one(:post, from(p in Post, where: p.id == ^post_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} ->
        Notifications.delete(post.user_id, user_id, "like", post_id: post.id)
        {:ok, %{post | liked_by_current_user?: false}}

      error ->
        error
    end
  end

  @doc """
  Returns the list of post_comments.

  ## Examples

      iex> list_post_comments()
      [%Comment{}, ...]

  """
  def list_post_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    case %Comment{} |> Comment.changeset(attrs) |> Repo.insert() do
      {:ok, comment} = ok ->
        notify_new_comment(comment)
        ok

      error ->
        error
    end
  end

  defp notify_new_comment(comment) do
    post = Repo.get(Post, comment.post_id)

    if post do
      Notifications.create(%{
        user_id: post.user_id,
        actor_id: comment.user_id,
        type: "comment",
        post_id: post.id,
        comment_id: comment.id
      })
    end
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  @doc """
  Creates a like for comment, updates comment likes count.
  """
  def like_comment(comment_id, user_id) do
    Multi.new()
    |> Multi.insert(
      :comment_like,
      CommentLike.changeset(%CommentLike{}, %{comment_id: comment_id, user_id: user_id})
    )
    |> Multi.update_all(
      :comment_update,
      from(c in Comment, where: c.id == ^comment_id),
      inc: [likes: 1]
    )
    |> Multi.one(:comment, from(c in Comment, where: c.id == ^comment_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{comment: comment}} ->
        Notifications.create(%{
          user_id: comment.user_id,
          actor_id: user_id,
          type: "like_comment",
          post_id: comment.post_id,
          comment_id: comment.id
        })

        {:ok, %{comment | liked_by_current_user?: true}}

      error ->
        error
    end
  end

  def unlike_comment(comment_id, user_id) do
    Multi.new()
    |> Multi.delete_all(
      :delete_comment_like,
      from(cl in CommentLike, where: cl.comment_id == ^comment_id and cl.user_id == ^user_id)
    )
    |> Multi.update_all(
      :comment_update,
      from(c in Comment, where: c.id == ^comment_id),
      inc: [likes: -1]
    )
    |> Multi.one(:comment, from(c in Comment, where: c.id == ^comment_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{comment: comment}} ->
        Notifications.delete(comment.user_id, user_id, "like_comment", comment_id: comment.id)
        {:ok, %{comment | liked_by_current_user?: false}}

      error ->
        error
    end
  end

  def save_post(post_id, user_id) do
    %Save{}
    |> Save.changeset(%{post_id: post_id, user_id: user_id})
    |> Repo.insert()
  end

  def remove_save_post(post_id, user_id) do
    case Repo.delete_all(from s in Save, where: s.post_id == ^post_id and s.user_id == ^user_id) do
      {1, _} -> :ok
      _ -> {:error, :not_found}
    end
  end

  defp preload_and_process(posts, current_user_id) when is_list(posts) do
    posts
    |> Repo.preload([:user, :resources, :location, comments: [:user, :comment_likes]])
    |> Enum.map(fn post ->
      comments =
        Enum.map(post.comments, fn comment ->
          %{
            comment
            | liked_by_current_user?:
                Enum.any?(comment.comment_likes, &(&1.user_id == current_user_id))
          }
        end)

      %{post | comments: comments}
    end)
  end

  # --- Hashtag functions ---

  @doc """
  Extracts hashtag names from a caption string.
  Returns a list of unique, lowercase tag names without the `#` prefix.
  """
  def extract_hashtags(nil), do: []

  def extract_hashtags(caption) do
    Regex.scan(~r/(?<!\S)#([a-zA-Z0-9_]+)/, caption)
    |> Enum.map(fn [_, tag] -> String.downcase(tag) end)
    |> Enum.uniq()
  end

  @doc """
  Searches hashtags by partial name match, ordered by post_count.
  """
  def search_hashtags(query, limit \\ 20) do
    pattern = "#{String.downcase(String.trim_leading(query, "#"))}%"

    from(h in Hashtag,
      where: ilike(h.name, ^pattern) and h.post_count > 0,
      order_by: [desc: h.post_count],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns posts for a given hashtag name, paginated.
  """
  def list_posts_by_hashtag(tag_name, current_user_id, page \\ 0, limit \\ 18) do
    offset = limit * page

    from(p in Post,
      join: ph in PostHashtag,
      on: ph.post_id == p.id,
      join: h in Hashtag,
      on: h.id == ph.hashtag_id,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      where: h.name == ^String.downcase(tag_name),
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: [desc: p.inserted_at],
      offset: ^offset,
      limit: ^limit
    )
    |> Repo.all()
    |> preload_and_process(current_user_id)
  end

  @doc """
  Gets a hashtag by its name.
  """
  def get_hashtag_by_name(name) do
    Repo.get_by(Hashtag, name: String.downcase(name))
  end

  defp sync_hashtags(post) do
    tag_names = extract_hashtags(post.caption)

    if tag_names == [] do
      {:ok, []}
    else
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entries =
        Enum.map(tag_names, fn name ->
          %{name: name, post_count: 0, inserted_at: now, updated_at: now}
        end)

      Repo.insert_all(Hashtag, entries, on_conflict: :nothing, conflict_target: :name)

      hashtags = Repo.all(from(h in Hashtag, where: h.name in ^tag_names))

      junction_entries =
        Enum.map(hashtags, fn h ->
          %{post_id: post.id, hashtag_id: h.id, inserted_at: now, updated_at: now}
        end)

      Repo.insert_all(PostHashtag, junction_entries, on_conflict: :nothing)

      hashtag_ids = Enum.map(hashtags, & &1.id)
      Repo.update_all(from(h in Hashtag, where: h.id in ^hashtag_ids), inc: [post_count: 1])

      {:ok, hashtags}
    end
  end

  # --- Locations ---

  def search_locations(query) do
    Instagrain.Feed.LocationSearch.search(query)
  end

  def search_locations_db(query, limit \\ 10)
  def search_locations_db(query, _limit) when byte_size(query) < 2, do: []

  def search_locations_db(query, limit) do
    query_str = "%#{String.trim(query)}%"

    from(l in Location,
      left_join: p in Post,
      on: p.location_id == l.id,
      where: ilike(l.name, ^query_str),
      group_by: l.id,
      select: %{id: l.id, name: l.name, address: l.address, post_count: count(p.id)},
      order_by: [desc: count(p.id)],
      having: count(p.id) > 0,
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_posts_by_location(location_id, current_user_id, page \\ 0, limit \\ 18) do
    offset = limit * page

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      where: p.location_id == ^location_id,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      },
      order_by: [desc: p.inserted_at],
      offset: ^offset,
      limit: ^limit
    )
    |> Repo.all()
    |> preload_and_process(current_user_id)
  end

  def get_location(id), do: Repo.get(Location, id)

  def find_or_create_location(%{name: name} = attrs) when is_binary(name) and name != "" do
    case Repo.get_by(Location, name: name) do
      nil ->
        %Location{}
        |> Location.changeset(Map.take(attrs, [:name, :address, :lat, :lng]))
        |> Repo.insert()

      location ->
        {:ok, location}
    end
  end

  def find_or_create_location(_), do: {:ok, nil}
end
