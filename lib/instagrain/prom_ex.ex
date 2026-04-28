defmodule Instagrain.PromEx do
  @moduledoc """
  Prometheus metrics for Instagrain. Mounted at `/metrics` (see router).
  Scraped by the somsiad stack on the Air via host.docker.internal:4163.
  """
  use PromEx, otp_app: :instagrain

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: InstagrainWeb.Router, endpoint: InstagrainWeb.Endpoint},
      Plugins.Ecto,
      Plugins.PhoenixLiveView
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards, do: []
end
