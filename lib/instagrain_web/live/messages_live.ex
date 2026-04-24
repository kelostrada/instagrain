defmodule InstagrainWeb.MessagesLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Accounts
  alias Instagrain.Conversations
  alias Instagrain.Profiles

  import InstagrainWeb.UserComponents

  defp top_nav(conversation) do
    assigns = %{conversation: conversation}

    ~H"""
    <div class="sm:hidden flex items-center px-4 py-2 gap-3 border-b">
      <.link onclick="history.back()" class="cursor-pointer flex-shrink-0">
        <.icon name="hero-arrow-left" class="h-6 w-6" />
      </.link>
      <%= if length(@conversation.participants) == 1 do %>
        <.link navigate={~p"/#{List.first(@conversation.participants).username}"} class="flex items-center gap-3 grow cursor-pointer min-w-0">
          <.avatar size={:sm} user={List.first(@conversation.participants)} />
          <div class="min-w-0">
            <p class="font-bold text-sm truncate">
              <%= List.first(@conversation.participants).full_name || List.first(@conversation.participants).username %>
            </p>
            <p class="text-xs text-neutral-500 truncate">
              <%= List.first(@conversation.participants).username %>
            </p>
          </div>
        </.link>
      <% else %>
        <div class="flex items-center gap-3 grow cursor-pointer min-w-0" phx-click="open-details">
          <div class="relative w-[34px] h-[34px] flex-shrink-0">
            <% [user1, user2 | _] = @conversation.participants %>
            <.avatar size={:xxs} user={user1} class="absolute top-0 left-0" />
            <.avatar size={:xxs} user={user2} class="absolute bottom-0 right-0 border-white border-2" />
          </div>
          <div class="min-w-0">
            <p class="font-bold text-sm truncate"><%= @conversation.name %></p>
          </div>
        </div>
      <% end %>
      <button phx-click="open-details" class="cursor-pointer flex-shrink-0">
        <.icon name="hero-information-circle" class="h-6 w-6" />
      </button>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    conversations = Conversations.link_and_list_conversations(user_id)
    suggested_users = Profiles.list_following(user_id)

    {:ok,
     assign(socket,
       raw_layout: "",
       message: "",
       conversations: conversations,
       unread_conversation_ids: Conversations.unread_conversation_ids(user_id),
       suggested_users: suggested_users,
       new_message_search: "",
       new_message_results: suggested_users,
       selected_users: [],
       show_details: false,
       details_group_name: "",
       add_member_search: "",
       add_member_results: [],
       show_add_member: false
     )}
  end

  @impl true
  def handle_info({:conversations_update, conversations}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      assign(socket,
        conversations: conversations,
        unread_conversation_ids: Conversations.unread_conversation_ids(user_id)
      )

    socket =
      if socket.assigns.conversation_id &&
           Map.has_key?(conversations, socket.assigns.conversation_id) do
        # Any new inbound message for the currently-open conversation counts as
        # "seen" immediately — we're actively looking at it.
        Conversations.mark_conversation_read(user_id, socket.assigns.conversation_id)

        assign(socket,
          top_nav: top_nav(conversations[socket.assigns.conversation_id]),
          unread_conversation_ids:
            MapSet.delete(socket.assigns.unread_conversation_ids, socket.assigns.conversation_id)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:messages_changed, _uid}, socket) do
    {:noreply,
     assign(socket,
       unread_conversation_ids:
         Conversations.unread_conversation_ids(socket.assigns.current_user.id)
     )}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case socket.assigns.live_action do
      :new ->
        conversation =
          Conversations.create_conversation(socket.assigns.current_user.id, [
            String.to_integer(params["user_id"])
          ])

        {:noreply, push_navigate(socket, to: ~p"/messages/#{conversation.id}")}

      :show ->
        conversation_id = String.to_integer(params["conversation_id"])
        conversation = socket.assigns.conversations[conversation_id]

        Conversations.mark_conversation_read(socket.assigns.current_user.id, conversation_id)

        {:noreply,
         assign(socket,
           conversation_id: conversation_id,
           unread_conversation_ids:
             MapSet.delete(socket.assigns.unread_conversation_ids, conversation_id),
           main_no_scroll: true,
           top_nav: top_nav(conversation),
           show_details: false,
           hide_mobile_nav: true
         )}

      _ ->
        {:noreply,
         assign(socket,
           conversation_id: nil,
           main_no_scroll: false,
           hide_mobile_nav: false,
           top_nav: nil
         )}
    end
  end

  @impl true
  def handle_event("message-edit", params, socket) do
    {:noreply, assign(socket, message: params["message"])}
  end

  def handle_event("send-message", params, socket) do
    Conversations.send_message(
      socket.assigns.current_user.id,
      socket.assigns.conversation_id,
      String.trim(params["message"])
    )

    {:noreply, assign(socket, message: "")}
  end

  def handle_event("open-new-message", _params, socket) do
    {:noreply,
     assign(socket,
       new_message_search: "",
       new_message_results: socket.assigns.suggested_users,
       selected_users: []
     )}
  end

  def handle_event("new-message-search", %{"query" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        socket.assigns.suggested_users
      else
        Accounts.search_users(query, 20)
        |> Enum.reject(&(&1.id == socket.assigns.current_user.id))
      end

    {:noreply, assign(socket, new_message_search: query, new_message_results: results)}
  end

  def handle_event("select-user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)
    selected = socket.assigns.selected_users

    if Enum.any?(selected, &(&1.id == user_id)) do
      {:noreply, assign(socket, selected_users: Enum.reject(selected, &(&1.id == user_id)))}
    else
      user = Enum.find(socket.assigns.new_message_results, &(&1.id == user_id))

      if user do
        {:noreply, assign(socket, selected_users: selected ++ [user])}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("deselect-user", %{"id" => id}, socket) do
    user_id = String.to_integer(id)

    {:noreply,
     assign(socket,
       selected_users: Enum.reject(socket.assigns.selected_users, &(&1.id == user_id))
     )}
  end

  def handle_event("create-conversation", _params, socket) do
    selected = socket.assigns.selected_users

    if selected == [] do
      {:noreply, socket}
    else
      user_ids = Enum.map(selected, & &1.id)

      conversation =
        Conversations.create_conversation(socket.assigns.current_user.id, user_ids)

      {:noreply,
       socket
       |> push_navigate(to: ~p"/messages/#{conversation.id}")}
    end
  end

  def handle_event("toggle-details", _params, socket) do
    if socket.assigns.show_details do
      handle_event("close-details", %{}, socket)
    else
      handle_event("open-details", %{}, socket)
    end
  end

  def handle_event("open-details", _params, socket) do
    conversation = socket.assigns.conversations[socket.assigns.conversation_id]

    {:noreply,
     assign(socket,
       show_details: true,
       top_nav: nil,
       details_group_name: conversation.name,
       add_member_search: "",
       add_member_results: []
     )}
  end

  def handle_event("close-details", _params, socket) do
    conversation = socket.assigns.conversations[socket.assigns.conversation_id]

    {:noreply,
     assign(socket,
       show_details: false,
       top_nav: top_nav(conversation)
     )}
  end

  def handle_event("rename-group-edit", %{"name" => name}, socket) do
    {:noreply, assign(socket, details_group_name: name)}
  end

  def handle_event("rename-group", _params, socket) do
    name = String.trim(socket.assigns.details_group_name)

    if name != "" do
      Conversations.rename_conversation(
        socket.assigns.current_user.id,
        socket.assigns.conversation_id,
        name
      )
    end

    {:noreply, socket}
  end

  def handle_event("open-add-member", _params, socket) do
    conversation = socket.assigns.conversations[socket.assigns.conversation_id]
    member_ids = Enum.map(conversation.all_participants, & &1.id)
    suggested = Enum.reject(socket.assigns.suggested_users, &(&1.id in member_ids))

    {:noreply, assign(socket, add_member_search: "", add_member_results: suggested)}
  end

  def handle_event("add-member-search", %{"query" => query}, socket) do
    query = String.trim(query)
    conversation = socket.assigns.conversations[socket.assigns.conversation_id]
    member_ids = Enum.map(conversation.all_participants, & &1.id)

    results =
      if query == "" do
        Enum.reject(socket.assigns.suggested_users, &(&1.id in member_ids))
      else
        Accounts.search_users(query, 20)
        |> Enum.reject(&(&1.id in member_ids))
      end

    {:noreply, assign(socket, add_member_search: query, add_member_results: results)}
  end

  def handle_event("add-member", %{"id" => id}, socket) do
    new_user_id = if is_integer(id), do: id, else: String.to_integer(id)

    Conversations.add_member(
      socket.assigns.current_user.id,
      socket.assigns.conversation_id,
      new_user_id
    )

    {:noreply, assign(socket, add_member_search: "", add_member_results: [])}
  end

  def handle_event("remove-member", %{"id" => id}, socket) do
    target_user_id = String.to_integer(id)

    Conversations.remove_member(
      socket.assigns.current_user.id,
      socket.assigns.conversation_id,
      target_user_id
    )

    {:noreply, socket}
  end

  def handle_event("leave-chat", _params, socket) do
    Conversations.remove_member(
      socket.assigns.current_user.id,
      socket.assigns.conversation_id,
      socket.assigns.current_user.id
    )

    {:noreply,
     socket
     |> assign(show_details: false)
     |> push_navigate(to: ~p"/messages")}
  end

  def handle_event("delete-chat", _params, socket) do
    Conversations.delete_conversation(
      socket.assigns.current_user.id,
      socket.assigns.conversation_id
    )

    {:noreply,
     socket
     |> assign(show_details: false)
     |> push_navigate(to: ~p"/messages")}
  end

  defp group_messages(messages) do
    Enum.chunk_while(
      messages,
      nil,
      fn message, acc ->
        case acc do
          nil ->
            {:cont, [message]}

          [prev | _] = group ->
            same_user = message.user.id == prev.user.id
            gap = DateTime.diff(message.inserted_at, prev.inserted_at, :second)

            if same_user and gap < 10800 do
              {:cont, [message | group]}
            else
              {:cont, Enum.reverse(group), [message]}
            end
        end
      end,
      fn
        nil -> {:cont, []}
        group -> {:cont, Enum.reverse(group), nil}
      end
    )
  end

  defp format_message_datetime(datetime) do
    date = DateTime.to_date(datetime)
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    time_str = Calendar.strftime(datetime, "%H:%M")

    cond do
      date == today -> time_str
      date == yesterday -> "Yesterday, #{time_str}"
      date.year == today.year -> Calendar.strftime(datetime, "%-d %b, %H:%M")
      true -> Calendar.strftime(datetime, "%-d %b %Y, %H:%M")
    end
  end

  defp bubble_class(index, total, is_own) do
    position =
      cond do
        total == 1 -> :single
        index == 0 -> :first
        index == total - 1 -> :last
        true -> :middle
      end

    radius =
      case {position, is_own} do
        {:single, _} -> "rounded-[1.25rem]"
        {:first, true} -> "rounded-[1.25rem] rounded-br-[4px]"
        {:middle, true} -> "rounded-[1.25rem] rounded-r-[4px]"
        {:last, true} -> "rounded-[1.25rem] rounded-tr-[4px]"
        {:first, false} -> "rounded-[1.25rem] rounded-bl-[4px]"
        {:middle, false} -> "rounded-[1.25rem] rounded-l-[4px]"
        {:last, false} -> "rounded-[1.25rem] rounded-tl-[4px]"
      end

    color = if(is_own, do: "bg-sky-500", else: "bg-neutral-200")
    [radius, color, "py-2 px-3 [overflow-wrap:anywhere]"]
  end
end
