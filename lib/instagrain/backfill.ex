defmodule Instagrain.Backfill do
  @moduledoc """
  Migrates legacy local-only image rows into object storage.

  Walks every user with an avatar and every post resource whose
  `storage_key` / `avatar_storage_key` is still nil, reads each local
  file from `priv/static/uploads/...`, runs it through `Uploads.upload/2`
  to generate variants, and persists the returned key.

  Re-runnable: rows already keyed are filtered out by the query, so a
  partial run can be resumed without re-uploading.
  """

  import Ecto.Query
  require Logger

  alias Instagrain.Accounts.User
  alias Instagrain.Feed.Post.Resource
  alias Instagrain.{Repo, Uploads}

  @type kind :: :avatars | :resources
  @type summary :: %{
          total: non_neg_integer(),
          ok: non_neg_integer(),
          skipped: non_neg_integer(),
          failed: non_neg_integer()
        }

  @spec run(keyword) :: %{avatars: summary, resources: summary}
  def run(opts \\ []) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    limit = Keyword.get(opts, :limit)
    log = Keyword.get(opts, :log, &Logger.info/1)

    %{
      avatars: backfill(:avatars, dry_run?, limit, log),
      resources: backfill(:resources, dry_run?, limit, log)
    }
  end

  defp backfill(kind, dry_run?, limit, log) do
    rows = fetch_rows(kind, limit)
    suffix = if dry_run?, do: " (dry run)", else: ""
    log.("[#{kind}] #{length(rows)} row(s) to process#{suffix}")

    Enum.reduce(rows, base_summary(rows), fn row, acc ->
      process_row(kind, row, dry_run?, log, acc)
    end)
  end

  defp fetch_rows(:avatars, limit) do
    User
    |> where([u], not is_nil(u.avatar) and is_nil(u.avatar_storage_key))
    |> select([u], %{id: u.id, label: u.username, file: u.avatar})
    |> maybe_limit(limit)
    |> Repo.all()
  end

  defp fetch_rows(:resources, limit) do
    Resource
    |> where([r], not is_nil(r.file) and is_nil(r.storage_key))
    |> select([r], %{id: r.id, label: r.post_id, file: r.file})
    |> maybe_limit(limit)
    |> Repo.all()
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, n) when is_integer(n), do: limit(query, ^n)

  defp process_row(kind, row, dry_run?, log, acc) do
    path = local_path(kind, row.file)
    rel = Path.relative_to_cwd(path)

    cond do
      not File.exists?(path) ->
        log.("[#{kind}] skip ##{row.id} (#{row.label}): file missing — #{rel}")
        increment(acc, :skipped)

      dry_run? ->
        log.("[#{kind}] would process ##{row.id} (#{row.label}): #{rel}")
        increment(acc, :ok)

      true ->
        case Uploads.upload(path, prefix(kind)) do
          {:ok, key} ->
            update_row!(kind, row.id, key)
            log.("[#{kind}] ok ##{row.id} (#{row.label}) -> #{key}")
            increment(acc, :ok)

          :error ->
            log.("[#{kind}] fail ##{row.id} (#{row.label}): #{rel}")
            increment(acc, :failed)
        end
    end
  end

  defp update_row!(:avatars, id, key) do
    {1, _} = Repo.update_all(where(User, [u], u.id == ^id), set: [avatar_storage_key: key])
  end

  defp update_row!(:resources, id, key) do
    {1, _} = Repo.update_all(where(Resource, [r], r.id == ^id), set: [storage_key: key])
  end

  defp local_path(:avatars, file),
    do: Path.join([uploads_dir(), "avatars", file])

  defp local_path(:resources, file),
    do: Path.join([uploads_dir(), file])

  defp uploads_dir,
    do: Path.join([:code.priv_dir(:instagrain), "static", "uploads"])

  defp prefix(:avatars), do: "avatars"
  defp prefix(:resources), do: "posts"

  defp base_summary(rows),
    do: %{total: length(rows), ok: 0, skipped: 0, failed: 0}

  defp increment(acc, key), do: Map.update!(acc, key, &(&1 + 1))
end
