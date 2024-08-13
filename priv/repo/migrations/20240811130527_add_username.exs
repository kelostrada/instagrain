defmodule Instagrain.Repo.Migrations.AddUsername do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :username, :citext
    end

    execute "UPDATE users SET username = LEFT(email, POSITION('@' IN email) - 1)", ""

    alter table(:users) do
      modify :username, :citext, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :username
    end
  end
end
