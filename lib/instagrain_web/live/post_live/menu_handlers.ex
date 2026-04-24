defmodule InstagrainWeb.PostLive.MenuHandlers do
  @moduledoc """
  Shared `handle_event`/`handle_info` clauses for the post options menu
  (Delete / Edit / Hide likes / Disable comments) so every LiveView that
  renders a `.menu` — feed, post details, profile, explore — behaves the
  same without duplicating logic.

  Use via `use InstagrainWeb.PostLive.MenuHandlers`. The injected
  handlers rely on the LiveView having either a `:posts` stream (feed,
  profile, explore) or a single `:post` assign (details page), and an
  `:editing_post` assign which defaults to `nil`.
  """

  alias Instagrain.Feed

  defmacro __using__(_opts) do
    quote do
      def handle_event("menu-toggle-hide-likes", %{"id" => id}, socket) do
        InstagrainWeb.PostLive.MenuHandlers.toggle_field(socket, id, :hide_likes)
      end

      def handle_event("menu-toggle-comments", %{"id" => id}, socket) do
        InstagrainWeb.PostLive.MenuHandlers.toggle_field(socket, id, :disable_comments)
      end

      def handle_event("menu-edit", %{"id" => id}, socket) do
        InstagrainWeb.PostLive.MenuHandlers.open_edit(socket, id)
      end

      def handle_event("close-edit-modal", _, socket) do
        {:noreply, Phoenix.Component.assign(socket, editing_post: nil)}
      end

      def handle_event("confirm-delete-post", %{"id" => id}, socket) do
        InstagrainWeb.PostLive.MenuHandlers.delete(socket, id, __MODULE__)
      end

      def handle_info({InstagrainWeb.PostLive.EditFormComponent, :close}, socket) do
        {:noreply, Phoenix.Component.assign(socket, editing_post: nil)}
      end
    end
  end

  def toggle_field(socket, id, field) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    if post.user_id != socket.assigns.current_user.id do
      {:noreply, Phoenix.LiveView.put_flash(socket, :error, "You can only edit your own posts.")}
    else
      {:ok, _} = Feed.update_post(post, %{field => !Map.get(post, field)})
      fresh = Feed.get_post!(post.id, socket.assigns.current_user.id)
      {:noreply, refresh_post(socket, fresh)}
    end
  end

  def open_edit(socket, id) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    if post.user_id == socket.assigns.current_user.id do
      {:noreply, Phoenix.Component.assign(socket, editing_post: post)}
    else
      {:noreply, socket}
    end
  end

  def delete(socket, id, caller) do
    post = Feed.get_post!(id, socket.assigns.current_user.id)

    cond do
      post.user_id != socket.assigns.current_user.id ->
        {:noreply,
         Phoenix.LiveView.put_flash(socket, :error, "You can only delete your own posts.")}

      caller == InstagrainWeb.PostLive.Show ->
        {:ok, _} = Feed.delete_post(post)

        {:noreply,
         socket
         |> Phoenix.LiveView.put_flash(:info, "Post deleted.")
         |> Phoenix.LiveView.push_navigate(to: "/")}

      true ->
        {:ok, _} = Feed.delete_post(post)

        socket = Phoenix.LiveView.put_flash(socket, :info, "Post deleted.")

        if has_posts_stream?(socket) do
          {:noreply, Phoenix.LiveView.stream_delete(socket, :posts, post)}
        else
          {:noreply, socket}
        end
    end
  end

  defp refresh_post(socket, post) do
    cond do
      has_posts_stream?(socket) ->
        Phoenix.LiveView.stream_insert(socket, :posts, post)

      Map.has_key?(socket.assigns, :post) ->
        Phoenix.Component.assign(socket, post: post)

      true ->
        socket
    end
  end

  defp has_posts_stream?(socket) do
    case Map.get(socket.assigns, :streams) do
      %{posts: _} -> true
      _ -> false
    end
  end
end
