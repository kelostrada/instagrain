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
            id_prefix="desktop"
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
          id_prefix="mobile"
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

    <%= if @post_id do %>
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
                {user.full_name || user.username}
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
              <p class="font-semibold text-sm truncate">{user.full_name || user.username}</p>
              <p class="text-sm text-neutral-500 truncate">{user.username}</p>
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
                id={"#{@id_prefix}-copy-link-#{@post_id}"}
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
                  {name, icon_name, href} <- [
                    {"Facebook", :facebook,
                     "https://www.facebook.com/sharer/sharer.php?u=" <>
                       URI.encode_www_form(@url) <> "&quote=" <> @encoded_text},
                    {"Messenger", :messenger,
                     "https://www.facebook.com/dialog/send?link=" <>
                       URI.encode_www_form(@url) <> "&redirect_uri=" <> URI.encode_www_form(@url)},
                    {"WhatsApp", :whatsapp, "https://wa.me/?text=" <> @encoded_text},
                    {"Email", :email, "mailto:?subject=Check%20this%20out&body=" <> @encoded_text},
                    {"Threads", :threads,
                     "https://www.threads.net/intent/post?text=" <> @encoded_text},
                    {"X", :x, "https://x.com/intent/post?text=" <> @encoded_text}
                  ]
                }
                href={href}
                target="_blank"
                rel="noopener noreferrer"
                class="flex flex-col items-center gap-1 flex-shrink-0 cursor-pointer"
              >
                <div class="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center">
                  <.social_icon name={icon_name} />
                </div>
                <span class="text-xs">{name}</span>
              </a>
              <button
                type="button"
                id={"#{@id_prefix}-native-share-#{@post_id}"}
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
    <% end %>
    """
  end

  attr :name, :atom, required: true

  defp social_icon(%{name: :facebook} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
      <circle
        cx="12"
        cy="12"
        fill="none"
        r="11.25"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="1.5"
      />
      <path
        d="M16.671 15.469 17.203 12h-3.328V9.749a1.734 1.734 0 0 1 1.956-1.874h1.513V4.922a18.452 18.452 0 0 0-2.686-.234c-2.741 0-4.533 1.66-4.533 4.668V12H7.078v3.469h3.047v7.885a12.125 12.125 0 0 0 3.75 0V15.47Z"
        fill-rule="evenodd"
      />
    </svg>
    """
  end

  defp social_icon(%{name: :messenger} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
      <path
        d="M12.003 2.001a9.705 9.705 0 1 1 0 19.4 10.876 10.876 0 0 1-2.895-.384.798.798 0 0 0-.533.04l-1.984.876a.801.801 0 0 1-1.123-.708l-.054-1.78a.806.806 0 0 0-.27-.569 9.49 9.49 0 0 1-3.14-7.175 9.65 9.65 0 0 1 10-9.7Z"
        fill="none"
        stroke="currentColor"
        stroke-miterlimit="10"
        stroke-width="1.739"
      />
      <path
        d="M17.79 10.132a.659.659 0 0 0-.962-.873l-2.556 2.05a.63.63 0 0 1-.758.002L11.06 9.47a1.576 1.576 0 0 0-2.277.42l-2.567 3.98a.659.659 0 0 0 .961.875l2.556-2.049a.63.63 0 0 1 .759-.002l2.452 1.84a1.576 1.576 0 0 0 2.278-.42Z"
        fill-rule="evenodd"
      />
    </svg>
    """
  end

  defp social_icon(%{name: :whatsapp} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" />
    </svg>
    """
  end

  defp social_icon(%{name: :email} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"
      />
    </svg>
    """
  end

  defp social_icon(%{name: :threads} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 192 192" fill="currentColor">
      <path d="M141.537 88.9883C140.71 88.5919 139.87 88.2104 139.019 87.8451C137.537 60.5382 122.616 44.905 97.5619 44.745C97.4484 44.7443 97.3355 44.7443 97.222 44.7443C82.2364 44.7443 69.7731 51.1409 62.102 62.7807L75.881 72.2328C81.6116 63.5383 90.6052 61.6848 97.2286 61.6848C97.3051 61.6848 97.3819 61.6848 97.4576 61.6855C105.707 61.7381 111.932 64.1366 115.961 68.814C118.893 72.2193 120.854 76.925 121.825 82.8638C114.511 81.6207 106.601 81.2385 98.145 81.7233C74.3247 83.0954 59.0111 96.9879 60.0396 116.292C60.5615 126.084 65.4397 134.508 73.775 140.011C80.8224 144.663 89.899 146.938 99.3323 146.423C111.79 145.74 121.563 140.987 128.381 132.296C133.559 125.696 136.834 117.143 138.28 106.366C144.217 109.949 148.617 114.664 151.047 120.332C155.179 129.967 155.42 145.8 142.501 158.708C131.182 170.016 117.576 174.908 97.0135 175.059C74.2042 174.89 56.9538 167.575 45.7381 153.317C35.2355 139.966 29.8077 120.682 29.6052 96C29.8077 71.3178 35.2355 52.0336 45.7381 38.6827C56.9538 24.4249 74.2039 17.11 97.0132 16.9405C119.988 17.1113 137.539 24.4614 149.184 38.788C154.894 45.8136 159.199 54.6488 162.037 64.9503L178.184 60.6422C174.744 47.9622 169.331 37.0357 161.965 27.974C147.036 9.60668 125.202 0.195148 97.0695 0H96.9569C68.8816 0.19447 47.2921 9.6418 32.7883 28.0793C19.8819 44.4864 13.2244 67.3157 13.0007 95.9325L13 96L13.0007 96.0675C13.2244 124.684 19.8819 147.514 32.7883 163.921C47.2921 182.358 68.8816 191.806 96.9569 192H97.0695C122.03 191.827 139.624 185.292 154.118 170.811C173.081 151.866 172.51 128.119 166.26 113.541C161.776 103.087 153.227 94.5962 141.537 88.9883ZM98.4405 129.507C88.0005 130.095 77.1544 125.409 76.6196 115.372C76.2232 107.93 81.9158 99.626 99.0812 98.6368C101.047 98.5234 102.976 98.468 104.871 98.468C111.106 98.468 116.939 99.0737 122.242 100.233C120.264 124.935 108.662 128.946 98.4405 129.507Z" />
    </svg>
    """
  end

  defp social_icon(%{name: :x} = assigns) do
    ~H"""
    <svg class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
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

    count = length(socket.assigns.selected_users)
    send(self(), {__MODULE__, :share_sent})

    {:noreply,
     socket
     |> assign(post_id: nil, selected_users: [], search_query: "", message: "")
     |> push_event("close-share-modal", %{})
     |> push_event("show-toast", %{
       message: "Sent to #{count} #{if count == 1, do: "person", else: "people"}"
     })}
  end
end
