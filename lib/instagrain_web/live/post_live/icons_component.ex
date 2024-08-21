defmodule InstagrainWeb.PostLive.IconsComponent do
  use InstagrainWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2">
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
          <span phx-click={
            show_modal("post-details-modal-#{@post.id}")
            |> JS.focus(to: "##{@comment_input_id}")
          }>
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
    """
  end

  @impl true
  def handle_event("like", _, socket) do
    case Instagrain.Feed.like(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, post} ->
        post = %{
          socket.assigns.post
          | liked_by_current_user?: post.liked_by_current_user?,
            likes: post.likes
        }

        notify_parent({:post_updated, post})
        {:noreply, socket}

      _ ->
        notify_parent({:error, "Like failed"})
        {:noreply, socket}
    end
  end

  def handle_event("unlike", _, socket) do
    case Instagrain.Feed.unlike(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, post} ->
        post = %{
          socket.assigns.post
          | liked_by_current_user?: post.liked_by_current_user?,
            likes: post.likes
        }

        notify_parent({:post_updated, post})
        {:noreply, socket}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  def handle_event("save", _, socket) do
    case Instagrain.Feed.save_post(socket.assigns.post.id, socket.assigns.current_user.id) do
      {:ok, _} ->
        post = %{socket.assigns.post | saved_by_current_user?: true}
        notify_parent({:post_updated, post})
        {:noreply, socket}

      _ ->
        notify_parent({:error, "Save failed"})
        {:noreply, socket}
    end
  end

  def handle_event("remove-save", _, socket) do
    case Instagrain.Feed.remove_save_post(socket.assigns.post.id, socket.assigns.current_user.id) do
      :ok ->
        post = %{socket.assigns.post | saved_by_current_user?: false}
        notify_parent({:post_updated, post})
        {:noreply, socket}

      _ ->
        notify_parent({:error, "Remove Save failed"})
        {:noreply, socket}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
