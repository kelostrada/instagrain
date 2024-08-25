defmodule InstagrainWeb.ProfileLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Feed
  alias Instagrain.Profiles
  alias Instagrain.Repo

  import InstagrainWeb.PostComponents

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    profile = Profiles.get_profile(username)
    current_user = Repo.preload(socket.assigns.current_user, [:followers, :followings])

    {:ok,
     socket
     |> assign(profile: profile, current_user: current_user, page: 0, end_reached?: false)
     |> stream(:posts, [])
     |> fetch_posts()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({_, {:error, message}}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_info({_, {:post_updated, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
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

  def handle_event("load-more", _, socket) do
    {:noreply, fetch_posts(socket)}
  end

  defp fetch_posts(socket) do
    posts =
      case socket.assigns.live_action do
        :posts ->
          Feed.list_user_posts(
            socket.assigns.profile.id,
            socket.assigns.current_user.id,
            socket.assigns.page
          )

        :saved ->
          Feed.list_saved_posts(
            socket.assigns.current_user.id,
            socket.assigns.page
          )
      end

    if posts == [] do
      assign(socket, end_reached?: true)
    else
      socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)
    end
  end
end
