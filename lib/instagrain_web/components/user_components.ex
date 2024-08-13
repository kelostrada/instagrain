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
end
