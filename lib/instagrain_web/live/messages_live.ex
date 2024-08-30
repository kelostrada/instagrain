defmodule InstagrainWeb.MessagesLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Accounts
  alias Instagrain.Conversations

  import InstagrainWeb.UserComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full">
      <div class={[
        "sm:border-r max-sm:w-full md:w-85 overflow-y-auto",
        @conversation_id && "max-sm:hidden"
      ]}>
        <div class="max-sm:p-4 sm:p-6 flex justify-between sm:max-md:justify-center w-full">
          <div class="sm:max-md:hidden">
            <h1 class="text-base font-extrabold">Messages</h1>
          </div>
          <div>
            <.icon name="hero-pencil-square" class="cursor-pointer" />
          </div>
        </div>

        <div
          :for={{id, conversation} <- @conversations}
          class={[
            "max-sm:px-4 sm:px-6 py-2 flex gap-3 hover:bg-neutral-100/50 cursor-pointer",
            @conversation_id == conversation.id && "bg-neutral-100"
          ]}
          phx-click={JS.patch(~p"/messages/#{id}")}
          phx-value-id={conversation.id}
        >
          <%= if length(conversation.participants) == 1 do %>
            <div>
              <.avatar size={:lg} user={List.first(conversation.participants)} />
            </div>
          <% else %>
            <div class="relative w-[58px] h-[58px]">
              <% [user1, user2 | _] = conversation.participants %>

              <.avatar size={:md} user={user1} class="absolute top-0 left-0" />
              <.avatar
                size={:md}
                user={user2}
                class="absolute bottom-0 right-0 border-white border-2"
              />
            </div>
          <% end %>
          <div class="grow flex flex-col justify-center sm:max-md:hidden">
            <div class="text-sm font-medium"><%= conversation.name %></div>
            <div>
              <.user_content text={conversation.last_message} class="text-xs text-neutral-500" />
              <.time
                :if={conversation.last_message_at}
                prefix="· "
                datetime={conversation.last_message_at}
                class="text-xs text-neutral-500"
              />
            </div>
          </div>
        </div>
      </div>
      <%= if @conversation_id do %>
        <div class="grow">
          <div class="max-sm:hidden px-4 py-2 border-b flex items-center gap-4">
            <%= if length(@conversations[@conversation_id].participants) == 1 do %>
              <div>
                <.avatar size={:lg} user={List.first(@conversations[@conversation_id].participants)} />
              </div>
            <% else %>
              <div class="relative w-[58px] h-[58px]">
                <% [user1, user2 | _] = @conversations[@conversation_id].participants %>

                <.avatar size={:md} user={user1} class="absolute top-0 left-0" />
                <.avatar
                  size={:md}
                  user={user2}
                  class="absolute bottom-0 right-0 border-white border-2"
                />
              </div>
            <% end %>
            <span class="font-bold text-base">
              <%= @conversations[@conversation_id].name %>
            </span>
          </div>
          <div
            class="flex flex-col gap-4 max-sm:h-[calc(100%-7rem)] sm:h-[calc(100%-10rem)] overflow-y-auto p-6"
            phx-hook="ScrollToBottom"
            id="messages-list"
          >
            <%= for message <- @conversations[@conversation_id].messages do %>
              <div class={"flex " <> if(message.user.id == @current_user.id, do: "justify-end", else: "")}>
                <div class={[
                  "py-2 px-4 rounded-[1.5rem] inline",
                  if(message.user.id == @current_user.id, do: "bg-sky-500", else: "bg-neutral-200")
                ]}>
                  <.username
                    user={message.user}
                    class={
                  "font-bold text-sm leading-6 " <>
                  if(message.user.id == @current_user.id, do: "text-white", else: "text-black")
                }
                  />
                  <.user_content
                    text={message.message}
                    class={
                  "font-medium text-sm leading-6 " <>
                  if(message.user.id == @current_user.id, do: "text-white", else: "text-black")
                }
                  />
                </div>
              </div>
            <% end %>
          </div>
          <div class="border-t p-4">
            <div class="rounded-full border">
              <form phx-change="message-edit" phx-submit="send-message">
                <div class="flex justify-between">
                  <textarea
                    id="message-input"
                    name="message"
                    phx-hook="SubmitOnEnter"
                    class={[
                      "block w-full mx-6 mt-4 p-0 border-0 outline-none outline-clear",
                      "resize-none overflow-hidden placeholder:font-medium placeholder:text-neutral-500 text-black font-medium text-sm"
                    ]}
                    placeholder="Message..."
                  ><%= Phoenix.HTML.Form.normalize_value("textarea", @message) %></textarea>
                  <div class="mx-6 mt-4">
                    <%= if String.length(@message) > 0 do %>
                      <button class="cursor-pointer font-bold text-sm text-sky-500 hover:text-sky-900">
                        Send
                      </button>
                    <% end %>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      <% else %>
        <div class="max-sm:hidden flex flex-col items-center justify-center gap-4 grow">
          <h1 class="text-xl font-medium">
            Your messages
          </h1>
          <span class="text-sm">Send private photos and messages to a friend or group.</span>
          <.button>Send message</.button>
        </div>
      <% end %>
    </div>
    """
  end

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
