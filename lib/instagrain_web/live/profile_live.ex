defmodule InstagrainWeb.ProfileLive do
  use InstagrainWeb, :live_view
  alias Instagrain.Profiles
  alias Instagrain.Repo

  import InstagrainWeb.PostComponents

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    profile = Profiles.get_profile(username)
    current_user = Repo.preload(socket.assigns.current_user, [:followers, :followings])
    {:ok, socket |> assign(profile: profile, current_user: current_user)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({_, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  @impl true
  def handle_event("follow", _, socket) do
    case Profiles.follow_user(socket.assigns.current_user.id, socket.assigns.profile.id) do
      {:ok, _follow} ->
        profile = socket.assigns.profile |> Repo.preload([:followers], force: true)
        current_user = socket.assigns.current_user |> Repo.preload([:followings], force: true)

        {:noreply, assign(socket, profile: profile, current_user: current_user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Follow failed")}
    end
  end

  def handle_event("unfollow", _, socket) do
    case Profiles.unfollow_user(socket.assigns.current_user.id, socket.assigns.profile.id) do
      :ok ->
        profile = socket.assigns.profile |> Repo.preload([:followers], force: true)
        current_user = socket.assigns.current_user |> Repo.preload([:followings], force: true)

        {:noreply, assign(socket, profile: profile, current_user: current_user)}

      _ ->
        {:noreply, put_flash(socket, :error, "Unfollow failed")}
    end
  end
end
