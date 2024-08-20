defmodule InstagrainWeb.PostComponents do
  @moduledoc """
  Post related components
  """
  use InstagrainWeb, :component
  alias Instagrain.Accounts.User
  alias Instagrain.Feed.Post

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
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer sm:hidden"
            phx-click={JS.patch(~p"/p/#{@post.id}")}
          >
            Go to post
          </div>
          <div
            class="flex items-center justify-center text-sm font-medium p-3.5 cursor-pointer max-sm:hidden"
            phx-click={hide_modal(@modal_id) |> show_modal("post-details-modal-#{@post.id}")}
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

  def caption(assigns) do
    ~H"""
    <span class="font-medium text-sm">
      <%= for part <- String.split(@post.caption || "", "\n") do %>
        <%= part %>
        <br />
      <% end %>
    </span>
    """
  end

  attr :datetime, DateTime, required: true

  def time(assigns) do
    ~H"""
    <time
      class="text-neutral-500 font-normal text-sm"
      datetime={@datetime}
      title={DateTime.to_date(@datetime)}
    >
      • <%= DateTime.utc_now() |> DateTime.diff(@datetime) |> format_seconds() %>
    </time>
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
end
