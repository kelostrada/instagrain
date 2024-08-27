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

  def menu(assigns) do
    ~H"""
    <div>
      <span phx-click={show_modal(@modal_id)}>
        <.icon name="hero-ellipsis-horizontal" class="h-7 w-7 cursor-pointer" />
      </span>

      <.modal id={@modal_id}>
        <div class="max-sm:w-80 sm:w-96 flex flex-col divide-y">
          <div class="flex items-center justify-center text-sm font-semibold p-3.5 cursor-pointer">
            Follow
          </div>
          <div
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
            phx-click={JS.patch(~p"/p/#{@post.id}")}
          >
            Go to post
          </div>
          <div
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer"
            phx-click={hide_modal(@modal_id)}
          >
            Cancel
          </div>
        </div>
      </.modal>
    </div>
    """
  end

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
