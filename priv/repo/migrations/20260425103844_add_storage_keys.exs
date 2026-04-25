defmodule Instagrain.Repo.Migrations.AddStorageKeys do
  use Ecto.Migration

  def change do
    alter table(:post_resources) do
      add :storage_key, :string
    end

    alter table(:users) do
      add :avatar_storage_key, :string
    end
  end
end
