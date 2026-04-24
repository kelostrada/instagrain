defmodule InstagrainWeb.PostComponents do
  @moduledoc """
  Post related components
  """
  use InstagrainWeb, :component
  alias Instagrain.Accounts.User
  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Comment

  attr :modal_id, :string, required: true
  attr :post, Post, required: true
  attr :current_user, User, required: true
  attr :following_user_ids, :list, default: []
  attr :show_go_to_post, :boolean, default: true

  def menu(assigns) do
    assigns =
      assigns
      |> assign(:owner?, assigns.post.user.id == assigns.current_user.id)
      |> assign(:confirm_id, "post-delete-confirm-#{assigns.modal_id}")
      |> assign(:post_url, post_url(assigns.post))

    ~H"""
    <div>
      <span phx-click={show_modal(@modal_id)}>
        <.icon name="hero-ellipsis-horizontal" class="h-7 w-7 cursor-pointer" />
      </span>

      <.modal id={@modal_id}>
        <div class="max-sm:w-80 sm:w-96 flex flex-col divide-y">
          <%= if @owner? do %>
            <div
              class="flex items-center justify-center text-sm font-bold text-red-500 p-3.5 cursor-pointer"
              phx-click={hide_modal(@modal_id) |> show_modal(@confirm_id)}
            >
              Delete
            </div>
            <div
              class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
              phx-click={hide_modal(@modal_id) |> JS.push("menu-edit", value: %{id: @post.id})}
            >
              Edit
            </div>
            <div
              class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
              phx-click={hide_modal(@modal_id) |> JS.push("menu-toggle-hide-likes", value: %{id: @post.id})}
            >
              <%= if @post.hide_likes, do: "Unhide like count to others", else: "Hide like count to others" %>
            </div>
            <div
              class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
              phx-click={hide_modal(@modal_id) |> JS.push("menu-toggle-comments", value: %{id: @post.id})}
            >
              <%= if @post.disable_comments, do: "Turn on commenting", else: "Turn off commenting" %>
            </div>
          <% else %>
            <%= if @post.user.id in @following_user_ids do %>
              <div
                class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
                phx-click={JS.push("menu-unfollow", value: %{post_user_id: @post.user.id, post_id: @post.id})}
              >
                Unfollow
              </div>
            <% else %>
              <div
                class="flex items-center justify-center text-sm font-semibold p-3.5 cursor-pointer"
                phx-click={JS.push("menu-follow", value: %{post_user_id: @post.user.id, post_id: @post.id})}
              >
                Follow
              </div>
            <% end %>
          <% end %>
          <div
            :if={@show_go_to_post}
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
            phx-click={hide_modal(@modal_id) |> JS.patch(~p"/p/#{@post.id}")}
          >
            Go to post
          </div>
          <button
            type="button"
            id={"copy-link-#{@modal_id}"}
            phx-hook="CopyToClipboard"
            data-clipboard-text={@post_url}
            phx-click={hide_modal(@modal_id)}
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
          >
            Copy link
          </button>
          <div
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
            phx-click={hide_modal(@modal_id)}
          >
            Cancel
          </div>
        </div>
      </.modal>

      <.modal :if={@owner?} id={@confirm_id}>
        <div class="w-80 sm:w-96 text-center">
          <div class="px-8 pt-6 pb-4">
            <h2 class="text-xl font-medium">Delete post?</h2>
            <p class="text-sm text-neutral-500 mt-2">
              Are you sure you want to delete this post?
            </p>
          </div>
          <div class="divide-y">
            <div
              class="py-3.5 text-sm font-bold text-red-500 cursor-pointer"
              phx-click={hide_modal(@confirm_id) |> JS.push("confirm-delete-post", value: %{id: @post.id})}
            >
              Delete
            </div>
            <div
              class="py-3.5 text-sm font-medium cursor-pointer"
              phx-click={hide_modal(@confirm_id)}
            >
              Cancel
            </div>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  defp post_url(%Post{id: id}),
    do: "#{InstagrainWeb.Endpoint.url()}/p/#{id}"

  attr :post, Post, required: true
  attr :current_user, User, required: true

  def likes(assigns) do
    ~H"""
    <%= if !@post.hide_likes || @post.user.id == @current_user.id  do %>
      <div class="font-semibold	text-sm">
        <%= format_number(@post.likes) %> like<%= if @post.likes != 1, do: "s" %>
      </div>
    <% end %>
    """
  end

  attr :comment, Comment, required: true
  attr :class, :string, default: nil

  def comment_likes(assigns) do
    ~H"""
    <div :if={@comment.likes > 0} class={[!@class && "font-semibold text-sm", @class]}>
      <%= format_number(@comment.likes) %> like<%= if @comment.likes != 1, do: "s" %>
    </div>
    """
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
end
