defmodule InstagrainWeb.PostLive.CommentsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  attr :current_user, Instagrain.Accounts.User, required: true
  attr :post, Instagrain.Feed.Post, required: true
  attr :comment_input_id, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <%= unless @post.disable_comments do %>
        <div :for={comment <- @post.comments} class="my-4">
          <div class="flex gap-3">
            <div>
              <.avatar user={comment.user} size={:sm} />
            </div>
            <div class="grow">
              <span class="font-bold">
                <%= comment.user.username %>
              </span>
              <.time datetime={comment.inserted_at} />
              <div>
                <.user_content text={comment.comment} />
              </div>
            </div>
            <div class="flex items-center">
              <%= if comment.liked_by_current_user? do %>
                <span
                  phx-click="unlike-comment"
                  phx-value-comment_id={comment.id}
                  phx-target={@myself}
                >
                  <.icon
                    name="hero-heart-solid"
                    class="w-5 h-5 cursor-pointer hover:text-neutral-400 bg-red-500"
                  />
                </span>
              <% else %>
                <span phx-click="like-comment" phx-value-comment_id={comment.id} phx-target={@myself}>
                  <.icon name="hero-heart" class="w-5 h-5 cursor-pointer hover:text-neutral-400" />
                </span>
              <% end %>
            </div>
          </div>
          <div class="pt-2 px-11 flex gap-3">
            <.comment_likes comment={comment} class="font-extrabold text-xs text-neutral-500" />
            <.link
              class="text-xs font-bold text-neutral-500"
              phx-click="replyto"
              phx-value-username={comment.user.username}
              phx-value-comment_id={comment.id}
              phx-target={"##{@comment_input_id}-container"}
            >
              Reply
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
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

        post = %{socket.assigns.post | comments: comments}
        notify_parent({:post_updated, post})
        {:noreply, socket}

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

        post = %{socket.assigns.post | comments: comments}
        notify_parent({:post_updated, post})
        {:noreply, socket}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
