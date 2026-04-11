# Instagrain

Instagram clone built with Elixir, Phoenix Framework, and Phoenix LiveView.

## Tech Stack

- **Language**: Elixir 1.19 / Erlang/OTP 28
- **Framework**: Phoenix 1.7 with Phoenix LiveView
- **Database**: PostgreSQL (via Ecto)
- **Assets**: esbuild + Tailwind CSS
- **HTTP Server**: Bandit

## Features

- User authentication (registration, login, password reset, email confirmation)
- Posts with multiple image uploads
- Comments with nested replies
- Likes on posts and comments
- Save/bookmark posts
- User profiles with follow/unfollow
- Real-time direct messaging (via GenServer-based ConversationServer)
- Paginated feed

## Project Structure

- `lib/instagrain/` - Business logic contexts:
  - `accounts/` - User auth, tokens, profiles
  - `feed/` - Posts, comments, likes, saves, resources
  - `conversations/` - Direct messaging system
  - `profiles/` - Follow relationships
- `lib/instagrain_web/` - Web layer (controllers, LiveViews, components)
- `priv/repo/migrations/` - Database migrations

## Common Commands

```bash
mix setup              # Install deps, create DB, run migrations, build assets
mix test               # Run tests (creates DB and runs migrations automatically)
mix phx.server         # Start dev server at localhost:4000
mix ecto.reset         # Drop, create, migrate DB and run seeds
mix deps.get           # Fetch dependencies
```

## Development

- PostgreSQL must be running locally (user: postgres, password: postgres)
- Tests use a sandboxed DB connection pool
- Assets are built with esbuild and Tailwind (installed via mix tasks)
