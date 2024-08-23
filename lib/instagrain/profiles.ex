defmodule Instagrain.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query, warn: false
  alias Instagrain.Repo

  # alias Instagrain.Feed.Post
  alias Instagrain.Accounts.User

  def get_profile(username) do
    from(u in User, where: u.username == ^username)
    |> Repo.one()
    |> Repo.preload([:posts])
  end
end
