defmodule Instagrain.Repo.Migrations.CreatePostLikes do
  use Ecto.Migration

  def change do
    create table(:post_likes, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all, primary_key: true)
      add :user_id, references(:users, on_delete: :delete_all, primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_likes, [:post_id, :user_id])
  end
end
