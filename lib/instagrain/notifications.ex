defmodule Instagrain.Notifications do
  @moduledoc """
  Tracks and delivers in-app notifications (follow, like, comment, like_comment).

  Persists to the `notifications` table and broadcasts a `{:notification_changed, user_id}`
  message on the per-user PubSub topic so LiveViews can refresh their unread badge.
  """

  import Ecto.Query, warn: false

  alias Instagrain.Notifications.Notification
  alias Instagrain.Repo

  @pubsub Instagrain.PubSub

  def topic(user_id), do: "user:#{user_id}:notifications"

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  @doc """
  Inserts a notification and broadcasts a change event to the recipient.
  Silently skips self-notifications (actor == recipient). Uses a unique index
  so repeated actions (e.g. like → unlike → like) don't pile up rows.
  """
  def create(attrs) do
    user_id = Map.get(attrs, :user_id) || Map.get(attrs, "user_id")
    actor_id = Map.get(attrs, :actor_id) || Map.get(attrs, "actor_id")

    if user_id == actor_id do
      {:ok, :self}
    else
      type = Map.get(attrs, :type) || Map.get(attrs, "type")
      post_id = Map.get(attrs, :post_id) || Map.get(attrs, "post_id")
      comment_id = Map.get(attrs, :comment_id) || Map.get(attrs, "comment_id")

      # Delete any existing matching row so repeated actions bump the row's
      # inserted_at and reset the seen_at flag without piling up duplicates.
      delete_matching(user_id, actor_id, type, post_id, comment_id)

      result =
        %Notification{}
        |> Notification.changeset(attrs)
        |> Repo.insert()

      case result do
        {:ok, _} = ok ->
          broadcast_change(user_id)
          ok

        error ->
          error
      end
    end
  end

  defp delete_matching(user_id, actor_id, type, post_id, comment_id) do
    query =
      from n in Notification,
        where: n.user_id == ^user_id and n.actor_id == ^actor_id and n.type == ^type

    query =
      case post_id do
        nil -> where(query, [n], is_nil(n.post_id))
        id -> where(query, [n], n.post_id == ^id)
      end

    query =
      case comment_id do
        nil -> where(query, [n], is_nil(n.comment_id))
        id -> where(query, [n], n.comment_id == ^id)
      end

    Repo.delete_all(query)
  end

  @doc """
  Deletes the specific notification matching the actor/type/(post|comment) tuple.
  Used when the originating action is reversed (unfollow, unlike).
  """
  def delete(user_id, actor_id, type, keys \\ []) do
    post_id = Keyword.get(keys, :post_id)
    comment_id = Keyword.get(keys, :comment_id)

    query =
      from n in Notification,
        where:
          n.user_id == ^user_id and
            n.actor_id == ^actor_id and
            n.type == ^type

    query = if post_id, do: where(query, [n], n.post_id == ^post_id), else: query
    query = if comment_id, do: where(query, [n], n.comment_id == ^comment_id), else: query

    {count, _} = Repo.delete_all(query)
    if count > 0, do: broadcast_change(user_id)
    count
  end

  @doc """
  Returns the last 50 notifications for a user, with actors, post and a thumbnail
  resource preloaded. Notifications are ordered newest first.
  """
  def list_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
    |> Repo.preload([:actor, post: :resources])
  end

  @doc """
  Counts unseen notifications for a user.
  """
  def unseen_count(user_id) do
    Repo.aggregate(
      from(n in Notification, where: n.user_id == ^user_id and is_nil(n.seen_at)),
      :count
    )
  end

  @doc """
  Marks all notifications for a user as seen (clears the unread badge).
  """
  def mark_all_seen(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      Repo.update_all(
        from(n in Notification, where: n.user_id == ^user_id and is_nil(n.seen_at)),
        set: [seen_at: now, updated_at: now]
      )

    if count > 0, do: broadcast_change(user_id)
    count
  end

  @doc """
  Groups like-type notifications by post so multiple likes on the same post
  render as a single "a, b and N others liked your photo" row. Returns a list
  of %{type: ..., actors: [...], post: ..., inserted_at: ..., seen?: ...}.
  """
  def group_for_display(notifications) do
    notifications
    |> Enum.chunk_while(
      nil,
      fn n, acc ->
        case acc do
          nil ->
            {:cont, start_group(n)}

          %{type: "like", post_id: pid} = group when n.type == "like" and pid == n.post_id ->
            {:cont, add_actor(group, n)}

          %{type: "like_comment", comment_id: cid} = group
          when n.type == "like_comment" and cid == n.comment_id ->
            {:cont, add_actor(group, n)}

          group ->
            {:cont, finalize(group), start_group(n)}
        end
      end,
      fn
        nil -> {:cont, nil}
        acc -> {:cont, finalize(acc), nil}
      end
    )
    |> Enum.reject(&is_nil/1)
  end

  defp start_group(n) do
    %{
      type: n.type,
      actors: [n.actor],
      post: n.post,
      post_id: n.post_id,
      comment_id: n.comment_id,
      inserted_at: n.inserted_at,
      seen?: not is_nil(n.seen_at),
      count: 1
    }
  end

  defp add_actor(group, n) do
    %{
      group
      | actors: Enum.uniq_by([n.actor | group.actors], & &1.id) |> Enum.take(3),
        count: group.count + 1,
        inserted_at: latest(group.inserted_at, n.inserted_at),
        seen?: group.seen? and not is_nil(n.seen_at)
    }
  end

  defp finalize(group), do: %{group | actors: Enum.reverse(group.actors)}

  defp latest(a, b), do: if(DateTime.compare(a, b) == :lt, do: b, else: a)

  defp broadcast_change(user_id) do
    Phoenix.PubSub.broadcast(@pubsub, topic(user_id), {:notification_changed, user_id})
  end
end
