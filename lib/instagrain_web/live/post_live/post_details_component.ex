defmodule InstagrainWeb.PostLive.PostDetailsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex max-md:flex-col min-h-[400px] max-h-[80vh]">
      <div class="flex-1 md:max-w-[600px] md:shrink max-md:w-full border-r flex items-center justify-center bg-black">
        <.live_component
          id={"post-details-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
      </div>
      <div class="md:w-96 max-md:w-full flex flex-col">
        <div class="flex items-center border-b">
          <div class="flex-1">
            <.user_post_header user={@post.user} current_user={@current_user} size={:sm} />
          </div>
          <div class="flex justify-end px-4">
            <.menu
              current_user={@current_user}
              modal_id={"post-details-menu-#{@post.id}"}
              post={@post}
            />
          </div>
        </div>

        <div class="flex-1 border-b overflow-y-auto">
          <div class="flex">
            <div class="pl-4 pr-3 py-4">
              <.avatar user={@post.user} size={:sm} />
            </div>
            <div class="flex-1 py-4">
              <div>
                <span class="text-black font-bold text-sm">
                  <%= @post.user.username %>
                </span>
                <.time datetime={@post.inserted_at} />
              </div>
              <div>
                <.caption post={@post} />
              </div>
            </div>
          </div>
        </div>

        <div>
          Icons, likes etc
        </div>

        <div>
          123 likes <br />
          <%= @post.id %>
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
