defmodule Instagrain.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string, null: false
      add :address, :string
      add :lat, :float
      add :lng, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:locations, [:name])

    # Nullify stale location_ids before adding FK constraint
    execute "UPDATE posts SET location_id = NULL WHERE location_id IS NOT NULL", ""

    alter table(:posts) do
      modify :location_id, references(:locations, on_delete: :nilify_all), from: :integer
    end
  end
end
