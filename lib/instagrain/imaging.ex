defmodule Instagrain.Imaging do
  @moduledoc """
  Generates resized variants of an uploaded image using libvips (via the
  `image` package).

  Variants are tuned for an Instagram-style feed:

    * `:thumb_jpg` — 400px wide JPEG, used for OG / Twitter card / link-preview
       crawlers (some, like Signal, are picky about WebP and large payloads).
    * `:thumb`     — 400px wide WebP for in-app feed thumbnails.
    * `:medium`    — 1080px wide WebP for the main feed display.
    * `:full`      — up to 2048px wide WebP for the lightbox / detail view.

  EXIF / colour-profile metadata is stripped on output for privacy and size.
  Originals are preserved separately by the upload pipeline so we can
  re-derive new variants in the future (e.g. AVIF) without losing quality.
  """

  @type variant_name :: :thumb_jpg | :thumb | :medium | :full
  @type variant :: %{binary: binary, content_type: String.t(), ext: String.t()}

  @variants [
    {:thumb_jpg, %{max_width: 400, format: :jpeg, quality: 80, content_type: "image/jpeg", ext: "jpg"}},
    {:thumb, %{max_width: 400, format: :webp, quality: 80, content_type: "image/webp", ext: "webp"}},
    {:medium, %{max_width: 1080, format: :webp, quality: 85, content_type: "image/webp", ext: "webp"}},
    {:full, %{max_width: 2048, format: :webp, quality: 90, content_type: "image/webp", ext: "webp"}}
  ]

  @spec variants() :: [{variant_name, map}]
  def variants, do: @variants

  @doc """
  Reads `path`, generates each variant, and returns a map keyed by variant name.
  """
  @spec process(Path.t()) :: {:ok, %{variant_name => variant}} | {:error, term}
  def process(path) when is_binary(path) do
    with {:ok, image} <- Image.open(path) do
      original_width = Image.width(image)

      Enum.reduce_while(@variants, {:ok, %{}}, fn {name, spec}, {:ok, acc} ->
        case render(image, spec, original_width) do
          {:ok, binary} ->
            variant = %{binary: binary, content_type: spec.content_type, ext: spec.ext}
            {:cont, {:ok, Map.put(acc, name, variant)}}

          {:error, _} = err ->
            {:halt, err}
        end
      end)
    end
  end

  defp render(image, spec, original_width) do
    target = Map.fetch!(spec, :max_width)

    image
    |> maybe_resize(target, original_width)
    |> case do
      {:ok, resized} ->
        Image.write(resized, :memory,
          suffix: ".#{spec.ext}",
          quality: spec.quality,
          strip_metadata: true
        )

      {:error, _} = err ->
        err
    end
  end

  defp maybe_resize(image, target, original_width) when original_width <= target do
    {:ok, image}
  end

  defp maybe_resize(image, target, _original_width) do
    Image.thumbnail(image, "#{target}x")
  end
end
