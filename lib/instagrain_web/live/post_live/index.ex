defmodule InstagrainWeb.PostLive.Index do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:posts, Feed.list_posts(socket.assigns.current_user.id))
     |> assign(page: 0, end_reached?: false)}
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

  @impl true
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
