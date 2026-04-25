defmodule Instagrain.Feed.Post.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_resources" do
    field :type, Ecto.Enum, values: [:photo, :video]
    field :file, :string
    field :storage_key, :string
    field :alt, :string
    field :filter, :string, default: "original"
    field :adjustments, :map, default: %{}
    field :post_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:file, :storage_key, :alt, :type, :post_id, :filter, :adjustments])
    |> validate_required([:file, :type, :post_id])
  end
end
