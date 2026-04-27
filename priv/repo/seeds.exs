# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# To reset and reseed:
#
#     mix ecto.reset
#

alias Instagrain.Repo
alias Instagrain.Accounts.User
alias Instagrain.Feed
alias Instagrain.Feed.Post
alias Instagrain.Profiles
alias Instagrain.Uploads

# --- Helpers ---

defmodule Instagrain.Seeds.Helpers do
  @doc """
  Downloads `url` to a temp file, runs it through the upload pipeline
  (variants + original to object storage) and returns `{:ok, storage_key}`
  or `:error`. Cleans up the temp file in either case.
  """
  def download_and_upload(url, prefix, ext \\ ".jpg") do
    temp =
      Path.join(System.tmp_dir!(), "instagrain-seed-#{System.unique_integer([:positive])}#{ext}")

    try do
      case Req.get(url, redirect: true, max_redirects: 5, receive_timeout: 30_000) do
        {:ok, %{status: 200, body: body}} when is_binary(body) ->
          File.write!(temp, body)

          case Uploads.upload(temp, prefix) do
            {:ok, key} ->
              {:ok, key}

            {:error, reason} ->
              IO.puts("  Warning: upload failed for #{url}: #{inspect(reason)}")
              :error
          end

        other ->
          IO.puts("  Warning: failed to download #{url}: #{inspect(other)}")
          :error
      end
    after
      File.rm(temp)
    end
  end

  def random_hashtags(count) do
    tags = [
      "#photography",
      "#photooftheday",
      "#instagood",
      "#love",
      "#beautiful",
      "#nature",
      "#travel",
      "#art",
      "#happy",
      "#cute",
      "#fashion",
      "#style",
      "#food",
      "#fitness",
      "#selfie",
      "#sunset",
      "#cat",
      "#dog",
      "#pretty",
      "#summer",
      "#winter",
      "#friends",
      "#fun",
      "#life",
      "#mood",
      "#explore",
      "#adventure",
      "#wanderlust",
      "#vibes",
      "#blessed",
      "#ootd",
      "#throwback",
      "#goals",
      "#morning",
      "#coffee",
      "#weekend",
      "#chill",
      "#goodvibes",
      "#instadaily",
      "#picoftheday",
      "#landscape",
      "#sky",
      "#beach",
      "#mountains",
      "#city",
      "#street",
      "#architecture",
      "#portrait",
      "#flowers",
      "#aesthetic"
    ]

    tags |> Enum.shuffle() |> Enum.take(count)
  end

  def random_caption do
    captions = [
      "Living my best life",
      "Just another day in paradise",
      "Chasing sunsets",
      "Good times and tan lines",
      "Making memories",
      "Can't stop won't stop",
      "This is what happiness looks like",
      "Adventures await",
      "Feeling grateful today",
      "Keep it simple",
      "Lost in the moment",
      "Escape the ordinary",
      "Collecting moments, not things",
      "Life is short, make it sweet",
      "Dream big, travel far",
      "Finding beauty everywhere",
      "Today was a good day",
      "Less perfection, more authenticity",
      "Wander often, wonder always",
      "Some days are just perfect",
      "Sunshine state of mind",
      "That golden hour glow",
      "Weekend mode activated",
      "Just vibes",
      "Doing what I love",
      "It's the little things",
      "New day, new adventure",
      "Stay wild, moon child",
      "Let the good times roll",
      "Going with the flow"
    ]

    caption = Enum.random(captions)
    hashtag_count = Enum.random(2..6)
    hashtags = random_hashtags(hashtag_count) |> Enum.join(" ")

    "#{caption}\n\n#{hashtags}"
  end

  def random_full_name do
    first_names = [
      "Emma",
      "Liam",
      "Olivia",
      "Noah",
      "Ava",
      "Ethan",
      "Sophia",
      "Mason",
      "Isabella",
      "William",
      "Mia",
      "James",
      "Charlotte",
      "Benjamin",
      "Amelia",
      "Lucas",
      "Harper",
      "Henry",
      "Evelyn",
      "Alexander",
      "Luna",
      "Sebastian",
      "Ella",
      "Jack",
      "Chloe",
      "Daniel",
      "Aria",
      "Matthew",
      "Lily",
      "Owen",
      "Zoe",
      "Leo",
      "Nora",
      "David",
      "Riley",
      "Jackson",
      "Layla",
      "Samuel",
      "Grace",
      "Aiden",
      "Scarlett",
      "Joseph",
      "Stella",
      "Carter",
      "Violet",
      "Kai",
      "Aurora",
      "Mila",
      "Ellie",
      "Theo"
    ]

    last_names = [
      "Smith",
      "Johnson",
      "Williams",
      "Brown",
      "Jones",
      "Garcia",
      "Miller",
      "Davis",
      "Rodriguez",
      "Martinez",
      "Anderson",
      "Taylor",
      "Thomas",
      "Moore",
      "Jackson",
      "Martin",
      "Lee",
      "Thompson",
      "White",
      "Harris",
      "Clark",
      "Lewis",
      "Robinson",
      "Walker",
      "Young",
      "Allen",
      "King",
      "Wright",
      "Scott",
      "Torres",
      "Hill",
      "Green",
      "Adams",
      "Baker",
      "Nelson",
      "Mitchell",
      "Campbell",
      "Roberts",
      "Carter",
      "Phillips",
      "Evans",
      "Turner",
      "Parker",
      "Collins",
      "Edwards",
      "Stewart",
      "Murphy",
      "Cook"
    ]

    "#{Enum.random(first_names)} #{Enum.random(last_names)}"
  end

  def random_bio do
    bios = [
      "Living life one photo at a time",
      "Travel | Food | Adventure",
      "Just a soul with good vibes",
      "Creating my own sunshine",
      "Life is beautiful",
      "Coffee addict & dreamer",
      "Wanderlust & city dust",
      "Digital nomad",
      "Lover of all things beautiful",
      "Making the world a better place",
      "Storyteller | Explorer",
      "Work hard, travel harder",
      "Chasing dreams & sunsets",
      "Photography enthusiast",
      "Born to explore",
      "On a mission to live fully",
      "Art is my therapy",
      "Not all who wander are lost",
      "Living for the moments",
      "Keep it real, keep it simple"
    ]

    Enum.random(bios)
  end
end

alias Instagrain.Seeds.Helpers

# --- Create Users ---

IO.puts("Creating 100 users...")

users =
  Enum.map(1..100, fn i ->
    username =
      Helpers.random_full_name()
      |> String.downcase()
      |> String.replace(" ", ".")
      |> then(fn name -> "#{name}#{Enum.random(1..999)}" end)

    # Ensure uniqueness
    username = "#{username}_#{i}"

    {:ok, user} =
      %User{}
      |> User.registration_changeset(%{
        email: "#{username}@example.com",
        username: username,
        password: "password123456"
      })
      |> User.confirm_changeset()
      |> Repo.insert()

    # Update profile info
    {:ok, user} =
      user
      |> User.profile_changeset(%{
        full_name: Helpers.random_full_name(),
        description: Helpers.random_bio()
      })
      |> Repo.update()

    if rem(i, 10) == 0, do: IO.puts("  Created #{i}/100 users")
    user
  end)

IO.puts("Done creating users.\n")

# --- Upload Avatars ---

IO.puts("Uploading avatars to object storage...")

users =
  Enum.map(Enum.with_index(users, 1), fn {user, i} ->
    # Use randomuser.me for realistic portrait avatars
    gender = Enum.random(["men", "women"])
    portrait_id = Enum.random(1..99)
    url = "https://randomuser.me/api/portraits/#{gender}/#{portrait_id}.jpg"

    case Helpers.download_and_upload(url, "avatars") do
      {:ok, key} ->
        {:ok, user} =
          user
          |> User.avatar_changeset(%{avatar_storage_key: key})
          |> Repo.update()

        if rem(i, 20) == 0, do: IO.puts("  Uploaded #{i}/100 avatars")
        user

      :error ->
        if rem(i, 20) == 0, do: IO.puts("  Uploaded #{i}/100 avatars (some failed)")
        user
    end
  end)

IO.puts("Done uploading avatars.\n")

# --- Create Posts with Images ---

IO.puts("Creating posts with images...")

Enum.reduce(Enum.with_index(users, 1), 0, fn {user, user_idx}, acc ->
  post_count = Enum.random(5..20)

  Enum.each(1..post_count, fn _post_idx ->
    # Create post
    {:ok, post} =
      Feed.create_post(%{
        caption: Helpers.random_caption(),
        user_id: user.id,
        likes: Enum.random(0..500),
        hide_likes: Enum.random([true, false, false, false, false]),
        disable_comments: false
      })

    # Each post gets 1-4 images
    image_count = Enum.random(1..4)

    Enum.each(1..image_count, fn img_idx ->
      # Use picsum.photos for random images (640x640 square like Instagram)
      seed = post.id * 10 + img_idx
      url = "https://picsum.photos/seed/#{seed}/640/640.jpg"

      case Helpers.download_and_upload(url, "posts") do
        {:ok, key} ->
          {:ok, _resource} =
            Feed.create_resource(%{
              post_id: post.id,
              storage_key: key,
              type: :photo,
              alt: "Photo #{img_idx}"
            })

        :error ->
          :ok
      end
    end)
  end)

  if rem(user_idx, 10) == 0, do: IO.puts("  Processed #{user_idx}/100 users")
  acc + post_count
end)

IO.puts("Done creating posts.\n")

# --- Create Follow Relationships ---

IO.puts("Creating follow relationships...")

Enum.each(Enum.with_index(users, 1), fn {user, i} ->
  # Each user follows 10-40 random other users
  follow_count = Enum.random(10..40)

  users
  |> Enum.reject(fn u -> u.id == user.id end)
  |> Enum.shuffle()
  |> Enum.take(follow_count)
  |> Enum.each(fn target ->
    Profiles.follow_user(user.id, target.id)
  end)

  if rem(i, 20) == 0, do: IO.puts("  Processed #{i}/100 users")
end)

IO.puts("Done creating follows.\n")

# --- Add some likes ---

IO.puts("Adding likes to posts...")

all_posts = Repo.all(Post)

Enum.each(Enum.with_index(all_posts, 1), fn {post, i} ->
  # Random subset of users like each post
  like_count = min(Enum.random(0..30), length(users))

  users
  |> Enum.shuffle()
  |> Enum.take(like_count)
  |> Enum.each(fn user ->
    Feed.like(post.id, user.id)
  end)

  if rem(i, 100) == 0, do: IO.puts("  Liked #{i}/#{length(all_posts)} posts")
end)

IO.puts("Done with likes.\n")

# --- Add Comments and Replies ---

Instagrain.Seeds.Comments.run(users, all_posts)

total_users = length(users)
total_posts = length(all_posts)
IO.puts("Summary:")
IO.puts("  #{total_users} users")
IO.puts("  #{total_posts} posts")
IO.puts("  Images stored in object storage (MinIO)")
IO.puts("\nRun with: mix run priv/repo/seeds.exs")
