defmodule Instagrain.Repo.Migrations.BackfillHashtags do
  use Ecto.Migration

  def up do
    # Fetch all posts with captions that contain hashtags
    posts =
      repo().query!(
        "SELECT id, caption FROM posts WHERE caption LIKE '%#%'",
        []
      )

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    for [post_id, caption] <- posts.rows do
      tag_names =
        Regex.scan(~r/(?<!\S)#([a-zA-Z0-9_]+)/, caption)
        |> Enum.map(fn [_, tag] -> String.downcase(tag) end)
        |> Enum.uniq()

      for name <- tag_names do
        repo().query!(
          "INSERT INTO hashtags (name, post_count, inserted_at, updated_at) VALUES ($1, 0, $2, $2) ON CONFLICT (name) DO NOTHING",
          [name, now]
        )

        %{rows: [[hashtag_id]]} =
          repo().query!("SELECT id FROM hashtags WHERE name = $1", [name])

        repo().query!(
          "INSERT INTO post_hashtags (post_id, hashtag_id, inserted_at, updated_at) VALUES ($1, $2, $3, $3) ON CONFLICT DO NOTHING",
          [post_id, hashtag_id, now]
        )
      end
    end

    # Recount post_count for all hashtags based on actual junction entries
    repo().query!(
      "UPDATE hashtags SET post_count = (SELECT COUNT(*) FROM post_hashtags WHERE post_hashtags.hashtag_id = hashtags.id)"
    )
  end

  def down do
    # No-op: we don't want to remove hashtag data on rollback
    :ok
  end
end
