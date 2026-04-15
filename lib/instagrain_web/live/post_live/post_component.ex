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
          following_user_ids={@following_user_ids}
        />
      </.modal>

      <div class="flex items-center justify-between pb-3 max-sm:px-3">
        <div class="flex items-center gap-2">
          <.avatar user={@post.user} />

          <div>
            <div class="flex items-center gap-1">
              <.username user={@post.user} />
              <.time prefix="• " datetime={@post.inserted_at} />
            </div>
            <p :if={@post.location} class="text-xs text-neutral-500 leading-tight">
              <%= @post.location.name %>
            </p>
          </div>
        </div>
        <div>
          <.menu current_user={@current_user} modal_id={"post-menu-#{@post.id}"} post={@post} following_user_ids={@following_user_ids} />
        </div>
      </div>

      <div
        class="border-[0.5px] relative"
        id={"post-dbl-tap-#{@post.id}"}
        phx-hook="DoubleTapLike"
        data-liked={to_string(@post.liked_by_current_user?)}
        data-target={"post-icons-#{@post.id}-root"}
      >
        <.live_component
          id={"post-slider-#{@post.id}"}
          module={InstagrainWeb.PostLive.SliderComponent}
          resources={@post.resources}
        />
        <%!-- Heart animation overlay --%>
        <div
          data-heart-overlay
          class="absolute inset-0 flex items-center justify-center pointer-events-none opacity-0"
        >
          <svg class="w-24 h-24 text-white drop-shadow-lg" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
          </svg>
        </div>
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
