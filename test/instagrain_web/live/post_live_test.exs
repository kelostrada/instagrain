defmodule InstagrainWeb.PostLiveTest do
  use InstagrainWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Instagrain.FeedFixtures

  setup :register_and_log_in_user

  describe "Index" do
    test "renders the feed", %{conn: conn, user: user} do
      author = Instagrain.AccountsFixtures.user_fixture()
      Instagrain.Profiles.follow_user(user.id, author.id)
      post = post_fixture(%{user: author, caption: "Hello world"})

      {:ok, _live, html} = live(conn, ~p"/")

      assert html =~ post.caption
    end

    test "shows empty feed when no posts", %{conn: conn} do
      {:ok, _live, _html} = live(conn, ~p"/")
    end
  end

  describe "Show" do
    test "displays a post", %{conn: conn, user: user} do
      post = post_fixture(%{user: user, caption: "Test post"})

      {:ok, _live, html} = live(conn, ~p"/p/#{post.id}")

      assert html =~ "Test post"
    end
  end
end
