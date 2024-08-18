defmodule InstagrainWeb.UserComponents do
  @moduledoc """
  User components
  """
  use InstagrainWeb, :component
  alias Instagrain.Accounts.User

  attr :user, User, required: true

  def avatar(assigns) do
    ~H"""
    <div class="rounded-full border">
      <.icon :if={is_nil(@user.avatar)} name="hero-user" class="h-7 w-7" />
      <img
        :if={!is_nil(@user.avatar)}
        src={~p"/uploads/avatars/#{@user.avatar}"}
        class="w-7 h-7 object-cover rounded-full"
      />
    </div>
    """
  end

  attr :user, User, required: true
  attr :current_user, User, required: true

  def user_post_header(assigns) do
    ~H"""
    <div class="flex px-4 pt-4.5 pb-3.5 items-center">
      <div class="pr-3">
        <.avatar user={@user} />
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
