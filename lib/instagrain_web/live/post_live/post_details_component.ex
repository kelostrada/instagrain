defmodule InstagrainWeb.PostLive.PostDetailsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex max-md:flex-col">
      <div class="flex-1 md:max-w-[600px] md:shrink max-md:w-full">
        <.live_component
          id={"post-details-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
      </div>
      <div class="md:w-96 max-md:w-full"></div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, show_more: false, comment: "")}
  end
end
