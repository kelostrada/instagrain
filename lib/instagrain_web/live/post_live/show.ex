defmodule InstagrainWeb.PostLive.Show do
  use InstagrainWeb, :live_view

  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, top_nav: mobile_nav_header(%{navigate: ~p"/", title: "Post"}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:other_posts, Feed.list_other_posts(post))}
  end

  @impl true
  def handle_info({_, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_info({_, {:post_updated, post}}, socket) do
    {:noreply, assign(socket, post: post)}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
