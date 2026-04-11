defmodule Instagrain.ProfilesTest do
  use Instagrain.DataCase

  alias Instagrain.Profiles

  import Instagrain.AccountsFixtures

  describe "follow_user/2" do
    test "creates a follow relationship" do
      user = user_fixture()
      target = user_fixture()

      assert {:ok, follow} = Profiles.follow_user(user.id, target.id)
      assert follow.user_id == user.id
      assert follow.follow_id == target.id
    end

    test "fails for duplicate follows" do
      user = user_fixture()
      target = user_fixture()

      assert {:ok, _} = Profiles.follow_user(user.id, target.id)
      assert {:error, _} = Profiles.follow_user(user.id, target.id)
    end
  end

  describe "unfollow_user/2" do
    test "removes a follow relationship" do
      user = user_fixture()
      target = user_fixture()

      {:ok, _} = Profiles.follow_user(user.id, target.id)
      assert :ok = Profiles.unfollow_user(user.id, target.id)
    end

    test "returns error when not following" do
      user = user_fixture()
      target = user_fixture()

      assert {:error, :not_found} = Profiles.unfollow_user(user.id, target.id)
    end
  end

  describe "get_profile/1" do
    test "returns user profile by username" do
      user = user_fixture()
      profile = Profiles.get_profile(user.username)

      assert profile.id == user.id
      assert profile.username == user.username
    end

    test "returns nil for nonexistent username" do
      assert is_nil(Profiles.get_profile("nonexistent"))
    end
  end
end
