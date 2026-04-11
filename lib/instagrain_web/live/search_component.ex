defmodule InstagrainWeb.SearchComponent do
  use InstagrainWeb, :live_component

  alias Instagrain.Accounts
  alias Instagrain.Feed

  def mount(socket) do
    {:ok, assign(socket, search_query: "", search_results: [], searching?: false)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, current_user: assigns.current_user, id: assigns.id)}
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

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed top-0 left-0 bottom-0 w-[400px] bg-white border-r border-neutral-200 shadow-xl z-40 flex-col hidden"
      phx-click-away={hide_search_panel()}
    >
      <div class="p-6 pb-3">
        <h2 class="text-2xl font-semibold mb-5">Search</h2>
        <form phx-change="search" phx-target={@myself} class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400"
          />
          <input
            type="text"
            placeholder="Search"
            value={@search_query}
            phx-debounce="300"
            name="query"
            autocomplete="off"
            class="w-full rounded-lg bg-neutral-100 border-0 py-2.5 pl-10 pr-10 text-sm placeholder:text-neutral-400 focus:ring-0"
          />
          <button
            :if={@search_query != ""}
            type="button"
            phx-click="clear-search"
            phx-target={@myself}
            class="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600"
          >
            <.icon name="hero-x-circle-solid" class="w-4 h-4" />
          </button>
        </form>
      </div>

      <div class="border-t border-neutral-200 flex-1 overflow-y-auto">
        <div :if={@searching? && @search_results != []}>
          <div :for={{type, item} <- @search_results}>
            <%= if type == :user do %>
              <.link
                navigate={~p"/#{item.username}"}
                class="flex items-center gap-3 px-6 py-3 hover:bg-neutral-50"
              >
                <div class="w-11 h-11 rounded-full bg-neutral-200 flex-shrink-0 overflow-hidden">
                  <img
                    :if={item.avatar}
                    src={~p"/uploads/avatars/#{item.avatar}"}
                    class="w-full h-full object-cover"
                  />
                  <div :if={!item.avatar} class="w-full h-full flex items-center justify-center">
                    <.icon name="hero-user" class="w-6 h-6 text-neutral-400" />
                  </div>
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-sm truncate"><%= item.username %></p>
                  <p :if={item.full_name} class="text-sm text-neutral-500 truncate">
                    <%= item.full_name %>
                  </p>
                </div>
              </.link>
            <% else %>
              <.link
                navigate={~p"/p/#{item.id}"}
                class="flex items-center gap-3 px-6 py-3 hover:bg-neutral-50"
              >
                <div class="w-11 h-11 flex-shrink-0 overflow-hidden rounded">
                  <%= if item.resources != [] do %>
                    <img
                      src={~p"/uploads/#{hd(item.resources).file}"}
                      class="w-full h-full object-cover"
                    />
                  <% end %>
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-sm truncate"><%= item.user.username %></p>
                  <p class="text-sm text-neutral-500 truncate"><%= item.caption %></p>
                </div>
              </.link>
            <% end %>
          </div>
        </div>

        <div :if={@searching? && @search_results == []}>
          <p class="px-6 py-8 text-sm text-neutral-500 text-center">No results found.</p>
        </div>

      </div>
    </div>
    """
  end

  defp hide_search_panel do
    %Phoenix.LiveView.JS{}
    |> Phoenix.LiveView.JS.hide(
      to: "#search-panel",
      transition: {"transition-transform duration-300", "translate-x-0", "-translate-x-full"}
    )
  end
end
