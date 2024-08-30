defmodule Instagrain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InstagrainWeb.Telemetry,
      Instagrain.Repo,
      {DNSCluster, query: Application.get_env(:instagrain, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Instagrain.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Instagrain.Finch},

      # Start a worker by calling: Instagrain.Worker.start_link(arg)
      {Registry, keys: :unique, name: Instagrain.Conversations.Registry},
      {Instagrain.Conversations.ConversationsSupervisor, []},
      # Start to serve requests, typically the last entry
      InstagrainWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Instagrain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InstagrainWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
