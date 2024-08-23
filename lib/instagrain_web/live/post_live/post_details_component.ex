defmodule InstagrainWeb.PostLive.PostDetailsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex max-md:flex-col min-h-[400px] md:max-h-[80vh]">
      <div class="flex items-center md:hidden">
        <div class="flex-1 py-2.5">
          <.user_post_header user={@post.user} current_user={@current_user} size={:sm} />
        </div>
        <div class="flex justify-end px-4">
          <.menu
            current_user={@current_user}
            modal_id={"post-details-menu-mobile-#{@post.id}"}
            post={@post}
          />
        </div>
      </div>
      <div class="flex-1 md:max-w-[700px] md:shrink max-md:w-full md:border-r flex items-center justify-center bg-black">
        <.live_component
          id={"post-details-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
      </div>
      <div class="md:w-85 max-md:w-full flex flex-col">
        <div class="flex items-center border-b max-md:hidden">
          <div class="flex-1 pt-3.5 pb-2.5">
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

        <div class="flex-1 border-b overflow-y-auto max-md:hidden p-4">
          <div class="flex gap-3">
            <div>
              <.avatar user={@post.user} size={:sm} />
            </div>
            <div class="flex-1">
              <div>
                <.username user={@post.user} />
                <.time prefix="• " datetime={@post.inserted_at} />
              </div>
              <div>
                <.user_content text={@post.caption} />
              </div>
            </div>
          </div>

          <.live_component
            id={"post-details-comments-#{@post.id}"}
            module={InstagrainWeb.PostLive.CommentsComponent}
            current_user={@current_user}
            post={@post}
            comment_input_id={"post-details-comment-input-#{@post.id}"}
          />
        </div>

        <div class="px-3">
          <.live_component
            id={"post-details-icons-#{@post.id}"}
            module={InstagrainWeb.PostLive.IconsComponent}
            current_user={@current_user}
            post={@post}
            comment_input_id={"post-details-comment-input-#{@post.id}"}
          />
        </div>

        <div class="px-3">
          <.likes post={@post} current_user={@current_user} />
          <div class="md:hidden">
            <.live_component
              id={"post-details-caption-#{@post.id}"}
              module={InstagrainWeb.PostLive.CaptionComponent}
              current_user={@current_user}
              post={@post}
            />
          </div>
          <.time_ago datetime={@post.inserted_at} class="text-xs text-neutral-500" />
        </div>

        <div class="px-3 md:hidden">
          <.live_component
            id={"post-details-highlighted-comments-#{@post.id}"}
            module={InstagrainWeb.PostLive.HighlightedCommentsComponent}
            current_user={@current_user}
            post={@post}
          />
        </div>

        <div class="p-3 flex gap-2 items-center max-md:hidden">
          <div class="">
            <.avatar user={@post.user} size={:sm} />
          </div>
          <div class="pt-4 flex-1">
            <.live_component
              id={"post-details-comment-form-#{@post.id}"}
              module={InstagrainWeb.PostLive.CommentComponent}
              current_user={@current_user}
              post={@post}
              comment_input_id={"post-details-comment-input-#{@post.id}"}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
