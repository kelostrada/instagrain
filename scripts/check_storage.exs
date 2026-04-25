# End-to-end smoke test for the image storage pipeline.
#
# Requires MinIO to be running (`docker compose up -d minio minio-init`).
# Run with: `mix run scripts/check_storage.exs`
#
# Picks a sample image from the local uploads directory, generates every
# variant, uploads them to the configured bucket, fetches them back over
# plain HTTP (proving public-read works for OG crawlers), then deletes them.

alias Instagrain.{Imaging, Storage}

uploads_dir = Path.join([:code.priv_dir(:instagrain), "static", "uploads"])

sample =
  uploads_dir
  |> File.ls!()
  |> Enum.find(fn name ->
    full = Path.join(uploads_dir, name)
    File.regular?(full) and Path.extname(name) in [".jpg", ".jpeg", ".png", ".webp"]
  end)
  |> case do
    nil -> raise "no sample image found in #{uploads_dir}"
    name -> Path.join(uploads_dir, name)
  end

IO.puts("source: #{sample} (#{File.stat!(sample).size} bytes)")

{:ok, variants} = Imaging.process(sample)

key_prefix = "probe/run-#{System.unique_integer([:positive])}"

for {name, %{binary: bin, content_type: ct, ext: ext}} <- variants do
  key = "#{key_prefix}/#{name}.#{ext}"
  :ok = Storage.put(key, bin, content_type: ct)

  url = Storage.url(key)
  {:ok, %{status: status, headers: headers}} = Req.get(url, decode_body: false)

  ct_header =
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == "content-type", do: v
    end)

  IO.puts("  #{name}: #{byte_size(bin)} bytes, fetched HTTP #{status}, ct=#{inspect(ct_header)}")
  :ok = Storage.delete(key)
end

IO.puts("OK")
