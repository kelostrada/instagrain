defmodule Instagrain.Conversations do
  @moduledoc """
  Conversations context managing genservers.
  """

  import Ecto.Query, warn: false

  alias Instagrain.Conversations.Conversation.ConversationMessage
  alias Instagrain.Conversations.Conversation.ConversationUser
  alias Instagrain.Repo

  @pubsub Instagrain.PubSub

  def messages_topic(user_id), do: "user:#{user_id}:messages"

  def subscribe_to_messages(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, messages_topic(user_id))
  end

  def broadcast_messages_changed(user_id) do
    Phoenix.PubSub.broadcast(@pubsub, messages_topic(user_id), {:messages_changed, user_id})
  end

  @doc """
  Returns the number of conversations that contain a message the user hasn't
  read yet (i.e. a message from someone else inserted after their last_read_at).
  """
  def unread_conversation_count(user_id) do
    from(cu in ConversationUser,
      join: m in ConversationMessage,
      on: m.conversation_id == cu.conversation_id,
      where: cu.user_id == ^user_id and m.user_id != ^user_id,
      where: is_nil(cu.last_read_at) or m.inserted_at > cu.last_read_at,
      distinct: cu.conversation_id,
      select: cu.conversation_id
    )
    |> Repo.all()
    |> length()
  end

  @doc """
  Marks all of the user's conversations as read up to now.
  """
  def mark_all_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      Repo.update_all(
        from(cu in ConversationUser, where: cu.user_id == ^user_id),
        set: [last_read_at: now, updated_at: now]
      )

    if count > 0, do: broadcast_messages_changed(user_id)
    count
  end

  def link_and_list_conversations(user_id) do
    Instagrain.Conversations.ConversationsSupervisor.start_server(user_id)
    Instagrain.Conversations.ConversationServer.link_and_list_conversations(user_id)
  end

  def send_message(user_id, conversation_id, message) do
    Instagrain.Conversations.ConversationServer.send_message(user_id, conversation_id, message)
  end

  def create_conversation(user_id, user_ids) do
    Instagrain.Conversations.ConversationServer.create_conversation(user_id, user_ids)
  end

  def rename_conversation(user_id, conversation_id, name) do
    Instagrain.Conversations.ConversationServer.rename_conversation(
      user_id,
      conversation_id,
      name
    )
  end

  def add_member(user_id, conversation_id, new_user_id) do
    Instagrain.Conversations.ConversationServer.add_member(
      user_id,
      conversation_id,
      new_user_id
    )
  end

  def remove_member(user_id, conversation_id, target_user_id) do
    Instagrain.Conversations.ConversationServer.remove_member(
      user_id,
      conversation_id,
      target_user_id
    )
  end

  def delete_conversation(user_id, conversation_id) do
    Instagrain.Conversations.ConversationServer.delete_conversation(
      user_id,
      conversation_id
    )
  end
end
