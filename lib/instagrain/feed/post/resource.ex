defmodule Instagrain.Feed.Post.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_resources" do
    field :type, Ecto.Enum, values: [:photo, :video]
    field :file, :string
    field :alt, :string
    field :post_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:file, :alt, :type])
    |> validate_required([:file, :alt, :type])
  end
end
