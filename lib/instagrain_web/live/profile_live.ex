defmodule InstagrainWeb.ProfileLive do
  use InstagrainWeb, :live_view
  alias Instagrain.Profiles

  import InstagrainWeb.PostComponents

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    profile = Profiles.get_profile(username)
    {:ok, socket |> assign(profile: profile)}
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
end
