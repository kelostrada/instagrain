defmodule Instagrain.Conversations.Storage do
  @moduledoc """
  The Conversations context. Used for creating and managing conversations
  """

  import Ecto.Query, warn: false

  alias Instagrain.Conversations.Conversation.ConversationMessage
  alias Instagrain.Repo

  alias Instagrain.Conversations.Conversation
  alias Instagrain.Conversations.Conversation.ConversationUser

  @doc """
  Returns the list of conversations for user

  ## Examples

      iex> list_conversations(1)
      [%Conversation{}, ...]

  """
  def list_conversations(user_id) do
    from(c in Conversation,
      join: u in assoc(c, :users),
      where: u.user_id == ^user_id
    )
    |> Repo.all()
    |> Repo.preload(messages: :user, users: :user)
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id) do
    Repo.get!(Conversation, id)
    |> Repo.preload([:users, :messages])
  end

  @doc """
  Finds a single conversation by user IDs.

  ## Examples

      iex> find_conversation([1, 2, 3])
      %Conversation{}

      iex> find_conversation([2, 4])
      nil

  """
  def find_conversation(user_ids) do
    user_ids = Enum.sort(user_ids)

    from(c in Conversation,
      join: cu in assoc(c, :users),
      group_by: c.id,
      having: fragment("? = ARRAY_AGG(? ORDER BY ?)", ^user_ids, cu.user_id, cu.user_id)
    )
    |> Repo.one()
    |> Repo.preload([:users, :messages])
  end

  @doc """
  Finds a conversations for given list of user IDs or creates a new one
  """
  def find_or_create_conversation([]), do: {:error, :not_allowed}
  def find_or_create_conversation([_]), do: {:error, :not_allowed}

  def find_or_create_conversation(user_ids) do
    Repo.transaction(fn ->
      user_ids
      |> find_conversation()
      |> case do
        nil -> create_conversation_in_transaction(user_ids)
        conversation -> conversation
      end
      |> Repo.preload(users: :user, messages: :user)
    end)
  end

  defp create_conversation_in_transaction(user_ids) do
    case create_conversation() do
      {:ok, conversation} ->
        users =
          Enum.map(user_ids, &create_conversation_user_in_transaction(&1, conversation.id))

        %{conversation | messages: [], users: users}

      {:error, error} ->
        Repo.rollback(error)
    end
  end

  defp create_conversation_user_in_transaction(user_id, conversation_id) do
    case create_conversation_user(%{
           user_id: user_id,
           conversation_id: conversation_id
         }) do
      {:ok, user} -> user
      {:error, error} -> Repo.rollback(error)
    end
  end

  @doc """
  Adds a message to a conversation. Cannot add a new message if user_id is not part
  of :users list in a conversation.
  """
  def add_message(%Conversation{} = conversation, user_id, message) do
    if user_id in Enum.map(conversation.users, & &1.user_id) do
      create_conversation_message(%{
        conversation_id: conversation.id,
        user_id: user_id,
        message: message
      })
      |> case do
        {:ok, message} ->
          {:ok, Repo.preload(message, [:user])}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, :cannot_add_message}
    end
  end

  @doc """
  Creates a conversation.

  ## Examples

      iex> create_conversation(%{field: value})
      {:ok, %Conversation{}}

      iex> create_conversation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a conversation user.

  ## Examples

      iex> create_conversation_user(%{field: value})
      {:ok, %ConversationUser{}}

      iex> create_conversation_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation_user(attrs \\ %{}) do
    %ConversationUser{}
    |> ConversationUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a conversation message.

  ## Examples

      iex> create_conversation_message(attrs)
      {:ok, %ConversationMessage{}}

      iex> create_conversation_message(%{})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation_message(attrs \\ %{}) do
    %ConversationMessage{}
    |> ConversationMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a conversation.

  ## Examples

      iex> update_conversation(conversation, %{field: new_value})
      {:ok, %Conversation{}}

      iex> update_conversation(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation.

  ## Examples

      iex> delete_conversation(conversation)
      {:ok, %Conversation{}}

      iex> delete_conversation(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end
end
