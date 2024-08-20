defmodule InstagrainWeb.UserComponents do
  @moduledoc """
  User components
  """
  use InstagrainWeb, :component
  alias Instagrain.Accounts.User

  attr :user, User, required: true
  attr :size, :atom, values: [:xs, :sm], default: :xs

  def avatar(assigns) do
    ~H"""
    <div class="rounded-full border">
      <.icon
        :if={is_nil(@user.avatar)}
        name="hero-user"
        class={[@size == :xs && "h-7 w-7", @size == :sm && "h-8 w-8"]}
      />
      <img
        :if={!is_nil(@user.avatar)}
        src={~p"/uploads/avatars/#{@user.avatar}"}
        class={[@size == :xs && "h-7 w-7", @size == :sm && "h-8 w-8", "object-cover rounded-full"]}
      />
    </div>
    """
  end

  attr :user, User, required: true
  attr :current_user, User, required: true
  attr :size, :atom, values: [:xs, :sm], default: :xs

  def user_post_header(assigns) do
    ~H"""
    <div class={[
      "flex px-4 items-center",
      @size == :xs && "pt-4.5 pb-3.5",
      @size == :sm && "pt-3.5 pb-2.5"
    ]}>
      <div class="pr-3">
        <.avatar user={@user} size={@size} />
      </div>
      <div>
        <span class="text-black font-bold text-sm">
          <%= @user.username %>
        </span>
      </div>
    </div>
    """
  end
end
