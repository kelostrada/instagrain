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
end
