defmodule InstagrainWeb.Media do
  @moduledoc """
  URL helpers for post resources and avatars stored in object storage.

  Variants:

    * `:thumb_jpg` — 400px JPEG, used only for OG / Twitter cards
    * `:thumb`     — 400px WebP, used for grids, lists, avatars
    * `:medium`    — 1080px WebP, used for the main feed display / editor
    * `:full`      — up to 2048px WebP, used for the lightbox / carousel
  """

  alias Instagrain.Storage

  @type variant :: :thumb_jpg | :thumb | :medium | :full

  @spec resource_url(map, variant) :: String.t() | nil
  def resource_url(%{storage_key: sk}, variant) when is_binary(sk) do
    Storage.url("#{sk}/#{variant_filename(variant)}")
  end

  def resource_url(_, _), do: nil

  @spec avatar_url(map, variant) :: String.t() | nil
  def avatar_url(%{avatar_storage_key: sk}, variant) when is_binary(sk) do
    Storage.url("#{sk}/#{variant_filename(variant)}")
  end

  def avatar_url(_, _), do: nil

  @doc """
  Returns `{absolute_url, content_type}` for a post resource intended for
  Open Graph / Twitter meta tags. Always uses the JPEG thumb variant —
  link-preview crawlers (Signal, iMessage, some Slack/Discord paths) prefer
  small JPEGs over WebP, especially at preview sizes.
  """
  @spec resource_og(map | nil) :: {String.t() | nil, String.t() | nil}
  def resource_og(%{storage_key: sk}) when is_binary(sk) do
    {Storage.url("#{sk}/#{variant_filename(:thumb_jpg)}"), "image/jpeg"}
  end

  def resource_og(_), do: {nil, nil}

  @spec avatar_og(map | nil) :: {String.t() | nil, String.t() | nil}
  def avatar_og(%{avatar_storage_key: sk}) when is_binary(sk) do
    {Storage.url("#{sk}/#{variant_filename(:thumb_jpg)}"), "image/jpeg"}
  end

  def avatar_og(_), do: {nil, nil}

  defp variant_filename(:thumb_jpg), do: "thumb_jpg.jpg"
  defp variant_filename(:thumb), do: "thumb.webp"
  defp variant_filename(:medium), do: "medium.webp"
  defp variant_filename(:full), do: "full.webp"
end
