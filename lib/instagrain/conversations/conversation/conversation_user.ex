defmodule Instagrain.Conversations.Conversation.ConversationUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "conversations_users" do
    belongs_to :user, Instagrain.Accounts.User
    belongs_to :conversation, Instagrain.Conversations.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation_user, attrs) do
    conversation_user
    |> cast(attrs, [:user_id, :conversation_id])
    |> validate_required([:user_id, :conversation_id])
    |> unique_constraint([:user_id, :conversation_id])
  end
end
