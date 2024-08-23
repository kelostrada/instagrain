defmodule Instagrain.ProfilesTest do
  use Instagrain.DataCase

  alias Instagrain.Profiles

  describe "follows" do
    alias Instagrain.Profiles.Follow

    import Instagrain.ProfilesFixtures

    @invalid_attrs %{}

    test "list_follows/0 returns all follows" do
      follow = follow_fixture()
      assert Profiles.list_follows() == [follow]
    end

    test "get_follow!/1 returns the follow with given id" do
      follow = follow_fixture()
      assert Profiles.get_follow!(follow.id) == follow
    end

    test "create_follow/1 with valid data creates a follow" do
      valid_attrs = %{}

      assert {:ok, %Follow{} = follow} = Profiles.create_follow(valid_attrs)
    end

    test "create_follow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Profiles.create_follow(@invalid_attrs)
    end

    test "update_follow/2 with valid data updates the follow" do
      follow = follow_fixture()
      update_attrs = %{}

      assert {:ok, %Follow{} = follow} = Profiles.update_follow(follow, update_attrs)
    end

    test "update_follow/2 with invalid data returns error changeset" do
      follow = follow_fixture()
      assert {:error, %Ecto.Changeset{}} = Profiles.update_follow(follow, @invalid_attrs)
      assert follow == Profiles.get_follow!(follow.id)
    end

    test "delete_follow/1 deletes the follow" do
      follow = follow_fixture()
      assert {:ok, %Follow{}} = Profiles.delete_follow(follow)
      assert_raise Ecto.NoResultsError, fn -> Profiles.get_follow!(follow.id) end
    end

    test "change_follow/1 returns a follow changeset" do
      follow = follow_fixture()
      assert %Ecto.Changeset{} = Profiles.change_follow(follow)
    end
  end
end
