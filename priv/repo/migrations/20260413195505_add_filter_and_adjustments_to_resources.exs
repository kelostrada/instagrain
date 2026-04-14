defmodule Instagrain.Repo.Migrations.AddFilterAndAdjustmentsToResources do
  use Ecto.Migration

  def change do
    alter table(:post_resources) do
      add :filter, :string, default: "original"
      add :adjustments, :map, default: %{}
    end
  end
end
