defmodule InstagrainWeb.MessagesLive do
  alias Instagrain.Accounts
  use InstagrainWeb, :live_view

  import InstagrainWeb.UserComponents

  def render(assigns) do
    ~H"""
    <div class="flex h-full">
      <div class="sm:border-r">
        <div class="max-sm:p-2 sm:p-6 flex justify-around">
          <div class="max-sm:hidden w-80">
            <h1 class="text-base font-extrabold">Messages</h1>
          </div>
          <div>
            <.icon name="hero-pencil-square" class="cursor-pointer" />
          </div>
        </div>

        <div
          :for={conversation <- @conversations}
          class={[
            "max-sm:p-2 sm:px-6 py-2 flex gap-3 hover:bg-neutral-100/50 cursor-pointer",
            @selected_conversation == conversation.id && "bg-neutral-100"
          ]}
          phx-click="select-conversation"
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
          <div class="grow flex flex-col justify-center">
            <div class="text-sm font-medium"><%= conversation.name %></div>
            <div>
              <.user_content text={conversation.last_message} class="text-xs text-neutral-500" />
              <.time
                prefix="· "
                datetime={conversation.last_message_at}
                class="text-xs text-neutral-500"
              />
            </div>
          </div>
        </div>
      </div>
      <div class="max-sm:hidden flex flex-col items-center justify-center gap-4 w-full">
        <h1 class="text-xl font-medium">
          Your messages
        </h1>
        <span class="text-sm">Send private photos and messages to a friend or group.</span>
        <.button>Send message</.button>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       raw_layout: "",
       conversations: get_conversations(socket.assigns.current_user.id),
       selected_conversation: nil
     )}
  end

  @impl true
  def handle_event("select-conversation", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:noreply, assign(socket, selected_conversation: id)}
  end

  defp get_conversations(_user_id) do
    user1 = Accounts.get_user!(1)
    user2 = Accounts.get_user!(2)
    user3 = Accounts.get_user!(3)
    user4 = Accounts.get_user!(4)

    [
      %{
        id: 1,
        name: user2.full_name || user2.username,
        participants: [
          user2
        ],
        last_message: "Liked a message",
        last_message_at: user1.inserted_at
      },
      %{
        id: 2,
        name: user4.full_name || user4.username,
        participants: [
          user4
        ],
        last_message: "You sent an attachment.",
        last_message_at: user2.inserted_at
      },
      %{
        id: 3,
        name: "Melina Krzemowa",
        participants: [
          user1,
          user4
        ],
        last_message: "Thanks 😊",
        last_message_at: user3.inserted_at
      }
    ]
  end
end
