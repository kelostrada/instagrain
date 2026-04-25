defmodule Instagrain.Repo.Migrations.DropLegacyImageFilenameColumns do
  use Ecto.Migration

  def change do
    alter table(:post_resources) do
      remove :file, :text
    end

    alter table(:users) do
      remove :avatar, :string
    end

    alter table(:posts) do
      remove :image, :string
    end
  end
end
