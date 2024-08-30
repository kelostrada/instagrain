defmodule InstagrainWeb.MessagesLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Conversations

  import InstagrainWeb.UserComponents

  defp conversation_avatar(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <%= if length(@conversation.participants) == 1 do %>
        <div>
          <.avatar size={@size} user={List.first(@conversation.participants)} />
        </div>
      <% else %>
        <div class={[
          "relative",
          @size == :xxs && "w-[22px] h-[22px]",
          @size == :xs && "w-[30px] h-[30px]",
          @size == :sm && "w-[34px] h-[34px]",
          @size == :md && "w-[42px] h-[42px]",
          @size == :lg && "w-[58px] h-[58px]"
        ]}>
          <% [user1, user2 | _] = @conversation.participants %>

          <.avatar size={@size_small} user={user1} class="absolute top-0 left-0" />
          <.avatar
            size={@size_small}
            user={user2}
            class="absolute bottom-0 right-0 border-white border-2"
          />
        </div>
      <% end %>
      <span class="font-bold text-base">
        <%= @conversation.name %>
      </span>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    conversations = Conversations.link_and_list_conversations(socket.assigns.current_user.id)

    {:ok, assign(socket, raw_layout: "", message: "", conversations: conversations)}
  end

  @impl true
  def handle_info({:conversations_update, conversations}, socket) do
    {:noreply, assign(socket, conversations: conversations)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"conversation_id" => conversation_id}, _, socket) do
    conversation_id = String.to_integer(conversation_id)
    conversation = socket.assigns.conversations[conversation_id]
    assigns = %{conversation: conversation}

    top_nav =
      mobile_nav_header(%{
        title: ~H"""
        <div class="py-1">
          <.conversation_avatar conversation={@conversation} size={:sm} size_small={:xxs} />
        </div>
        """
      })

    {:noreply, assign(socket, conversation_id: conversation_id, top_nav: top_nav)}
  end

  def handle_params(_params, _, socket) do
    {:noreply, assign(socket, conversation_id: nil)}
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
end
