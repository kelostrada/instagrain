defmodule InstagrainWeb.PostLive.ShareComponent do
  use InstagrainWeb, :live_component

  alias Instagrain.Accounts
  alias Instagrain.Conversations
  alias Instagrain.Profiles

  import InstagrainWeb.UserComponents

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       post_id: nil,
       suggested_users: [],
       search_query: "",
       search_results: [],
       selected_users: [],
       message: ""
     )}
  end

  @impl true
  def update(%{post_id: post_id} = assigns, socket)
      when not is_nil(post_id) and post_id != socket.assigns.post_id do
    suggested_users = Profiles.list_following(assigns.current_user.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       suggested_users: suggested_users,
       search_query: "",
       search_results: suggested_users,
       selected_users: [],
       message: ""
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Desktop modal --%>
      <.modal id="share-modal" corner_style={:xl}>
        <div class="max-sm:hidden w-[90vw] max-w-[550px] max-h-[75vh] flex flex-col">
          <.share_content
            myself={@myself}
            post_id={@post_id}
            search_query={@search_query}
            search_results={@search_results}
            selected_users={@selected_users}
            suggested_users={@suggested_users}
            message={@message}
            close_action={hide_modal("share-modal")}
          />
        </div>
      </.modal>

      <%!-- Mobile full-screen --%>
      <div
        id="share-mobile"
        class="sm:hidden fixed inset-0 bg-white z-[60] flex flex-col overflow-hidden hidden"
      >
        <.share_content
          myself={@myself}
          post_id={@post_id}
          search_query={@search_query}
          search_results={@search_results}
          selected_users={@selected_users}
          suggested_users={@suggested_users}
          message={@message}
          close_action={JS.hide(to: "#share-mobile")}
        />
      </div>
    </div>
    """
  end

  defp share_content(assigns) do
    assigns =
      assign(assigns,
        url: InstagrainWeb.Endpoint.url() <> "/p/#{assigns.post_id}",
        encoded_text:
          URI.encode_www_form(
            "Check out this post: " <> InstagrainWeb.Endpoint.url() <> "/p/#{assigns.post_id}"
          )
      )

    ~H"""
    <%!-- Header --%>
    <div class="flex items-center justify-between px-4 py-3 border-b flex-shrink-0">
      <button type="button" phx-click={@close_action} class="cursor-pointer">
        <.icon name="hero-x-mark" class="h-6 w-6" />
      </button>
      <h2 class="font-bold text-base">Share</h2>
      <div class="w-6"></div>
    </div>

    <%!-- Search --%>
    <div class="flex items-center gap-2 px-4 py-2 border-b flex-shrink-0">
      <.icon name="hero-magnifying-glass" class="h-4 w-4 text-neutral-400 flex-shrink-0" />
      <form phx-change="share-search" phx-target={@myself} class="grow">
        <input
          type="text"
          name="query"
          value={@search_query}
          placeholder="Search..."
          autocomplete="off"
          phx-debounce="300"
          class="w-full border-0 focus:ring-0 text-sm placeholder:text-neutral-400 p-1"
        />
      </form>
    </div>

    <%!-- Scrollable user list --%>
    <div class="overflow-y-auto grow min-h-0">
      <%= if @search_query == "" do %>
        <div class="grid max-sm:grid-cols-3 sm:grid-cols-4 gap-2 p-4">
          <div
            :for={user <- @suggested_users}
            class="flex flex-col items-center gap-1 cursor-pointer relative"
            phx-click="toggle-share-user"
            phx-value-id={user.id}
            phx-target={@myself}
          >
            <div class="relative">
              <.avatar size={:lg} user={user} />
              <%= if Enum.any?(@selected_users, & &1.id == user.id) do %>
                <div class="absolute -bottom-0.5 -right-0.5 w-5 h-5 rounded-full bg-blue-500 flex items-center justify-center border-2 border-white">
                  <.icon name="hero-check" class="h-3 w-3 text-white" />
                </div>
              <% end %>
            </div>
            <p class="text-xs text-center truncate w-full">
              <%= user.full_name || user.username %>
            </p>
          </div>
        </div>
      <% else %>
        <div
          :for={user <- @search_results}
          class="flex items-center gap-3 px-4 py-2 hover:bg-neutral-50 cursor-pointer"
          phx-click="toggle-share-user"
          phx-value-id={user.id}
          phx-target={@myself}
        >
          <.avatar size={:md} user={user} />
          <div class="grow min-w-0">
            <p class="font-semibold text-sm truncate"><%= user.full_name || user.username %></p>
            <p class="text-sm text-neutral-500 truncate"><%= user.username %></p>
          </div>
          <div class="flex-shrink-0">
            <%= if Enum.any?(@selected_users, & &1.id == user.id) do %>
              <div class="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center">
                <.icon name="hero-check" class="h-4 w-4 text-white" />
              </div>
            <% else %>
              <div class="w-6 h-6 rounded-full border-2 border-neutral-300"></div>
            <% end %>
          </div>
        </div>
        <p :if={@search_results == []} class="px-4 py-8 text-sm text-neutral-500 text-center">
          No results found.
        </p>
      <% end %>
    </div>

    <%!-- Bottom section: message+send OR external links --%>
    <div class="flex-shrink-0">
      <%= if @selected_users != [] do %>
        <%!-- Message input + Send (covers external links) --%>
        <div class="border-t px-4 py-3 space-y-3">
          <form phx-change="share-message-edit" phx-target={@myself}>
            <input
              type="text"
              name="message"
              value={@message}
              placeholder="Write a message..."
              autocomplete="off"
              class="w-full border-0 focus:ring-0 text-sm placeholder:text-neutral-400 p-0"
            />
          </form>
          <button
            type="button"
            phx-click="send-share"
            phx-target={@myself}
            class="w-full py-2.5 rounded-lg text-white font-bold text-sm bg-blue-500 hover:bg-blue-600 cursor-pointer"
          >
            Send
          </button>
        </div>
      <% else %>
        <%!-- External share options --%>
        <div class="border-t px-4 py-3">
          <div class="flex gap-4 overflow-x-auto">
            <button
              type="button"
              id={"copy-link-#{@post_id}"}
              phx-hook="CopyToClipboard"
              data-clipboard-text={@url}
              class="flex flex-col items-center gap-1 cursor-pointer flex-shrink-0"
            >
              <div class="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center">
                <.icon name="hero-link" class="h-5 w-5" />
              </div>
              <span class="text-xs">Copy Link</span>
            </button>
            <a
              :for={
                {name, icon, href} <- [
                  {"Facebook", "hero-globe-alt", "https://www.facebook.com/sharer/sharer.php?u=" <> URI.encode_www_form(@url) <> "&quote=" <> @encoded_text},
                  {"WhatsApp", "hero-chat-bubble-left", "https://wa.me/?text=" <> @encoded_text},
                  {"Messenger", "hero-chat-bubble-oval-left", "https://www.facebook.com/msg/share/?link=" <> URI.encode_www_form(@url)},
                  {"Email", "hero-envelope", "mailto:?subject=Check%20this%20out&body=" <> @encoded_text},
                  {"Threads", "hero-at-symbol", "https://www.threads.net/intent/post?text=" <> @encoded_text},
                  {"X", "hero-arrow-up-right", "https://x.com/intent/post?text=" <> @encoded_text}
                ]
              }
              href={href}
              target="_blank"
              rel="noopener noreferrer"
              class="flex flex-col items-center gap-1 flex-shrink-0 cursor-pointer"
            >
              <div class="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center">
                <.icon name={icon} class="h-5 w-5" />
              </div>
              <span class="text-xs"><%= name %></span>
            </a>
            <button
              type="button"
              id={"native-share-#{@post_id}"}
              phx-hook="NativeShare"
              data-share-url={@url}
              data-share-title="Check out this post"
              class="flex flex-col items-center gap-1 flex-shrink-0 cursor-pointer"
            >
              <div class="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center">
                <.icon name="hero-arrow-up-on-square" class="h-5 w-5" />
              </div>
              <span class="text-xs">See All</span>
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("share-search", %{"query" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        socket.assigns.suggested_users
      else
        Accounts.search_users(query, 20)
        |> Enum.reject(&(&1.id == socket.assigns.current_user.id))
      end

    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  def handle_event("toggle-share-user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    selected = socket.assigns.selected_users

    if Enum.any?(selected, &(&1.id == user_id)) do
      {:noreply, assign(socket, selected_users: Enum.reject(selected, &(&1.id == user_id)))}
    else
      all_users = socket.assigns.search_results ++ socket.assigns.suggested_users
      user = Enum.find(all_users, &(&1.id == user_id))

      if user do
        {:noreply, assign(socket, selected_users: selected ++ [user])}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("share-message-edit", %{"message" => message}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  def handle_event("send-share", _params, socket) do
    post_id = socket.assigns.post_id
    current_user_id = socket.assigns.current_user.id
    message = String.trim(socket.assigns.message)
    post_url = InstagrainWeb.Endpoint.url() <> "/p/#{post_id}"
    full_message = if message == "", do: post_url, else: "#{message}\n#{post_url}"

    Conversations.ConversationsSupervisor.start_server(current_user_id)

    for user <- socket.assigns.selected_users do
      conversation = Conversations.create_conversation(current_user_id, [user.id])
      Conversations.send_message(current_user_id, conversation.id, full_message)
    end

    send(self(), {__MODULE__, :share_sent})

    {:noreply,
     socket
     |> assign(post_id: nil, selected_users: [], search_query: "", message: "")
     |> push_event("close-share-modal", %{})}
  end

end
