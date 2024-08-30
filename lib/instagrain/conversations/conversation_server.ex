defmodule Instagrain.Conversations.ConversationServer do
  use GenServer

  require Logger

  alias Instagrain.Conversations.Storage

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end

  def via_tuple(user_id) do
    {:via, Registry, {Instagrain.Conversations.Registry, user_id}}
  end

  @impl true
  def init(user_id) do
    conversations = Storage.list_conversations(user_id)

    {:ok, %{user_id: user_id, conversations: conversations, links: MapSet.new()}}
  end

  @impl true
  def handle_cast({:send_message, conversation_id, message}, state) do
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    case Storage.add_message(conversation, state.user_id, message) do
      {:ok, message} ->
        Enum.each(conversation.users, fn user ->
          notify_message(user.user_id, conversation_id, message)
        end)

        {:noreply, state}

      {:error, error} ->
        Logger.error("Error adding message", error: inspect(error))
        {:noreply, state}
    end
  end

  def handle_cast({:notify_message, conversation_id, message}, state) do
    conversations =
      Enum.map(state.conversations, fn conversation ->
        if conversation.id == conversation_id do
          %{conversation | messages: conversation.messages ++ [message]}
        else
          conversation
        end
      end)

    Enum.each(state.links, fn pid ->
      send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
    end)

    {:noreply, Map.put(state, :conversations, conversations)}
  end

  @impl true
  def handle_call(:link_and_list_conversations, {from, _}, state) do
    Process.monitor(from)

    conversations = format_conversations(state.conversations, state.user_id)

    {:reply, conversations, Map.put(state, :links, MapSet.put(state.links, from))}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    {:noreply, Map.put(state, :links, MapSet.delete(state.links, pid))}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def send_message(user_id, conversation_id, message) do
    GenServer.cast(via_tuple(user_id), {:send_message, conversation_id, message})
  end

  defp notify_message(user_id, conversation_id, message) do
    GenServer.cast(via_tuple(user_id), {:notify_message, conversation_id, message})
  end

  def link_and_list_conversations(user_id) do
    GenServer.call(via_tuple(user_id), :link_and_list_conversations)
  end

  defp format_conversations(conversations, user_id) do
    Enum.into(conversations, %{}, fn conversation ->
      other_users =
        conversation.users
        |> Enum.map(& &1.user)
        |> Enum.filter(&(&1.id != user_id))

      messages = conversation.messages |> Enum.sort_by(& &1.inserted_at, :asc)
      last_message = messages |> List.last() || %{}

      {conversation.id,
       %{
         id: conversation.id,
         name:
           if(length(other_users) > 1,
             do: conversation.name || "test",
             else: List.first(other_users).full_name
           ),
         participants: other_users,
         last_message: Map.get(last_message, :message, ""),
         last_message_at: Map.get(last_message, :inserted_at),
         messages: messages
       }}
    end)
  end
end
