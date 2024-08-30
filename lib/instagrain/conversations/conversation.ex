defmodule Instagrain.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :name, :string

    has_many :users, Instagrain.Conversations.Conversation.ConversationUser
    has_many :messages, Instagrain.Conversations.Conversation.ConversationMessage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name])
    |> validate_required([])
  end
end
