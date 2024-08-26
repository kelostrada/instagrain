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

  attr :text, :string, required: true

  def user_content(assigns) do
    # Split the text by lines
    parts = String.split(assigns.text || "", "\n")
    parts_length = length(parts)

    # Apply the replacement function to each part
    parts = Enum.map(parts, &replace_user_tags/1)

    assigns = assign(assigns, parts: parts, parts_length: parts_length)

    ~H"""
    <span class="font-medium text-sm">
      <%= for {part, i} <- Enum.with_index(@parts) do %>
        <%= for segment <- part do %>
          <%= segment %>
        <% end %>
        <br :if={i < @parts_length - 1} />
      <% end %>
    </span>
    """
  end

  # Function to replace user tags with safe HTML links
  defp replace_user_tags(text) do
    # Use a regex to find user tags (e.g., @username)
    Regex.split(~r/(?<!\S)@\w+(?:\.\w+)*/, text, include_captures: true, trim: true)
    |> Enum.map(&convert_to_safe_html/1)
  end

  # Function to convert user tags to safe HTML link or plain text
  defp convert_to_safe_html("@" <> username) do
    assigns = %{username: username}
    # Generate the HTML link structure safely
    ~H(<.link navigate={~p"/#{@username}"} class="text-sky-800">@<%= @username %></.link>)
  end

  defp convert_to_safe_html(text) do
    # Ensure other text is safe
    Phoenix.HTML.html_escape(text)
  end

  attr :datetime, DateTime, required: true
  attr :prefix, :string, default: ""
  attr :class, :string, default: ""

  def time(assigns) do
    ~H"""
    <time
      class={[@class == "" && "text-neutral-500 text-sm", @class]}
      datetime={@datetime}
      title={DateTime.to_date(@datetime)}
    >
      <%= @prefix %><%= DateTime.utc_now() |> DateTime.diff(@datetime) |> format_seconds() %>
    </time>
    """
  end

  attr :datetime, DateTime, required: true
  attr :class, :string, default: ""

  def time_ago(assigns) do
    ~H"""
    <time
      class={[@class == "" && "text-neutral-500 text-sm", @class]}
      datetime={@datetime}
      title={DateTime.to_date(@datetime)}
    >
      <%= DateTime.utc_now() |> DateTime.diff(@datetime) |> format_seconds_ago() %>
    </time>
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

  def format_seconds(seconds) when seconds < 60 do
    "#{seconds} s"
  end

  def format_seconds(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    "#{minutes} m"
  end

  def format_seconds(seconds) when seconds < 86_400 do
    hours = div(seconds, 3600)
    "#{hours} h"
  end

  def format_seconds(seconds) do
    days = div(seconds, 86_400)
    "#{days} d"
  end

  def format_seconds_ago(1) do
    "1 second ago"
  end

  def format_seconds_ago(seconds) when seconds < 60 do
    "#{seconds} seconds ago"
  end

  def format_seconds_ago(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    "#{minutes} minute#{if minutes > 1, do: "s"} ago"
  end

  def format_seconds_ago(seconds) when seconds < 86_400 do
    hours = div(seconds, 3600)
    "#{hours} hour#{if hours > 1, do: "s"} ago"
  end

  def format_seconds_ago(seconds) do
    days = div(seconds, 86_400)
    "#{days} day#{if days > 1, do: "s"} ago"
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
