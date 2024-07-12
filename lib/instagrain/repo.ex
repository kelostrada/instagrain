defmodule Instagrain.Repo do
  use Ecto.Repo,
    otp_app: :instagrain,
    adapter: Ecto.Adapters.Postgres
end
