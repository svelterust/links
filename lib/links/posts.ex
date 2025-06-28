defmodule Links.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Links.Repo

  alias Links.Posts.Post
  alias Links.Posts.Comment

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Repo.all(from p in Post, order_by: [desc: p.inserted_at])
  end

  @doc """
  Returns the list of posts ordered by points.

  ## Examples

      iex> list_posts_by_points()
      [%Post{}, ...]

  """
  def list_posts_by_points do
    Repo.all(from p in Post, order_by: [desc: p.points, desc: p.inserted_at])
  end

  @doc """
  Returns the list of posts with pagination.

  ## Examples

      iex> list_posts_paginated(1, 20)
      [%Post{}, ...]

  """
  def list_posts_paginated(page \\ 1, per_page \\ 20) do
    offset = (page - 1) * per_page
    
    Repo.all(
      from p in Post,
      order_by: [desc: p.points, desc: p.inserted_at],
      limit: ^per_page,
      offset: ^offset
    )
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
  Gets a single post.

  ## Examples

      iex> get_post(123)
      %Post{}

      iex> get_post(456)
      nil

  """
  def get_post(id), do: Repo.get(Post, id)

  @doc """
  Gets a single post with comments preloaded.

  ## Examples

      iex> get_post_with_comments!(123)
      %Post{comments: [%Comment{}, ...]}

  """
  def get_post_with_comments!(id) do
    Repo.get!(Post, id)
    |> Repo.preload(comments: from(c in Comment, order_by: [asc: c.inserted_at]))
  end

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
    |> Post.create_changeset(attrs)
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
  Increments the points for a post.

  ## Examples

      iex> upvote_post(post)
      {:ok, %Post{}}

  """
  def upvote_post(%Post{} = post) do
    post
    |> Post.changeset(%{points: post.points + 1})
    |> Repo.update()
  end

  @doc """
  Decrements the points for a post.

  ## Examples

      iex> downvote_post(post)
      {:ok, %Post{}}

  """
  def downvote_post(%Post{} = post) do
    new_points = max(0, post.points - 1)
    
    post
    |> Post.changeset(%{points: new_points})
    |> Repo.update()
  end

  # Comments

  @doc """
  Returns the list of comments for a post.

  ## Examples

      iex> list_comments_for_post(123)
      [%Comment{}, ...]

  """
  def list_comments_for_post(post_id) do
    Repo.all(
      from c in Comment,
      where: c.link_id == ^post_id,
      order_by: [asc: c.inserted_at]
    )
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Gets a single comment.

  ## Examples

      iex> get_comment(123)
      %Comment{}

      iex> get_comment(456)
      nil

  """
  def get_comment(id), do: Repo.get(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    result = 
      %Comment{}
      |> Comment.create_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, comment} ->
        update_post_comment_count(comment.link_id)
        {:ok, comment}
      error ->
        error
    end
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    result = Repo.delete(comment)
    
    case result do
      {:ok, deleted_comment} ->
        update_post_comment_count(deleted_comment.link_id)
        {:ok, deleted_comment}
      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # Private functions

  defp update_post_comment_count(post_id) do
    count = Repo.aggregate(
      from(c in Comment, where: c.link_id == ^post_id),
      :count,
      :id
    )

    case get_post(post_id) do
      nil -> :ok
      post ->
        post
        |> Post.update_comment_count_changeset(count)
        |> Repo.update()
    end
  end
end