defmodule InstagrainWeb.ExploreLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Accounts
  alias Instagrain.Feed

  import InstagrainWeb.PostComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page: 0, end_reached?: false, search_query: "", search_results: [], searching?: false)
     |> stream(:posts, [])
     |> fetch_posts()}
  end

  @impl true
  def handle_event("load-more", _, socket) do
    {:noreply, fetch_posts(socket)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      {:noreply, assign(socket, search_query: "", search_results: [], searching?: false)}
    else
      users = Accounts.search_users(query, 20)

      results =
        if users != [] do
          Enum.map(users, fn user -> {:user, user} end)
        else
          posts = Feed.search_posts_by_caption(query, socket.assigns.current_user.id, 20)
          Enum.map(posts, fn post -> {:post, post} end)
        end

      {:noreply, assign(socket, search_query: query, search_results: results, searching?: true)}
    end
  end

  def handle_event("clear-search", _, socket) do
    {:noreply, assign(socket, search_query: "", search_results: [], searching?: false)}
  end

  defp fetch_posts(socket) do
    posts =
      Feed.list_explore_posts(
        socket.assigns.current_user.id,
        socket.assigns.page
      )

    if posts == [] do
      assign(socket, end_reached?: true)
    else
      socket |> assign(page: socket.assigns.page + 1) |> stream(:posts, posts, at: -1)
    end
  end
end
