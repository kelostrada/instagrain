defmodule InstagrainWeb.PostLive.HighlightedCommentsComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.UserComponents

  attr :current_user, Instagrain.Accounts.User, required: true
  attr :post, Instagrain.Feed.Post, required: true

  @impl true
  def render(assigns) do
    comments_length = length(assigns.post.comments)
    assigns = assign(assigns, comments_length: comments_length)

    ~H"""
    <div>
      <%= unless @post.disable_comments do %>
        <%= if @comments_length > 0 do %>
          <div class="my-1 text-sm">
            <.link
              class="max-md:hidden text-neutral-500 text-sm font-medium"
              phx-click={show_modal("post-details-modal-#{@post.id}")}
            >
              <%= if @comments_length == 1 do %>
                View 1 comment
              <% else %>
                View all <%= @comments_length %> comments
              <% end %>
            </.link>

            <.link
              class="md:hidden text-neutral-500 text-sm font-medium"
              navigate={~p"/p/#{@post.id}/comments"}
            >
              <%= if @comments_length == 1 do %>
                View 1 comment
              <% else %>
                View all <%= @comments_length %> comments
              <% end %>
            </.link>
          </div>
        <% end %>

        <div :for={comment <- @highlighted_comments} class="my-1 text-sm flex gap-2">
          <div class="grow">
            <.username user={comment.user} />
            <.user_content text={comment.comment} />
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
      <% end %>
    </div>
    """
  end

  defp get_highlighted_comments(comments) do
    amount =
      case length(comments) do
        len when len < 3 -> 0
        len when len < 5 -> 1
        len when len < 10 -> 2
        _ -> 3
      end

    comments
    |> Enum.sort_by(& &1.likes, :desc)
    |> Enum.take(amount)
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:highlighted_comments, fn ->
       get_highlighted_comments(assigns.post.comments)
     end)}
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

        highlighted_comments =
          Enum.map(socket.assigns.highlighted_comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        {:noreply, assign(socket, highlighted_comments: highlighted_comments)}

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

        highlighted_comments =
          Enum.map(socket.assigns.highlighted_comments, fn
            %{id: ^comment_id} = c ->
              %{c | likes: comment.likes, liked_by_current_user?: comment.liked_by_current_user?}

            c ->
              c
          end)

        {:noreply, assign(socket, highlighted_comments: highlighted_comments)}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
