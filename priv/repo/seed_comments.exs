defmodule Instagrain.Seeds.Comments do
  @moduledoc """
  Seeds comments, threaded replies, and comment likes.

  Can be run standalone on an already-seeded database:

      mix run priv/repo/seed_comments.exs

  Or as part of the full seed via `Instagrain.Seeds.Comments.run/2`.
  """

  alias Instagrain.Repo
  alias Instagrain.Feed

  @comment_texts [
    "Love this! ❤️",
    "So beautiful 😍",
    "Amazing shot!",
    "This is incredible",
    "Goals 🙌",
    "Wow just wow",
    "Stunning!",
    "Can't get enough of this",
    "This made my day",
    "Obsessed with this",
    "Perfection 👌",
    "Need this in my life",
    "Absolutely gorgeous",
    "You're killing it!",
    "Fire 🔥🔥🔥",
    "So inspiring",
    "Yes yes yes!",
    "This is everything",
    "Living for this",
    "Take me there!",
    "Incredible vibes",
    "Seriously talented",
    "I can't even 😭",
    "How is this real?",
    "Dreamy ✨",
    "This deserves more likes",
    "Bookmarking this forever",
    "Major inspo",
    "Slay 💅",
    "Iconic",
    "So aesthetic",
    "My jaw dropped",
    "The colors tho 🎨",
    "10/10 would double tap again",
    "This is art",
    "I'm in love with this",
    "Brb crying this is so pretty",
    "Where is this?? I need to go",
    "Your feed is always immaculate",
    "Main character energy"
  ]

  @reply_texts [
    "Right?! Same here",
    "Totally agree!",
    "I know!! So good",
    "100% 🙌",
    "Couldn't have said it better",
    "Literally same",
    "This!! ^^",
    "Came here to say this",
    "So true",
    "Omg yes",
    "Facts!",
    "Hard agree 💯",
    "You took the words out of my mouth",
    "Thank you! 🥰",
    "Aww that's so sweet, thanks!",
    "Haha glad you like it!",
    "Appreciate the love ❤️",
    "You're too kind!",
    "Made my whole day with this comment",
    "Let's go together next time!",
    "It's even better in person!",
    "Thanks so much! Means a lot",
    "I was thinking the same thing",
    "Hahaha exactly 😂",
    "Right back at you!",
    "We should! DM me",
    "No you 😊",
    "Can confirm, it was amazing",
    "The vibes were unreal",
    "Next time for sure!"
  ]

  def run(users, posts) do
    IO.puts("Adding comments and replies...")

    user_ids = Enum.map(users, & &1.id)
    total = length(posts)
    comment_count = do_comments(posts, user_ids, total)

    IO.puts("Done with comments.\n")

    IO.puts("Adding likes to comments...")
    do_comment_likes(user_ids)
    IO.puts("Done with comment likes.\n")

    IO.puts("  #{comment_count} comments + replies created")
  end

  defp do_comments(posts, user_ids, total) do
    Enum.reduce(Enum.with_index(posts, 1), 0, fn {post, i}, acc ->
      # Each post gets 0-15 top-level comments
      comment_count = Enum.random(0..15)

      comments_created =
        Enum.map(1..max(comment_count, 1), fn _ ->
          if comment_count == 0 do
            []
          else
            commenter_id = Enum.random(user_ids)

            {:ok, comment} =
              Feed.create_comment(%{
                comment: Enum.random(@comment_texts),
                post_id: post.id,
                user_id: commenter_id
              })

            # 40% chance of getting 1-4 replies
            replies =
              if Enum.random(1..10) <= 4 do
                reply_count = Enum.random(1..4)

                Enum.map(1..reply_count, fn _ ->
                  replier_id = Enum.random(user_ids)

                  {:ok, reply} =
                    Feed.create_comment(%{
                      comment: Enum.random(@reply_texts),
                      post_id: post.id,
                      user_id: replier_id,
                      reply_to_id: comment.id
                    })

                  # 30% chance of a reply-to-reply (deeper thread)
                  if Enum.random(1..10) <= 3 do
                    deeper_replier_id = Enum.random(user_ids)

                    {:ok, _} =
                      Feed.create_comment(%{
                        comment: Enum.random(@reply_texts),
                        post_id: post.id,
                        user_id: deeper_replier_id,
                        reply_to_id: reply.id
                      })

                    2
                  else
                    1
                  end
                end)
              else
                []
              end

            [1 | List.flatten(replies)]
          end
        end)
        |> List.flatten()
        |> Enum.sum()

      if rem(i, 100) == 0, do: IO.puts("  Commented on #{i}/#{total} posts")
      acc + comments_created
    end)
  end

  defp do_comment_likes(user_ids) do
    alias Instagrain.Feed.Post.Comment

    all_comments = Repo.all(Comment)
    total = length(all_comments)

    Enum.each(Enum.with_index(all_comments, 1), fn {comment, i} ->
      # Each comment gets 0-10 likes
      like_count = Enum.random(0..10)

      user_ids
      |> Enum.shuffle()
      |> Enum.take(like_count)
      |> Enum.each(fn uid ->
        Feed.like_comment(comment.id, uid)
      end)

      if rem(i, 500) == 0, do: IO.puts("  Liked #{i}/#{total} comments")
    end)
  end
end

# --- Standalone execution ---
# When run directly: mix run priv/repo/seed_comments.exs

alias Instagrain.Repo
alias Instagrain.Accounts.User
alias Instagrain.Feed.Post

users = Repo.all(User)
posts = Repo.all(Post)

IO.puts("Found #{length(users)} users and #{length(posts)} posts.\n")

Instagrain.Seeds.Comments.run(users, posts)
