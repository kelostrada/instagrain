defmodule InstagrainWeb.NotificationsComponent do
  use InstagrainWeb, :live_component

  import Ecto.Query
  import InstagrainWeb.UserComponents

  alias Instagrain.Accounts.User
  alias Instagrain.Profiles
  alias Instagrain.Repo

  def mount(socket) do
    {:ok, assign(socket, filter: :all, suggestions: nil, following_user_ids: [])}
  end

  def update(assigns, socket) do
    current_user = assigns.current_user
    following_ids = Profiles.list_following(current_user.id) |> Enum.map(& &1.id)

    {:ok,
     assign(socket,
       id: assigns.id,
       variant: Map.get(assigns, :variant, :panel),
       current_user: current_user,
       following_user_ids: following_ids,
       suggestions: socket.assigns.suggestions || suggested_users(current_user.id, following_ids)
     )}
  end

  def handle_event("filter", %{"kind" => kind}, socket) when kind in ["all", "comments"] do
    {:noreply, assign(socket, filter: String.to_existing_atom(kind))}
  end

  def handle_event("follow", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    Profiles.follow_user(socket.assigns.current_user.id, user_id)
    {:noreply, assign(socket, following_user_ids: [user_id | socket.assigns.following_user_ids])}
  end

  def handle_event("unfollow", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    Profiles.unfollow_user(socket.assigns.current_user.id, user_id)

    {:noreply,
     assign(socket,
       following_user_ids: List.delete(socket.assigns.following_user_ids, user_id)
     )}
  end

  # Mocked "Suggested for you" — picks users the current user doesn't follow.
  # Will be replaced with a real recommender once the UI is approved.
  defp suggested_users(current_user_id, following_ids) do
    exclude_ids = [current_user_id | following_ids]

    from(u in User,
      where: u.id not in ^exclude_ids,
      order_by: fragment("RANDOM()"),
      limit: 7
    )
    |> Repo.all()
    |> Enum.map(fn user ->
      mutuals = mutual_followers(user.id, current_user_id)
      %{user: user, name: user.full_name || "No Info", reason: reason_line(mutuals)}
    end)
  end

  defp mutual_followers(suggested_user_id, current_user_id) do
    from(u in User,
      join: their_f in "follows",
      on: their_f.user_id == u.id and their_f.follow_id == ^suggested_user_id,
      join: my_f in "follows",
      on: my_f.follow_id == u.id and my_f.user_id == ^current_user_id,
      order_by: [asc: u.username],
      select: u.username
    )
    |> Repo.all()
  end

  defp reason_line([]), do: "Suggested for you"
  defp reason_line([a]), do: "Followed by #{a}"
  defp reason_line([a, b]), do: "Followed by #{a} and #{b}"

  defp reason_line([a, b | rest]),
    do: "Followed by #{a}, #{b} + #{length(rest)} more"

  def render(%{variant: :panel} = assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed top-0 left-0 bottom-0 w-[400px] bg-white border-r border-neutral-200 shadow-xl z-40 flex-col hidden overflow-y-auto"
      phx-click-away={hide_notifications_panel()}
    >
      <div class="p-6 pb-3">
        <h2 class="text-2xl font-bold mb-5">Notifications</h2>
        <.filter_tabs filter={@filter} target={@myself} />
      </div>

      <div class="border-t border-neutral-200 flex-1">
        <.notifications_body
          suggestions={@suggestions}
          following_user_ids={@following_user_ids}
          target={@myself}
          on_navigate={hide_notifications_panel()}
        />
      </div>
    </div>
    """
  end

  def render(%{variant: :full_page} = assigns) do
    ~H"""
    <div id={@id} class="max-w-2xl mx-auto">
      <div class="px-4 sm:px-6 pt-4 pb-3 max-sm:hidden">
        <h2 class="text-2xl font-bold mb-5">Notifications</h2>
        <.filter_tabs filter={@filter} target={@myself} />
      </div>

      <div class="sm:hidden px-4 pt-3 pb-2">
        <.filter_tabs filter={@filter} target={@myself} />
      </div>

      <div class="sm:border-t sm:border-neutral-200">
        <.notifications_body
          suggestions={@suggestions}
          following_user_ids={@following_user_ids}
          target={@myself}
          on_navigate={nil}
        />
      </div>
    </div>
    """
  end

  attr :filter, :atom, required: true
  attr :target, :any, required: true

  defp filter_tabs(assigns) do
    ~H"""
    <div class="flex gap-2">
      <button
        phx-click="filter"
        phx-value-kind="all"
        phx-target={@target}
        class={[
          "px-4 py-1.5 text-sm rounded-full border transition-colors",
          @filter == :all && "bg-neutral-200 border-neutral-200 font-semibold",
          @filter != :all && "border-neutral-300 hover:bg-neutral-100"
        ]}
      >
        All
      </button>
      <button
        phx-click="filter"
        phx-value-kind="comments"
        phx-target={@target}
        class={[
          "px-4 py-1.5 text-sm rounded-full border transition-colors",
          @filter == :comments && "bg-neutral-200 border-neutral-200 font-semibold",
          @filter != :comments && "border-neutral-300 hover:bg-neutral-100"
        ]}
      >
        Comments
      </button>
    </div>
    """
  end

  attr :suggestions, :list, required: true
  attr :following_user_ids, :list, required: true
  attr :target, :any, required: true
  attr :on_navigate, :any, default: nil

  defp notifications_body(assigns) do
    ~H"""
    <div class="flex flex-col items-center text-center py-10 px-6">
      <div class="w-16 h-16 rounded-full border-2 border-black flex items-center justify-center mb-4">
        <.icon name="hero-heart" class="w-8 h-8" />
      </div>
      <h3 class="text-base font-medium">Activity on your posts</h3>
      <p class="text-sm text-neutral-500 mt-1">
        When someone likes or comments on one of your posts, you'll see it here.
      </p>
    </div>

    <div :if={@suggestions != []} class="px-6 pb-8">
      <h3 class="text-base font-bold mb-2">Suggested for you</h3>

      <ul class="divide-y divide-neutral-100">
        <li
          :for={%{user: user, name: name, reason: reason} <- @suggestions}
          class="flex items-center gap-3 py-3"
        >
          <.link navigate={~p"/#{user.username}"} phx-click={@on_navigate}>
            <.avatar user={user} size={:md} />
          </.link>
          <div class="flex-1 min-w-0">
            <.link
              navigate={~p"/#{user.username}"}
              phx-click={@on_navigate}
              class="block truncate"
            >
              <span class="text-sm font-semibold"><%= user.username %></span>
            </.link>
            <p class="text-xs text-neutral-500 truncate"><%= name %></p>
            <p class="text-xs text-neutral-500 truncate"><%= reason %></p>
          </div>
          <button
            :if={user.id not in @following_user_ids}
            phx-click="follow"
            phx-value-user-id={user.id}
            phx-target={@target}
            class="px-4 py-1.5 text-sm font-semibold rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white"
          >
            Follow
          </button>
          <button
            :if={user.id in @following_user_ids}
            phx-click="unfollow"
            phx-value-user-id={user.id}
            phx-target={@target}
            class="px-4 py-1.5 text-sm font-semibold rounded-lg bg-neutral-200 hover:bg-neutral-300 text-black"
          >
            Following
          </button>
        </li>
      </ul>
    </div>
    """
  end

  defp hide_notifications_panel do
    %Phoenix.LiveView.JS{}
    |> Phoenix.LiveView.JS.hide(
      to: "#notifications-panel",
      transition: {"transition-transform duration-300", "translate-x-0", "-translate-x-full"}
    )
  end
end
