defmodule InstagrainWeb.PostLive.CommentComponent do
  use InstagrainWeb, :live_component

  alias Instagrain.Feed
  alias Instagrain.Repo

  attr :current_user, Instagrain.Accounts.User, required: true
  attr :post, Instagrain.Feed.Post, required: true
  attr :comment_input_id, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@comment_input_id}-container"}>
      <form
        :if={!@post.disable_comments}
        phx-target={@myself}
        phx-change="comment-edit"
        phx-submit="save-comment"
      >
        <div class="flex justify-between">
          <textarea
            id={@comment_input_id}
            name="comment"
            phx-hook="Resizable"
            class={[
              "block w-full p-0 border-0 outline-none outline-clear",
              "resize-none overflow-hidden placeholder:font-medium placeholder:text-neutral-500 text-black font-medium text-sm"
            ]}
            placeholder="Add a comment..."
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @comment) %></textarea>
          <div class="">
            <%= if String.length(@comment) > 0 do %>
              <button class="cursor-pointer font-bold text-sm text-sky-500 hover:text-sky-900">
                Post
              </button>
            <% end %>
          </div>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, comment: "", reply_to: nil)}
  end

  @impl true
  def handle_event("comment-edit", params, socket) do
    {:noreply, assign(socket, comment: params["comment"])}
  end

  def handle_event("save-comment", %{"comment" => comment}, socket) do
    case Feed.create_comment(%{
           comment: comment,
           post_id: socket.assigns.post.id,
           user_id: socket.assigns.current_user.id,
           reply_to_id: socket.assigns.reply_to
         }) do
      {:ok, comment} ->
        comment = Repo.preload(comment, [:user, :comment_likes])
        post = Map.update!(socket.assigns.post, :comments, &(&1 ++ [comment]))
        notify_parent({:post_updated, post})
        {:noreply, assign(socket, comment: "", reply_to: nil)}

      {:error, _error} ->
        notify_parent({:error, "Saving comment failed"})
        {:noreply, assign(socket, comment: "", reply_to: nil)}
    end
  end

  def handle_event("replyto", %{"username" => username, "comment_id" => comment_id}, socket) do
    {:noreply,
     socket
     |> assign(comment: "@#{username} ")
     |> assign(reply_to: comment_id)
     |> push_event("focus", %{id: socket.assigns.comment_input_id})}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
