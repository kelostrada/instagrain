defmodule Instagrain.Repo.Migrations.CreatePostResources do
  use Ecto.Migration

  def change do
    create table(:post_resources) do
      add :file, :text
      add :alt, :text
      add :type, :string
      add :post_id, references(:posts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:post_resources, [:post_id])
  end
end
