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

      <div class="grid grid-cols-2 max-sm:px-3">
        <div class="flex gap-4 py-3">
          <%= if @post.liked_by_current_user? do %>
            <span phx-click="unlike" phx-target={@myself}>
              <.icon
                name="hero-heart-solid"
                class="w-7 h-7 cursor-pointer hover:text-neutral-400 bg-red-500"
              />
            </span>
          <% else %>
            <span phx-click="like" phx-target={@myself}>
              <.icon name="hero-heart" class="w-7 h-7 cursor-pointer hover:text-neutral-400" />
            </span>
          <% end %>

          <%= unless @post.disable_comments do %>
            <span phx-click={show_modal("post-details-modal-#{@post.id}")}>
              <.icon
                name="hero-chat-bubble-oval-left"
                class="w-7 h-7 -scale-x-100 cursor-pointer hover:text-neutral-400"
              />
            </span>
          <% end %>

          <.icon
            name="hero-paper-airplane"
            class="w-7 h-7 ml-1 rotate-[-27deg] translate-y-[-0.1875rem] cursor-pointer hover:text-neutral-400 "
          />
        </div>
        <div class="flex py-3 flex-row-reverse">
          <%= if @post.saved_by_current_user? do %>
            <span phx-click="remove-save" phx-target={@myself}>
              <.icon
                name="hero-bookmark-solid"
                class="w-7 h-7 cursor-pointer hover:text-neutral-400 bg-black"
              />
            </span>
          <% else %>
            <span phx-click="save" phx-target={@myself}>
              <.icon name="hero-bookmark" class="w-7 h-7 cursor-pointer hover:text-neutral-400" />
            </span>
          <% end %>
        </div>
      </div>

      <%= if !@post.hide_likes || @post.user.id == @current_user.id  do %>
        <div class="font-semibold	text-sm max-sm:px-3">
          <%= format_number(@post.likes) %> like<%= if @post.likes != 1, do: "s" %>
        </div>
      <% end %>

      <div class="my-1 text-sm max-sm:px-3">
        <span class="font-semibold">
          <%= @post.user.username %>
        </span>

        <%= if @show_more || !@post.caption || String.length(@post.caption) <= 125 do %>
          <span class="font-medium"><%= @post.caption %></span>
        <% else %>
          <span class="font-medium"><%= String.slice(@post.caption, 0, 125) %>...</span>
          <span class="text-neutral-500 cursor-pointer" phx-click="show-more" phx-target={@myself}>
            more
          </span>
        <% end %>
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

        <form
          id={"post-comment-form-#{@post.id}"}
          phx-target={@myself}
          phx-change="comment-edit"
          phx-submit="save-comment"
          class="max-sm:px-3"
        >
          <div class="flex justify-between">
            <textarea
              id={"comment-#{@post.id}"}
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
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, show_more: false, comment: "")}
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
  def handle_event("show-more", _, socket) do
    {:noreply, assign(socket, show_more: true)}
  end

  def handle_event("like", _, socket) do
    case Instagrain.Feed.like(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, post} ->
        {:noreply,
         assign(socket,
           post: %{
             socket.assigns.post
             | liked_by_current_user?: post.liked_by_current_user?,
               likes: post.likes
           }
         )}

      _ ->
        notify_parent({:error, "Like failed"})
        {:noreply, socket}
    end
  end

  def handle_event("unlike", _, socket) do
    case Instagrain.Feed.unlike(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, post} ->
        {:noreply,
         assign(socket,
           post: %{
             socket.assigns.post
             | liked_by_current_user?: post.liked_by_current_user?,
               likes: post.likes
           }
         )}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  def handle_event("save", _, socket) do
    case Instagrain.Feed.save_post(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply, assign(socket, post: %{socket.assigns.post | saved_by_current_user?: true})}

      _ ->
        notify_parent({:error, "Save failed"})
        {:noreply, socket}
    end
  end

  def handle_event("remove-save", _, socket) do
    case Instagrain.Feed.remove_save_post(socket.assigns.post.id, socket.assigns.current_user.id) do
      :ok ->
        {:noreply, assign(socket, post: %{socket.assigns.post | saved_by_current_user?: false})}

      _ ->
        notify_parent({:error, "Remove Save failed"})
        {:noreply, socket}
    end
  end

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
        {:noreply, assign(socket, comment: "", post: post)}

      {:error, _error} ->
        notify_parent({:error, "Saving comment failed"})
        {:noreply, assign(socket, comment: "")}
    end
  end

  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> insert_commas()
  end

  defp insert_commas(number_str) do
    number_str
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
