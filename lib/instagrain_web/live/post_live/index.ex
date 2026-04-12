defmodule InstagrainWeb.PostLive.Index do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed

  alias Instagrain.Profiles

  @impl true
  def mount(_params, _session, socket) do
    following_ids =
      Profiles.list_following(socket.assigns.current_user.id) |> Enum.map(& &1.id)

    {:ok,
     socket
     |> stream(:posts, Feed.list_posts(socket.assigns.current_user.id))
     |> assign(page: 0, end_reached?: false, share_post_id: nil, following_user_ids: following_ids)}
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

  def handle_info({InstagrainWeb.PostLive.IconsComponent, {:open_share, post_id}}, socket) do
    {:noreply, assign(socket, share_post_id: post_id)}
  end

  def handle_info({InstagrainWeb.PostLive.ShareComponent, :share_sent}, socket) do
    {:noreply, assign(socket, share_post_id: nil)}
  end

  @impl true
  def handle_event("menu-follow", %{"post_user_id" => user_id}, socket) do
    Instagrain.Profiles.follow_user(socket.assigns.current_user.id, user_id)
    {:noreply, assign(socket, following_user_ids: [user_id | socket.assigns.following_user_ids])}
  end

  def handle_event("menu-unfollow", %{"post_user_id" => user_id}, socket) do
    Instagrain.Profiles.unfollow_user(socket.assigns.current_user.id, user_id)
    {:noreply, assign(socket, following_user_ids: List.delete(socket.assigns.following_user_ids, user_id))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)
    {:ok, _} = Feed.delete_post(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  def handle_event("load-more", _, socket) do
    posts = Feed.list_posts(socket.assigns.current_user.id, socket.assigns.page + 1)

    if posts == [] do
      {:noreply, assign(socket, end_reached?: true)}
    else
      {:noreply, socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)}
    end
  end
end
