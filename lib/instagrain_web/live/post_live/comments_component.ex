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
        <div :for={comment <- @comments} class="my-4">
          <.comment_component
            comment={comment}
            comment_input_id={@comment_input_id}
            myself={@myself}
            replies_shown={@replies_shown}
          />
        </div>
      <% end %>
    </div>
    """
  end

  def comment_component(assigns) do
    ~H"""
    <div class="flex gap-3">
      <div>
        <.avatar user={@comment.user} size={:sm} />
      </div>
      <div class="grow">
        <.username user={@comment.user} />
        <.time prefix="• " datetime={@comment.inserted_at} class="max-md:hidden" />
        <div>
          <.user_content text={@comment.comment} />
        </div>
      </div>
      <div class="flex items-center">
        <%= if @comment.liked_by_current_user? do %>
          <span phx-click="unlike-comment" phx-value-comment_id={@comment.id} phx-target={@myself}>
            <.icon
              name="hero-heart-solid"
              class="md:w-5 md:h-5 max-md:w-3 max-md:h-3 cursor-pointer hover:text-neutral-400 bg-red-500"
            />
          </span>
        <% else %>
          <span phx-click="like-comment" phx-value-comment_id={@comment.id} phx-target={@myself}>
            <.icon
              name="hero-heart"
              class="md:w-5 md:h-5 max-md:w-3 max-md:h-3 cursor-pointer hover:text-neutral-400"
            />
          </span>
        <% end %>
      </div>
    </div>
    <div class="pt-2 pl-11 flex gap-3">
      <.time datetime={@comment.inserted_at} class="md:hidden font-medium text-xs text-neutral-500" />
      <.comment_likes comment={@comment} class="font-extrabold text-xs text-neutral-500" />
      <.link
        class="text-xs font-bold text-neutral-500"
        phx-click="replyto"
        phx-value-username={@comment.user.username}
        phx-value-comment_id={@comment.reply_to_id || @comment.id}
        phx-target={"##{@comment_input_id}-container"}
      >
        Reply
      </.link>
    </div>
    <div :if={@comment.replies != [] && is_list(@comment.replies)} class="pt-2 pl-11">
      <.link
        :if={@comment.id not in @replies_shown}
        class="text-xs font-bold text-neutral-500"
        phx-click="display_replies"
        phx-target={@myself}
        phx-value-comment_id={@comment.id}
      >
        ---- View all <%= length(@comment.replies) %> replies
      </.link>
      <.link
        :if={@comment.id in @replies_shown}
        class="text-xs font-bold text-neutral-500"
        phx-click="hide_replies"
        phx-target={@myself}
        phx-value-comment_id={@comment.id}
      >
        ---- Hide all replies
      </.link>
      <%= if @comment.id in @replies_shown do %>
        <div :for={reply <- @comment.replies} class="my-4">
          <.comment_component
            comment={reply}
            comment_input_id={@comment_input_id}
            myself={@myself}
            replies_shown={@replies_shown}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, replies_shown: [])}
  end

  @impl true
  def update(assigns, socket) do
    grouped_comments = Enum.group_by(assigns.post.comments, & &1.reply_to_id)

    comments =
      grouped_comments
      |> Map.get(nil, [])
      |> Enum.map(fn comment ->
        %{comment | replies: Map.get(grouped_comments, comment.id, [])}
      end)

    {:ok, socket |> assign(assigns) |> assign(comments: comments)}
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

  def handle_event("display_replies", %{"comment_id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)
    {:noreply, assign(socket, replies_shown: [comment_id | socket.assigns.replies_shown])}
  end

  def handle_event("hide_replies", %{"comment_id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)
    {:noreply, assign(socket, replies_shown: socket.assigns.replies_shown -- [comment_id])}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
