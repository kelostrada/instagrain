defmodule Instagrain.Repo.Migrations.CreatePostCommentLikes do
  use Ecto.Migration

  def change do
    create table(:post_comment_likes, primary_key: false) do
      add :comment_id, references(:post_comments, on_delete: :delete_all, primary_key: true)
      add :user_id, references(:users, on_delete: :delete_all, primary_key: true)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_comment_likes, [:comment_id, :user_id])
  end
end
