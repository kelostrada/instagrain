defmodule Instagrain.Uploads do
  @moduledoc """
  Best-effort upload of a freshly-uploaded local file to object storage.

  During the dual-write phase the local filesystem remains the source of
  truth — `upload/2` is intentionally non-fatal: any failure (network,
  decode error, missing endpoint) is logged and returns `:error`, leaving
  the post / avatar to fall back to local-only storage. The next backfill
  run will pick up rows whose `storage_key` is still nil.

  Successful uploads write a layout like:

      <prefix>/<uuid>/original.<ext>
      <prefix>/<uuid>/thumb_jpg.jpg     # OG/social-preview compatible
      <prefix>/<uuid>/thumb.webp
      <prefix>/<uuid>/medium.webp
      <prefix>/<uuid>/full.webp

  …and returns `{:ok, "<prefix>/<uuid>"}` so the caller can persist the
  prefix in `storage_key` (or `avatar_storage_key`).
  """

  alias Instagrain.{Imaging, Storage}

  require Logger

  @image_exts ~w(.jpg .jpeg .png .webp)
  @video_exts ~w(.mp4 .mov .avi .mpg)

  @spec upload(Path.t(), String.t()) :: {:ok, String.t()} | :error
  def upload(local_path, prefix) when is_binary(local_path) and is_binary(prefix) do
    storage_key = "#{prefix}/#{Ecto.UUID.generate()}"
    ext = local_path |> Path.extname() |> String.downcase()

    try do
      do_upload(local_path, storage_key, ext)
    rescue
      e ->
        Logger.warning("Uploads.upload crashed for #{local_path}: #{Exception.message(e)}")
        :error
    end
  end

  defp do_upload(local_path, storage_key, ext) when ext in @image_exts do
    with :ok <- put_file(local_path, "#{storage_key}/original#{ext}", mime_for_image(ext)),
         {:ok, variants} <- Imaging.process(local_path),
         :ok <- put_variants(storage_key, variants) do
      {:ok, storage_key}
    else
      err ->
        Logger.warning("image upload failed for #{local_path}: #{inspect(err)}")
        :error
    end
  end

  defp do_upload(local_path, storage_key, ext) when ext in @video_exts do
    case put_file(local_path, "#{storage_key}/original#{ext}", "application/octet-stream") do
      :ok ->
        {:ok, storage_key}

      err ->
        Logger.warning("video upload failed for #{local_path}: #{inspect(err)}")
        :error
    end
  end

  defp do_upload(local_path, _storage_key, ext) do
    Logger.warning("upload skipped — unknown extension #{inspect(ext)} for #{local_path}")
    :error
  end

  defp put_file(local_path, key, content_type) do
    case File.read(local_path) do
      {:ok, bin} -> Storage.put(key, bin, content_type: content_type)
      err -> err
    end
  end

  defp put_variants(storage_key, variants) do
    Enum.reduce_while(variants, :ok, fn {name, %{binary: bin, content_type: ct, ext: ext}}, :ok ->
      key = "#{storage_key}/#{name}.#{ext}"

      case Storage.put(key, bin, content_type: ct) do
        :ok -> {:cont, :ok}
        err -> {:halt, err}
      end
    end)
  end

  defp mime_for_image(".jpg"), do: "image/jpeg"
  defp mime_for_image(".jpeg"), do: "image/jpeg"
  defp mime_for_image(".png"), do: "image/png"
  defp mime_for_image(".webp"), do: "image/webp"
end
