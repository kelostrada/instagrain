defmodule Instagrain.Repo.Migrations.CreatePostComments do
  use Ecto.Migration

  def change do
    create table(:post_comments) do
      add :comment, :text, null: false
      add :likes, :integer, null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reply_to_id, references(:post_comments, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:post_comments, [:post_id])
    create index(:post_comments, [:user_id])
    create index(:post_comments, [:reply_to_id])
  end
end
