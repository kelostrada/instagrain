defmodule Instagrain.Conversations.Conversation.ConversationMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations_messages" do
    field :message, :string
    belongs_to :user, Instagrain.Accounts.User
    belongs_to :conversation, Instagrain.Conversations.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation_message, attrs) do
    conversation_message
    |> cast(attrs, [:message, :user_id, :conversation_id])
    |> validate_required([:message, :user_id, :conversation_id])
  end
end
