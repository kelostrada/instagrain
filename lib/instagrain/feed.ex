defmodule Instagrain.Feed do
  @moduledoc """
  The Feed context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Instagrain.Repo

  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Comment
  alias Instagrain.Feed.Post.CommentLike
  alias Instagrain.Feed.Post.Like
  alias Instagrain.Feed.Post.Resource
  alias Instagrain.Feed.Post.Save

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(current_user_id, page \\ 0) do
    limit = 3
    offset = 3 * page

    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      left_join: s in Save,
      on: s.post_id == p.id and s.user_id == ^current_user_id,
      order_by: {:desc, p.inserted_at},
      offset: ^offset,
      limit: ^limit,
      select: %{
        p
        | liked_by_current_user?: not is_nil(l.post_id),
          saved_by_current_user?: not is_nil(s.post_id)
      }
    )
    |> Repo.all()
    |> Repo.preload([:user, :resources, comments: [:user, :comment_likes]])
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
    |> Repo.preload([:user, :resources, comments: [:user, :comment_likes]])
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
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
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
    post
    |> Post.changeset(attrs)
    |> Repo.update()
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
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
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
end
