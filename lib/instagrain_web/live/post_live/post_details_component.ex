defmodule InstagrainWeb.PostLive.PostDetailsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex max-md:flex-col border">
      <div class="flex-1 md:max-w-[600px] md:shrink max-md:w-full">
        <.live_component
          id={"post-details-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
      </div>
      <div class="md:w-96 max-md:w-full flex flex-col">
        <div class="flex items-center border-b">
          <div class="flex-1">
            <.user_post_header user={@post.user} current_user={@current_user} />
          </div>
          <div class="flex justify-end px-4">
            <.menu
              current_user={@current_user}
              modal_id={"post-details-menu-#{@post.id}"}
              post={@post}
            />
          </div>
        </div>

        <div class="flex-1 border-b">
          Comments
        </div>

        <div>
          Icons, likes etc
        </div>

        <div>
          123 likes
        </div>

        <div>
          Comment from user
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, show_more: false, comment: "")}
  end
end
