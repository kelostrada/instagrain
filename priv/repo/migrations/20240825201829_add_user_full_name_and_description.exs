defmodule Instagrain.Repo.Migrations.AddUserFullNameAndDescription do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :description, :text
      add :full_name, :string
    end
  end
end
