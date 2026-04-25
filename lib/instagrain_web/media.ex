defmodule InstagrainWeb.Media do
  @moduledoc """
  URL helpers for post resources and avatars.

  Reads prefer object storage (MinIO via `Instagrain.Storage`) when the row's
  `storage_key` / `avatar_storage_key` is populated. Otherwise the helpers
  fall back to the legacy `/uploads/...` static path so historical data
  keeps rendering until the backfill task fills in the storage keys.

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

  def resource_url(%{file: file}, _variant) when is_binary(file) do
    "/uploads/#{file}"
  end

  def resource_url(_, _), do: nil

  @spec avatar_url(map, variant) :: String.t() | nil
  def avatar_url(%{avatar_storage_key: sk}, variant) when is_binary(sk) do
    Storage.url("#{sk}/#{variant_filename(variant)}")
  end

  def avatar_url(%{avatar: avatar}, _variant) when is_binary(avatar) do
    "/uploads/avatars/#{avatar}"
  end

  def avatar_url(_, _), do: nil

  @doc """
  Returns `{absolute_url, content_type}` for a post resource intended for
  Open Graph / Twitter meta tags. Uses the JPEG thumb variant when present —
  link-preview crawlers (Signal, iMessage, some Slack/Discord paths) prefer
  small JPEGs over WebP, especially at preview sizes.
  """
  @spec resource_og(map | nil, String.t()) :: {String.t() | nil, String.t() | nil}
  def resource_og(%{storage_key: sk}, _base_url) when is_binary(sk) do
    {Storage.url("#{sk}/#{variant_filename(:thumb_jpg)}"), "image/jpeg"}
  end

  def resource_og(%{file: file}, base_url) when is_binary(file) do
    {"#{base_url}/uploads/#{file}", image_mime(file)}
  end

  def resource_og(_, _), do: {nil, nil}

  @spec avatar_og(map | nil, String.t()) :: {String.t() | nil, String.t() | nil}
  def avatar_og(%{avatar_storage_key: sk}, _base_url) when is_binary(sk) do
    {Storage.url("#{sk}/#{variant_filename(:thumb_jpg)}"), "image/jpeg"}
  end

  def avatar_og(%{avatar: avatar}, base_url) when is_binary(avatar) do
    {"#{base_url}/uploads/avatars/#{avatar}", image_mime(avatar)}
  end

  def avatar_og(_, _), do: {nil, nil}

  defp variant_filename(:thumb_jpg), do: "thumb_jpg.jpg"
  defp variant_filename(:thumb), do: "thumb.webp"
  defp variant_filename(:medium), do: "medium.webp"
  defp variant_filename(:full), do: "full.webp"

  defp image_mime(filename) do
    case filename |> Path.extname() |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      _ -> nil
    end
  end
end
