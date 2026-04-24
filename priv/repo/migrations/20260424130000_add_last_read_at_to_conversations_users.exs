defmodule Instagrain.Repo.Migrations.AddLastReadAtToConversationsUsers do
  use Ecto.Migration

  def change do
    alter table(:conversations_users) do
      add :last_read_at, :utc_datetime
    end
  end
end
