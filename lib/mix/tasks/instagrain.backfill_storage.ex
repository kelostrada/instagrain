defmodule Mix.Tasks.Instagrain.BackfillStorage do
  use Mix.Task

  @shortdoc "Upload legacy post and avatar images to object storage"

  @moduledoc """
  Walks every user with an avatar and every post resource whose
  storage_key column is still nil, reads the local file from
  `priv/static/uploads/...`, runs it through the upload pipeline
  (variants + original to MinIO), and persists the returned key.

  Re-running is safe: rows already keyed are filtered out by the query,
  and rows whose local file is missing are skipped and counted.

  ## Options

    * `--dry-run`   List rows that would be processed without touching
                    the bucket or DB.
    * `--limit N`   Cap rows per category to N (useful for smoke
                    testing on a slice).

  ## Examples

      mix instagrain.backfill_storage --dry-run --limit 5
      mix instagrain.backfill_storage --limit 50
      mix instagrain.backfill_storage

  In production releases (no Mix), invoke the underlying module directly:

      bin/instagrain rpc 'IO.inspect(Instagrain.Backfill.run([]))'
  """

  @switches [dry_run: :boolean, limit: :integer]

  @impl true
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(argv, strict: @switches)
    log = fn msg -> Mix.shell().info(msg) end

    summary = Instagrain.Backfill.run(Keyword.put(opts, :log, log))

    log.("")
    log.("---- summary ----")

    for {kind, %{total: total, ok: ok, skipped: skipped, failed: failed}} <- summary do
      log.("#{kind}: total=#{total} ok=#{ok} skipped=#{skipped} failed=#{failed}")
    end
  end
end
