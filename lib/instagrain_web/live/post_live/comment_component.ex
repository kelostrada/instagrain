defmodule InstagrainWeb.PostLive.CommentComponent do
  use InstagrainWeb, :live_component

  alias Instagrain.Feed

  attr :current_user, Instagrain.Accounts.User, required: true
  attr :post, Instagrain.Feed.Post, required: true
  attr :comment_input_id, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-target={@myself} phx-change="comment-edit" phx-submit="save-comment">
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
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, comment: "")}
  end

  @impl true
  def handle_event("comment-edit", params, socket) do
    {:noreply, assign(socket, comment: params["comment"])}
  end

  def handle_event("save-comment", %{"comment" => comment}, socket) do
    case Feed.create_comment(%{
           comment: comment,
           post_id: socket.assigns.post.id,
           user_id: socket.assigns.current_user.id
         }) do
      {:ok, comment} ->
        post = Map.update!(socket.assigns.post, :comments, &(&1 ++ [comment]))
        notify_parent({:post_updated, post})
        {:noreply, assign(socket, comment: "")}

      {:error, _error} ->
        notify_parent({:error, "Saving comment failed"})
        {:noreply, assign(socket, comment: "")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
