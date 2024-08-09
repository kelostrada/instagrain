defmodule Instagrain.Repo.Migrations.CreatePostResources do
  use Ecto.Migration

  def change do
    create table(:post_resources) do
      add :file, :text, null: false
      add :alt, :text
      add :type, :string, null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:post_resources, [:post_id])
  end
end
