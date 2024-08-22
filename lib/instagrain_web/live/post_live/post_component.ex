defmodule InstagrainWeb.PostLive.PostComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed

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

            <.time datetime={@post.inserted_at} />
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

      <%= unless @post.disable_comments do %>
        <% comments_length = length(@post.comments) %>

        <%= if comments_length > 0 do %>
          <div class="my-1 max-sm:px-3 text-sm">
            <.link
              class="text-neutral-500 text-sm font-medium"
              phx-click={show_modal("post-details-modal-#{@post.id}")}
            >
              <%= if comments_length == 1 do %>
                View 1 comment
              <% else %>
                View all <%= comments_length %> comments
              <% end %>
            </.link>
          </div>
        <% end %>

        <div :for={comment <- @highlighted_comments} class="my-1 max-sm:px-3 text-sm flex gap-2">
          <div class="grow">
            <span class="font-bold">
              <%= comment.user.username %>
            </span>
            <span><%= comment.comment %></span>
          </div>
          <div>
            <%= if comment.liked_by_current_user? do %>
              <span phx-click="unlike-comment" phx-value-comment_id={comment.id} phx-target={@myself}>
                <.icon
                  name="hero-heart-solid"
                  class="w-3 h-3 cursor-pointer hover:text-neutral-400 bg-red-500"
                />
              </span>
            <% else %>
              <span phx-click="like-comment" phx-value-comment_id={comment.id} phx-target={@myself}>
                <.icon name="hero-heart" class="w-3 h-3 cursor-pointer hover:text-neutral-400" />
              </span>
            <% end %>
          </div>
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
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    amount =
      case length(assigns.post.comments) do
        len when len < 3 -> 0
        len when len < 5 -> 1
        len when len < 10 -> 2
        _ -> 3
      end

    highlighted_comments =
      assigns.post.comments
      |> Enum.sort_by(& &1.likes, :desc)
      |> Enum.take(amount)

    {:ok, socket |> assign(highlighted_comments: highlighted_comments) |> assign(assigns)}
  end

  @impl true
  def handle_event("like-comment", %{"comment_id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)

    case Instagrain.Feed.like_comment(comment_id, socket.assigns.current_user.id) do
      {:ok, comment} ->
        comments =
          Enum.map(socket.assigns.post.comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        highlighted_comments =
          Enum.map(socket.assigns.highlighted_comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        {:noreply,
         assign(socket,
           post: %{socket.assigns.post | comments: comments},
           highlighted_comments: highlighted_comments
         )}

      _ ->
        notify_parent({:error, "Like failed"})
        {:noreply, socket}
    end
  end

  def handle_event("unlike-comment", %{"comment_id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)

    case Instagrain.Feed.unlike_comment(comment_id, socket.assigns.current_user.id) do
      {:ok, comment} ->
        comments =
          Enum.map(socket.assigns.post.comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        highlighted_comments =
          Enum.map(socket.assigns.highlighted_comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        {:noreply,
         assign(socket,
           post: %{socket.assigns.post | comments: comments},
           highlighted_comments: highlighted_comments
         )}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
