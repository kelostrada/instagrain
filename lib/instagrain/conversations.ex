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
end
