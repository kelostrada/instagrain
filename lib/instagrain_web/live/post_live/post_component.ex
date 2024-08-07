defmodule InstagrainWeb.PostLive.PostComponent do
  use InstagrainWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"post-#{@post.id}"} class="w-full">
      <div class="flex items-center justify-between px-1 pb-3">
        <div class="flex items-center gap-2">
          <div class="rounded-full border">
            <.icon name="hero-user" class="h-7 w-7" />
          </div>

          <div>
            <span class="text-black font-bold text-sm">
              <%= @post.user.email |> String.split("@") |> List.first() %>
            </span>

            <time
              class="text-neutral-500 font-normal text-sm"
              datetime={@post.inserted_at}
              title={DateTime.to_date(@post.inserted_at)}
            >
              • <%= DateTime.utc_now() |> DateTime.diff(@post.inserted_at) |> format_seconds() %>
            </time>
          </div>
        </div>
        <div>
          <.icon name="hero-ellipsis-horizontal" class="h-7 w-7" />
        </div>
      </div>

      <img src={~p"/uploads/#{@post.image}"} class="w-full" />

      <div class="grid grid-cols-2 px-3">
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
          <.icon
            name="hero-chat-bubble-oval-left"
            class="w-7 h-7 -scale-x-100 cursor-pointer hover:text-neutral-400"
          />
          <.icon
            name="hero-paper-airplane"
            class="w-7 h-7 ml-1 rotate-[-27deg] translate-y-[-0.1875rem] cursor-pointer hover:text-neutral-400 "
          />
        </div>
        <div class="flex py-3 flex-row-reverse">
          <.icon name="hero-bookmark" class="w-7 h-7 cursor-pointer hover:text-neutral-400" />
        </div>
      </div>

      <div class="font-semibold	text-sm px-3">
        <%= format_number(@post.likes) %> like<%= if @post.likes != 1, do: "s" %>
      </div>

      <div class="my-1 text-sm px-3">
        <span class="font-semibold">
          <%= @post.user.email |> String.split("@") |> List.first() %>
        </span>

        <%= if @show_more || !@post.caption || String.length(@post.caption) <= 125 do %>
          <span><%= @post.caption %></span>
        <% else %>
          <span><%= String.slice(@post.caption, 0, 125) %>...</span>
          <span class="text-neutral-500 cursor-pointer" phx-click="show-more" phx-target={@myself}>
            more
          </span>
        <% end %>
      </div>
      <form
        id={"post-comment-form-#{@post.id}"}
        phx-target={@myself}
        phx-change="comment-edit"
        phx-submit="save-comment"
        class="px-3"
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
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, show_more: false, comment: "")}
  end

  @impl true
  def handle_event("show-more", _, socket) do
    {:noreply, assign(socket, show_more: true)}
  end

  def handle_event("like", _, socket) do
    case Instagrain.Feed.like(socket.assigns.post, socket.assigns.user.id) do
      {:ok, post} ->
        {:noreply, assign(socket, post: post)}

      _ ->
        notify_parent({:error, "Like failed"})
        {:noreply, socket}
    end
  end

  def handle_event("unlike", _, socket) do
    case Instagrain.Feed.unlike(socket.assigns.post, socket.assigns.user.id) do
      {:ok, post} ->
        {:noreply, assign(socket, post: post)}

      _ ->
        notify_parent({:error, "Unlike failed"})
        {:noreply, socket}
    end
  end

  def handle_event("comment-edit", params, socket) do
    {:noreply, assign(socket, comment: params["comment"])}
  end

  def handle_event("save-comment", %{"comment" => comment}, socket) do
    # TODO: handle saving comments
    IO.inspect(comment)

    {:noreply, socket}
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
