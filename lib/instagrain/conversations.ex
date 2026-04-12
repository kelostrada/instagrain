defmodule Instagrain.Conversations do
  @moduledoc """
  Conversations context managing genservers.
  """

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
