defmodule Instagrain.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :post_id, references(:posts, on_delete: :delete_all)
      add :comment_id, references(:post_comments, on_delete: :delete_all)
      add :seen_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id, :inserted_at])
    create index(:notifications, [:user_id, :seen_at])

    create unique_index(
             :notifications,
             [:user_id, :actor_id, :type, :post_id, :comment_id],
             name: :notifications_uniqueness_index
           )

    create index(:notifications, [:actor_id])
  end
end
