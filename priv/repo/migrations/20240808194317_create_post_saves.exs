defmodule Instagrain.Repo.Migrations.CreatePostSaves do
  use Ecto.Migration

  def change do
    create table(:post_saves, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all, primary_key: true)
      add :user_id, references(:users, on_delete: :delete_all, primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_saves, [:post_id, :user_id])
  end
end
