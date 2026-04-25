defmodule InstagrainWeb.ProfileLive do
  use InstagrainWeb, :live_view
  use InstagrainWeb.PostLive.MenuHandlers

  alias Instagrain.Feed
  alias Instagrain.Profiles
  alias Instagrain.Repo

  import InstagrainWeb.PostComponents

  @impl true
  def handle_params(%{"username" => username}, _url, socket) do
    profile = Profiles.get_profile(username)
    current_user = Repo.preload(socket.assigns.current_user, [:followers, :followings])
    current_user_profile? = profile.id == current_user.id

    base_url = InstagrainWeb.Endpoint.url()
    {og_image, og_image_type} = InstagrainWeb.Media.avatar_og(profile)

    og_desc = profile.description || "#{profile.full_name || profile.username}'s profile on Instagrain"

    {:noreply,
     socket
     |> assign(
       profile: profile,
       current_user: current_user,
       page: 0,
       end_reached?: false,
       current_user_profile?: current_user_profile?,
       share_post_id: nil,
       editing_post: nil,
       following_user_ids: Enum.map(current_user.followings, & &1.id),
       page_title: "#{profile.full_name || profile.username} (@#{profile.username})",
       og_title: "#{profile.full_name || profile.username} (@#{profile.username})",
       og_description: og_desc,
       og_image: og_image,
       og_image_type: og_image_type,
       og_url: "#{base_url}/#{profile.username}",
       og_type: "profile"
     )
     |> stream(:posts, [], reset: true)
     |> fetch_posts()}
  end

  @impl true
  def handle_info({_, {:error, message}}, socket) do
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
  def handle_event("menu-follow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Profiles.follow_user(socket.assigns.current_user.id, user_id)
    following_ids = [user_id | socket.assigns.following_user_ids]

    send_update(InstagrainWeb.PostLive.PostDetailsComponent,
      id: "#post-details-modal-content-#{post_id}",
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("menu-unfollow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Profiles.unfollow_user(socket.assigns.current_user.id, user_id)
    following_ids = List.delete(socket.assigns.following_user_ids, user_id)

    send_update(InstagrainWeb.PostLive.PostDetailsComponent,
      id: "#post-details-modal-content-#{post_id}",
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("follow", _, socket) do
    case Profiles.follow_user(socket.assigns.current_user.id, socket.assigns.profile.id) do
      {:ok, _follow} -> {:noreply, reload_follow_state(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Follow failed")}
    end
  end

  def handle_event("unfollow", _, socket) do
    case Profiles.unfollow_user(socket.assigns.current_user.id, socket.assigns.profile.id) do
      :ok -> {:noreply, reload_follow_state(socket)}
      _ -> {:noreply, put_flash(socket, :error, "Unfollow failed")}
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
      Feed.record_impressions(socket.assigns.current_user.id, Enum.map(posts, & &1.id))

      socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)
    end
  end

  defp reload_follow_state(socket) do
    profile = socket.assigns.profile |> Repo.preload([:followers], force: true)
    current_user = socket.assigns.current_user |> Repo.preload([:followings], force: true)
    following_ids = Enum.map(current_user.followings, & &1.id)

    # Reload all currently loaded posts to refresh stream items (menus inside streams)
    total = (socket.assigns.page + 1) * 9

    posts =
      case socket.assigns.live_action do
        :posts -> Feed.list_user_posts(profile.id, current_user.id, 0, total)
        :saved -> Feed.list_saved_posts(current_user.id, 0, total)
      end

    socket
    |> assign(profile: profile, current_user: current_user, following_user_ids: following_ids)
    |> stream(:posts, posts, reset: true)
  end

end
