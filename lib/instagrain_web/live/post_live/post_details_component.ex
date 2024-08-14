defmodule InstagrainWeb.PostLive.PostDetailsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def render(assigns) do
    ~H"""
    <div class="wide-modal">
      Post details
    </div>
    """
  end
end
