defmodule InstagrainWeb.PostLive.PostComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"post-#{@post.id}"} class="w-full">
      <.modal id={"post-details-modal-#{@post.id}"} corner_style={:md}>
        <.live_component
          current_user={@current_user}
          module={InstagrainWeb.PostLive.PostDetailsComponent}
          id={"#post-details-modal-content-#{@post.id}"}
          post={@post}
        />
      </.modal>

      <div class="flex items-center justify-between pb-3 max-sm:px-3">
        <div class="flex items-center gap-2">
          <.avatar user={@post.user} />

          <div>
            <span class="text-black font-bold text-sm">
              <%= @post.user.username %>
            </span>

            <.time prefix="• " datetime={@post.inserted_at} />
          </div>
        </div>
        <div>
          <.menu current_user={@current_user} modal_id={"post-menu-#{@post.id}"} post={@post} />
        </div>
      </div>

      <div class="border-[0.5px]">
        <.live_component
          id={"post-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
      </div>

      <div class="max-sm:px-3">
        <.live_component
          id={"post-icons-#{@post.id}"}
          module={InstagrainWeb.PostLive.IconsComponent}
          current_user={@current_user}
          post={@post}
          comment_input_id={"post-details-comment-input-#{@post.id}"}
        />
      </div>

      <div class="max-sm:px-3">
        <.likes post={@post} current_user={@current_user} />
      </div>

      <div class="my-1 text-sm max-sm:px-3">
        <.live_component
          id={"post-caption-#{@post.id}"}
          module={InstagrainWeb.PostLive.CaptionComponent}
          current_user={@current_user}
          post={@post}
        />
      </div>

      <div class="max-sm:px-3">
        <.live_component
          id={"post-comments-#{@post.id}"}
          module={InstagrainWeb.PostLive.HighlightedCommentsComponent}
          current_user={@current_user}
          post={@post}
        />
      </div>

      <div class="max-sm:px-3">
        <.live_component
          id={"post-comment-form-#{@post.id}"}
          module={InstagrainWeb.PostLive.CommentComponent}
          current_user={@current_user}
          post={@post}
          comment_input_id={"post-comment-input-#{@post.id}"}
        />
      </div>
    </div>
    """
  end
end
