defmodule Instagrain.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :image, :string
      add :likes, :integer, null: false
      add :caption, :text
      add :location_id, :integer
      add :hide_likes, :boolean, default: false, null: false
      add :disable_comments, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
  end
end
