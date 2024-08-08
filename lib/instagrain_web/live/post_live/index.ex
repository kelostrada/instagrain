defmodule InstagrainWeb.PostLive.Index do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed
  alias Instagrain.Feed.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:posts, Feed.list_posts(socket.assigns.current_user.id))
     |> assign(page: 0, end_reached?: false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Feed.get_post!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create new post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, nil)
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({InstagrainWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  def handle_info({InstagrainWeb.PostLive.PostComponent, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Feed.get_post!(id)
    {:ok, _} = Feed.delete_post(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  def handle_event("load-more", _, socket) do
    posts = Feed.list_posts(socket.assigns.current_user.id, socket.assigns.page + 1)

    if posts == [] do
      {:noreply, assign(socket, end_reached?: true)}
    else
      socket =
        Enum.reduce(posts, socket, fn post, socket ->
          stream_insert(socket, :posts, post)
        end)

      {:noreply, assign(socket, page: socket.assigns.page + 1)}
    end
  end
end
