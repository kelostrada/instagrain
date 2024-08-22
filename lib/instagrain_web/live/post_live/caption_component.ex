defmodule InstagrainWeb.PostLive.CaptionComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents

  attr :current_user, Instagrain.Accounts.User, required: true
  attr :post, Instagrain.Feed.Post, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <span class="text-sm font-semibold">
        <%= @post.user.username %>
      </span>

      <%= if @show_more? || !@post.caption || (String.length(@post.caption) <= 125 && @post.caption |> String.split("\n") |> length() < 3) do %>
        <.caption text={@post.caption} />
      <% else %>
        <.caption text={(@post.caption |> String.split("\n") |> Enum.take(3) |> Enum.join("\n") |> String.slice(0, 125)) <> "..."} />
        <span
          class="text-sm text-neutral-500 cursor-pointer"
          phx-click="show-more"
          phx-target={@myself}
        >
          more
        </span>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, show_more?: false)}
  end

  @impl true
  def handle_event("show-more", _, socket) do
    {:noreply, assign(socket, show_more?: true)}
  end
end
