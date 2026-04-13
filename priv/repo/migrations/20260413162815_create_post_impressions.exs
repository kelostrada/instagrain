defmodule Instagrain.Repo.Migrations.CreatePostImpressions do
  use Ecto.Migration

  def change do
    create table(:post_impressions, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :post_id, references(:posts, on_delete: :delete_all), primary_key: true
      add :view_count, :integer, null: false, default: 1
      add :last_seen_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:post_impressions, [:post_id])
  end
end
