defmodule Instagrain.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create table(:conversations_users, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, primary_key: true)
      add :conversation_id, references(:conversations, on_delete: :delete_all, primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversations_users, [:user_id, :conversation_id])

    create table(:conversations_messages) do
      add :message, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :conversation_id, references(:conversations, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:conversations_messages, [:user_id])
    create index(:conversations_messages, [:conversation_id])
  end
end
