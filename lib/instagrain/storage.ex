defmodule Instagrain.Storage do
  @moduledoc """
  Thin wrapper over an S3-compatible object store (MinIO in dev and prod).

  Reads connection settings from `Application.get_env(:instagrain, __MODULE__)`.
  Public URLs are built from the configured `:public_url`, which in prod points
  at the Cloudflare-tunnelled CDN subdomain so OG/link-preview crawlers can
  fetch images directly without signed URLs.
  """

  alias ExAws.S3

  @type key :: String.t()

  @spec put(key, binary, keyword) :: :ok | {:error, term}
  def put(key, body, opts \\ []) when is_binary(key) and is_binary(body) do
    s3_opts = [content_type: Keyword.get(opts, :content_type, "application/octet-stream")]

    bucket()
    |> S3.put_object(key, body, s3_opts)
    |> ExAws.request(ex_aws_config())
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @spec delete(key) :: :ok | {:error, term}
  def delete(key) when is_binary(key) do
    bucket()
    |> S3.delete_object(key)
    |> ExAws.request(ex_aws_config())
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @spec url(key) :: String.t()
  def url(key) when is_binary(key) do
    "#{public_url()}/#{bucket()}/#{key}"
  end

  @spec bucket() :: String.t()
  def bucket, do: fetch!(:bucket)

  defp public_url, do: fetch!(:public_url) |> String.trim_trailing("/")

  defp fetch!(key) do
    :instagrain
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end

  defp ex_aws_config do
    cfg = Application.fetch_env!(:instagrain, __MODULE__)
    uri = URI.parse(Keyword.fetch!(cfg, :endpoint))

    [
      access_key_id: Keyword.fetch!(cfg, :access_key_id),
      secret_access_key: Keyword.fetch!(cfg, :secret_access_key),
      region: Keyword.get(cfg, :region, "us-east-1"),
      scheme: "#{uri.scheme}://",
      host: uri.host,
      port: uri.port || default_port(uri.scheme)
    ]
  end

  defp default_port("https"), do: 443
  defp default_port(_), do: 80
end
