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

    Instagrain.Conversations.broadcast_messages_changed(state.user_id)

    {:noreply, Map.put(state, :conversations, conversations)}
  end

  def handle_cast({:notify_conversation_update, conversation_id, name}, state) do
    conversations =
      Enum.map(state.conversations, fn c ->
        if c.id == conversation_id, do: %{c | name: name}, else: c
      end)

    Enum.each(state.links, fn pid ->
      send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
    end)

    {:noreply, Map.put(state, :conversations, conversations)}
  end

  def handle_cast({:notify_members_changed, conversation_id}, state) do
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    if conversation do
      refreshed =
        Storage.get_conversation!(conversation_id)
        |> Instagrain.Repo.preload(users: :user, messages: :user)

      conversations =
        Enum.map(state.conversations, fn c ->
          if c.id == conversation_id, do: refreshed, else: c
        end)

      Enum.each(state.links, fn pid ->
        send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
      end)

      {:noreply, Map.put(state, :conversations, conversations)}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:notify_new_conversation, conversation}, state) do
    conversations = [conversation | state.conversations]

    Enum.each(
      state.links,
      &send(&1, {:conversations_update, format_conversations(conversations, state.user_id)})
    )

    {:noreply, Map.put(state, :conversations, conversations)}
  end

  @impl true
  def handle_call(:link_and_list_conversations, {from, _}, state) do
    Process.monitor(from)

    conversations = format_conversations(state.conversations, state.user_id)

    {:reply, conversations, Map.put(state, :links, MapSet.put(state.links, from))}
  end

  def handle_call({:rename_conversation, conversation_id, name}, _from, state) do
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    case Storage.update_conversation(conversation, %{name: name}) do
      {:ok, updated} ->
        conversations =
          Enum.map(state.conversations, fn c ->
            if c.id == conversation_id, do: %{c | name: updated.name}, else: c
          end)

        Enum.each(conversation.users, fn user ->
          if user.user_id != state.user_id do
            notify_conversation_update(user.user_id, conversation_id, name)
          end
        end)

        Enum.each(state.links, fn pid ->
          send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
        end)

        {:reply, :ok, Map.put(state, :conversations, conversations)}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:add_member, conversation_id, new_user_id}, _from, state) do
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    case Storage.create_conversation_user(%{
           conversation_id: conversation_id,
           user_id: new_user_id
         }) do
      {:ok, cu} ->
        cu = Instagrain.Repo.preload(cu, :user)
        updated_conversation = %{conversation | users: conversation.users ++ [cu]}

        conversations =
          Enum.map(state.conversations, fn c ->
            if c.id == conversation_id, do: updated_conversation, else: c
          end)

        notify_new_conversation(new_user_id, updated_conversation)

        Enum.each(conversation.users, fn user ->
          if user.user_id != state.user_id do
            notify_members_changed(user.user_id, conversation_id)
          end
        end)

        Enum.each(state.links, fn pid ->
          send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
        end)

        {:reply, :ok, Map.put(state, :conversations, conversations)}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:remove_member, conversation_id, target_user_id}, _from, state) do
    Storage.remove_conversation_user(conversation_id, target_user_id)
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    conversations =
      if target_user_id == state.user_id do
        # Leaving: remove the conversation entirely from our list
        Enum.reject(state.conversations, &(&1.id == conversation_id))
      else
        # Removing someone else: update the member list
        updated_conversation = %{
          conversation
          | users: Enum.reject(conversation.users, &(&1.user_id == target_user_id))
        }

        Enum.map(state.conversations, fn c ->
          if c.id == conversation_id, do: updated_conversation, else: c
        end)
      end

    Enum.each(state.links, fn pid ->
      send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
    end)

    {:reply, :ok, Map.put(state, :conversations, conversations)}
  end

  def handle_call({:delete_conversation, conversation_id}, _from, state) do
    conversation = Enum.find(state.conversations, &(&1.id == conversation_id))

    case Storage.delete_conversation(conversation) do
      {:ok, _} ->
        conversations = Enum.reject(state.conversations, &(&1.id == conversation_id))

        Enum.each(state.links, fn pid ->
          send(pid, {:conversations_update, format_conversations(conversations, state.user_id)})
        end)

        {:reply, :ok, Map.put(state, :conversations, conversations)}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:create_conversation, user_ids}, _from, state) do
    case Storage.find_or_create_conversation([state.user_id | user_ids]) do
      {:ok, conversation} ->
        if conversation.id in Enum.map(state.conversations, & &1.id) do
          {:reply, format_conversation(conversation, state.user_id), state}
        else
          Enum.each(conversation.users, fn user ->
            notify_new_conversation(user.user_id, conversation)
          end)

          {:reply, format_conversation(conversation, state.user_id), state}
        end

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
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

  defp notify_new_conversation(user_id, conversation) do
    GenServer.cast(via_tuple(user_id), {:notify_new_conversation, conversation})
  end

  defp notify_conversation_update(user_id, conversation_id, name) do
    GenServer.cast(via_tuple(user_id), {:notify_conversation_update, conversation_id, name})
  end

  defp notify_members_changed(user_id, conversation_id) do
    GenServer.cast(via_tuple(user_id), {:notify_members_changed, conversation_id})
  end

  def link_and_list_conversations(user_id) do
    GenServer.call(via_tuple(user_id), :link_and_list_conversations)
  end

  def create_conversation(user_id, user_ids) do
    GenServer.call(via_tuple(user_id), {:create_conversation, user_ids})
  end

  def rename_conversation(user_id, conversation_id, name) do
    GenServer.call(via_tuple(user_id), {:rename_conversation, conversation_id, name})
  end

  def add_member(user_id, conversation_id, new_user_id) do
    GenServer.call(via_tuple(user_id), {:add_member, conversation_id, new_user_id})
  end

  def remove_member(user_id, conversation_id, target_user_id) do
    GenServer.call(via_tuple(user_id), {:remove_member, conversation_id, target_user_id})
  end

  def delete_conversation(user_id, conversation_id) do
    GenServer.call(via_tuple(user_id), {:delete_conversation, conversation_id})
  end

  defp format_conversations(conversations, user_id) do
    Enum.into(conversations, %{}, fn conversation ->
      {conversation.id, format_conversation(conversation, user_id)}
    end)
  end

  defp format_conversation(conversation, user_id) do
    other_users =
      conversation.users
      |> Enum.map(& &1.user)
      |> Enum.filter(&(&1.id != user_id))

    messages = conversation.messages |> Enum.sort_by(& &1.inserted_at, :asc)
    last_message = messages |> List.last() || %{}

    all_users = conversation.users |> Enum.map(& &1.user)

    %{
      id: conversation.id,
      name:
        if(length(other_users) > 1,
          do:
            conversation.name ||
              Enum.map_join(other_users, ", ", &(&1.full_name || &1.username)),
          else: List.first(other_users).full_name || List.first(other_users).username
        ),
      participants: other_users,
      all_participants: all_users,
      is_group: length(other_users) > 1,
      last_message: Map.get(last_message, :message, ""),
      last_message_at: Map.get(last_message, :inserted_at),
      messages: messages
    }
  end
end
