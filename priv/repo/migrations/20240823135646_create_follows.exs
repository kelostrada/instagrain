defmodule Instagrain.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, primary_key: true)
      add :follow_id, references(:users, on_delete: :delete_all, primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:follows, [:user_id, :follow_id])
  end
end
