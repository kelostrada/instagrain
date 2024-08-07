defmodule Instagrain.Feed do
  @moduledoc """
  The Feed context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Instagrain.Repo

  alias Instagrain.Feed.Post
  alias Instagrain.Feed.Post.Like
  alias Instagrain.Feed.Post.Resource

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(current_user_id) do
    from(p in Post,
      left_join: l in Like,
      on: l.post_id == p.id and l.user_id == ^current_user_id,
      order_by: {:desc, p.inserted_at},
      select: %{p | liked_by_current_user?: not is_nil(l.post_id)}
    )
    |> Repo.all()
    |> Repo.preload([:user, :resources])
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Returns the list of post_resources.

  ## Examples

      iex> list_post_resources()
      [%Resource{}, ...]

  """
  def list_post_resources do
    Repo.all(Resource)
  end

  @doc """
  Gets a single resource.

  Raises `Ecto.NoResultsError` if the Resource does not exist.

  ## Examples

      iex> get_resource!(123)
      %Resource{}

      iex> get_resource!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource!(id), do: Repo.get!(Resource, id)

  @doc """
  Creates a resource.

  ## Examples

      iex> create_resource(%{field: value})
      {:ok, %Resource{}}

      iex> create_resource(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource.

  ## Examples

      iex> update_resource(resource, %{field: new_value})
      {:ok, %Resource{}}

      iex> update_resource(resource, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource.

  ## Examples

      iex> delete_resource(resource)
      {:ok, %Resource{}}

      iex> delete_resource(resource)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.

  ## Examples

      iex> change_resource(resource)
      %Ecto.Changeset{data: %Resource{}}

  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  @doc """
  Creates a like, updates post.
  """
  def like(%Post{} = post, user_id) do
    Multi.new()
    |> Multi.insert(:like, Like.changeset(%Like{}, %{post_id: post.id, user_id: user_id}))
    |> Multi.update(:post, Post.changeset(post, %{likes: post.likes + 1}))
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} ->
        {:ok, %{post | liked_by_current_user?: true}}

      error ->
        error
    end
  end

  def unlike(%Post{id: post_id} = post, user_id) do
    Multi.new()
    |> Multi.delete_all(
      :delete_like,
      from(l in Like, where: l.post_id == ^post_id and l.user_id == ^user_id)
    )
    |> Multi.update(:post, fn %{delete_like: {deleted, _}} ->
      if deleted == 1 do
        Post.changeset(post, %{likes: post.likes - 1})
      else
        Post.changeset(post, %{})
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{post: post}} ->
        {:ok, %{post | liked_by_current_user?: false}}

      error ->
        error
    end
  end

  @doc """
  Deletes a like.

  ## Examples

      iex> delete_like(like)
      {:ok, %Like{}}

      iex> delete_like(like)
      {:error, %Ecto.Changeset{}}

  """
  def delete_like(%Like{} = like) do
    Repo.delete(like)
  end
end
