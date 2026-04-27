defmodule InstagrainWeb.PostLive.Show do
  use InstagrainWeb, :live_view
  use InstagrainWeb.PostLive.MenuHandlers

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def mount(_params, _session, socket) do
    following_ids =
      Instagrain.Profiles.list_following(socket.assigns.current_user.id) |> Enum.map(& &1.id)

    {:ok,
     assign(socket,
       top_nav: mobile_nav_header(%{title: "Post"}),
       share_post_id: nil,
       following_user_ids: following_ids,
       editing_post: nil
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    # Direct post view has weight 3 (higher impact than feed scroll)
    Feed.record_impressions(socket.assigns.current_user.id, [post.id], 3)

    base_url = InstagrainWeb.Endpoint.url()

    {og_image, og_image_type} =
      case post.resources do
        [resource | _] -> InstagrainWeb.Media.resource_og(resource)
        _ -> {nil, nil}
      end

    caption = post.caption || ""

    og_desc =
      if String.length(caption) > 200, do: String.slice(caption, 0, 197) <> "...", else: caption

    {:noreply,
     socket
     |> assign(:page_title, "#{post.user.username} on Instagrain")
     |> assign(:og_title, "#{post.user.full_name || post.user.username} on Instagrain")
     |> assign(
       :og_description,
       if(og_desc == "", do: "View this post on Instagrain", else: og_desc)
     )
     |> assign(:og_image, og_image)
     |> assign(:og_image_type, og_image_type)
     |> assign(:og_url, "#{base_url}/p/#{post.id}")
     |> assign(:og_type, "article")
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

  def handle_info({InstagrainWeb.PostLive.IconsComponent, {:open_share, post_id}}, socket) do
    {:noreply, assign(socket, share_post_id: post_id)}
  end

  def handle_info({InstagrainWeb.PostLive.ShareComponent, :share_sent}, socket) do
    {:noreply, assign(socket, share_post_id: nil)}
  end

  @impl true
  def handle_event("menu-follow", %{"post_user_id" => user_id}, socket) do
    Instagrain.Profiles.follow_user(socket.assigns.current_user.id, user_id)
    {:noreply, assign(socket, following_user_ids: [user_id | socket.assigns.following_user_ids])}
  end

  def handle_event("menu-unfollow", %{"post_user_id" => user_id}, socket) do
    Instagrain.Profiles.unfollow_user(socket.assigns.current_user.id, user_id)

    {:noreply,
     assign(socket, following_user_ids: List.delete(socket.assigns.following_user_ids, user_id))}
  end
end
