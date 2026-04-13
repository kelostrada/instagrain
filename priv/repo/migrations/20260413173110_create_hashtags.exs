defmodule Instagrain.Repo.Migrations.CreateHashtags do
  use Ecto.Migration

  def change do
    create table(:hashtags) do
      add :name, :string, null: false
      add :post_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:hashtags, [:name])
    create index(:hashtags, [:post_count])

    create table(:post_hashtags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all), primary_key: true
      add :hashtag_id, references(:hashtags, on_delete: :delete_all), primary_key: true

      timestamps(type: :utc_datetime)
    end

    create index(:post_hashtags, [:hashtag_id])
  end
end
