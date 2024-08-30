defmodule InstagrainWeb.UserComponents do
  @moduledoc """
  User components
  """
  use InstagrainWeb, :component
  alias Instagrain.Accounts.User

  attr :user, User, required: true
  attr :class, :string, default: nil

  def username(assigns) do
    ~H"""
    <.link navigate={~p"/#{@user.username}"}>
      <span class={[!@class && "text-black font-bold text-sm", @class]}>
        <%= @user.username %>
      </span>
    </.link>
    """
  end

  attr :user, User, required: true
  attr :size, :atom, values: [:xxs, :xs, :sm, :md, :lg], default: :xs
  attr :class, :string, default: nil

  def avatar(assigns) do
    ~H"""
    <div class={["rounded-full border", @class]}>
      <img
        src={
          if is_nil(@user.avatar),
            do: ~p"/images/person.webp",
            else: ~p"/uploads/avatars/#{@user.avatar}"
        }
        class={[
          @size == :xxs && "h-5 w-5",
          @size == :xs && "h-7 w-7",
          @size == :sm && "h-8 w-8",
          @size == :md && "h-10 w-10",
          @size == :lg && "h-14 w-14",
          "object-cover rounded-full"
        ]}
      />
    </div>
    """
  end

  attr :user, User, required: true
  attr :current_user, User, required: true
  attr :size, :atom, values: [:xs, :sm], default: :xs

  def user_post_header(assigns) do
    ~H"""
    <div class={["flex px-4 items-center"]}>
      <div class="pr-3">
        <.avatar user={@user} size={@size} />
      </div>
      <div>
        <.username user={@user} />
      </div>
    </div>
    """
  end
end
