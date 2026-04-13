defmodule InstagrainWeb.ExploreLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Accounts
  alias Instagrain.Feed

  import InstagrainWeb.PostComponents

  @impl true
  def mount(_params, _session, socket) do
    following_ids =
      Instagrain.Profiles.list_following(socket.assigns.current_user.id) |> Enum.map(& &1.id)

    {:ok,
     assign(socket,
       search_query: "",
       search_results: [],
       searching?: false,
       share_post_id: nil,
       following_user_ids: following_ids,
       tag: nil,
       hashtag: nil
     )}
  end

  @impl true
  def handle_params(%{"tag" => tag}, _url, socket) do
    hashtag = Feed.get_hashtag_by_name(tag)

    {:noreply,
     socket
     |> assign(
       page: 0,
       end_reached?: false,
       tag: tag,
       hashtag: hashtag,
       searching?: false,
       search_query: ""
     )
     |> stream(:posts, [], reset: true)
     |> fetch_posts()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(
       page: 0,
       end_reached?: false,
       tag: nil,
       hashtag: nil,
       seed: :rand.uniform(1_000_000) |> to_string()
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
    {:noreply,
     socket
     |> assign(share_post_id: nil)
     |> push_event("close-share-modal", %{})}
  end

  @impl true
  def handle_event("menu-follow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Instagrain.Profiles.follow_user(socket.assigns.current_user.id, user_id)
    following_ids = [user_id | socket.assigns.following_user_ids]

    send_update(InstagrainWeb.PostLive.PostDetailsComponent,
      id: "#post-details-modal-content-#{post_id}",
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("menu-unfollow", %{"post_user_id" => user_id, "post_id" => post_id}, socket) do
    Instagrain.Profiles.unfollow_user(socket.assigns.current_user.id, user_id)
    following_ids = List.delete(socket.assigns.following_user_ids, user_id)

    send_update(InstagrainWeb.PostLive.PostDetailsComponent,
      id: "#post-details-modal-content-#{post_id}",
      following_user_ids: following_ids
    )

    {:noreply, assign(socket, following_user_ids: following_ids)}
  end

  def handle_event("load-more", _, socket) do
    {:noreply, fetch_posts(socket)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      {:noreply, assign(socket, search_query: "", search_results: [], searching?: false)}
    else
      hashtags =
        if String.starts_with?(query, "#") or String.match?(query, ~r/^[a-zA-Z0-9_]+$/) do
          Feed.search_hashtags(query, 10)
        else
          []
        end

      users = Accounts.search_users(query, 20)

      results =
        Enum.map(hashtags, fn h -> {:hashtag, h} end) ++
          Enum.map(users, fn u -> {:user, u} end)

      results =
        if results == [] do
          posts = Feed.search_posts_by_caption(query, socket.assigns.current_user.id, 20)
          Enum.map(posts, fn post -> {:post, post} end)
        else
          results
        end

      {:noreply, assign(socket, search_query: query, search_results: results, searching?: true)}
    end
  end

  def handle_event("clear-search", _, socket) do
    {:noreply, assign(socket, search_query: "", search_results: [], searching?: false)}
  end

  defp fetch_posts(%{assigns: %{tag: tag}} = socket) when not is_nil(tag) do
    posts =
      Feed.list_posts_by_hashtag(
        tag,
        socket.assigns.current_user.id,
        socket.assigns.page
      )

    if posts == [] do
      assign(socket, end_reached?: true)
    else
      Feed.record_impressions(socket.assigns.current_user.id, Enum.map(posts, & &1.id))
      socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)
    end
  end

  defp fetch_posts(socket) do
    posts =
      Feed.list_explore_posts(
        socket.assigns.current_user.id,
        socket.assigns.seed,
        socket.assigns.page
      )

    if posts == [] do
      assign(socket, end_reached?: true)
    else
      Feed.record_impressions(socket.assigns.current_user.id, Enum.map(posts, & &1.id))

      socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)
    end
  end
end
