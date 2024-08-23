defmodule InstagrainWeb.PostLive.Show.Comments do
  use InstagrainWeb, :live_view

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def mount(%{"id" => post_id}, _session, socket) do
    top_nav = mobile_nav_header(%{navigate: ~p"/p/#{post_id}", title: "Comments"})
    {:ok, assign(socket, top_nav: top_nav)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Feed.get_post!(id, socket.assigns.current_user.id))}
  end

  @impl true
  def handle_info({_, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_info({_, {:post_updated, post}}, socket) do
    {:noreply, assign(socket, post: post)}
  end

  defp page_title(:show), do: "Comments"
end
