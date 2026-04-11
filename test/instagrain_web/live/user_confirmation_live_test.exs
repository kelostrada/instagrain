defmodule InstagrainWeb.UserConfirmationLiveTest do
  use InstagrainWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Instagrain.AccountsFixtures

  alias Instagrain.Accounts
  alias Instagrain.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      lv
      |> form("#confirmation_form")
      |> render_submit()

      assert Accounts.get_user!(user.id).confirmed_at
      assert Repo.all(Accounts.UserToken) == []
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm/invalid-token")

      lv
      |> form("#confirmation_form")
      |> render_submit()

      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
