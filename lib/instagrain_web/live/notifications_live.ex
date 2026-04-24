defmodule InstagrainWeb.NotificationsLive do
  use InstagrainWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    top_nav = mobile_nav_header(%{title: "Notifications", navigate: ~p"/"})
    {:ok, assign(socket, top_nav: top_nav)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={InstagrainWeb.NotificationsComponent}
      id="notifications-full-page"
      current_user={@current_user}
      variant={:full_page}
    />
    """
  end
end
