defmodule InstagrainWeb.PostLive.Index do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed

  alias Instagrain.Profiles

  @impl true
  def mount(_params, _session, socket) do
    seed = :rand.uniform() |> Float.to_string()

    following_ids =
      Profiles.list_following(socket.assigns.current_user.id) |> Enum.map(& &1.id)

    posts = Feed.list_posts(socket.assigns.current_user.id, 0, seed)
    Feed.record_impressions(socket.assigns.current_user.id, Enum.map(posts, & &1.id))

    {:ok,
     socket
     |> stream(:posts, posts)
     |> assign(
       page: 0,
       end_reached?: false,
       share_post_id: nil,
       following_user_ids: following_ids,
       feed_seed: seed,
       editing_post: nil
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({InstagrainWeb.PostLive.PostComponent, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_info({_, {:post_updated, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  def handle_info({InstagrainWeb.PostLive.EditFormComponent, :close}, socket) do
    {:noreply, assign(socket, editing_post: nil)}
  end

  def handle_info({InstagrainWeb.PostLive.IconsComponent, {:open_share, post_id}}, socket) do
    {:noreply, assign(socket, share_post_id: post_id)}
  end

  def handle_info({InstagrainWeb.PostLive.ShareComponent, :share_sent}, socket) do
    {:noreply, assign(socket, share_post_id: nil)}
  end

  @impl true
  def handle_event("menu-follow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Instagrain.Profiles.follow_user(socket.assigns.current_user.id, user_id)
    following_ids = [user_id | socket.assigns.following_user_ids]

    send_update(InstagrainWeb.PostLive.PostComponent,
      id: post_id,
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("menu-unfollow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Instagrain.Profiles.unfollow_user(socket.assigns.current_user.id, user_id)
    following_ids = List.delete(socket.assigns.following_user_ids, user_id)

    send_update(InstagrainWeb.PostLive.PostComponent,
      id: post_id,
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)
    {:ok, _} = Feed.delete_post(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  def handle_event("confirm-delete-post", %{"id" => id}, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    if post.user_id == socket.assigns.current_user.id do
      {:ok, _} = Feed.delete_post(post)
      {:noreply, socket |> put_flash(:info, "Post deleted.") |> stream_delete(:posts, post)}
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own posts.")}
    end
  end

  def handle_event("menu-toggle-hide-likes", %{"id" => id}, socket) do
    {:noreply, toggle_post_field(socket, id, :hide_likes)}
  end

  def handle_event("menu-toggle-comments", %{"id" => id}, socket) do
    {:noreply, toggle_post_field(socket, id, :disable_comments)}
  end

  def handle_event("menu-edit", %{"id" => id}, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    if post.user_id == socket.assigns.current_user.id do
      {:noreply, assign(socket, editing_post: post)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close-edit-modal", _, socket) do
    {:noreply, assign(socket, editing_post: nil)}
  end

  def handle_event("load-more", _, socket) do
    next_page = socket.assigns.page + 1
    posts = Feed.list_posts(socket.assigns.current_user.id, next_page, socket.assigns.feed_seed)

    if posts == [] do
      {:noreply, assign(socket, end_reached?: true)}
    else
      Feed.record_impressions(socket.assigns.current_user.id, Enum.map(posts, & &1.id))

      {:noreply,
       socket
       |> assign(page: next_page)
       |> stream(:posts, posts, at: -1)}
    end
  end

  defp toggle_post_field(socket, id, field) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    if post.user_id != socket.assigns.current_user.id do
      put_flash(socket, :error, "You can only edit your own posts.")
    else
      {:ok, updated} = Feed.update_post(post, %{field => !Map.get(post, field)})
      fresh = Feed.get_post!(updated.id, socket.assigns.current_user.id)
      stream_insert(socket, :posts, fresh)
    end
  end
end
