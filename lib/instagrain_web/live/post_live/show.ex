defmodule InstagrainWeb.PostLive.Show do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Feed.get_post!(id, socket.assigns.current_user.id))}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
