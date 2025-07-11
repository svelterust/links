defmodule Links.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Links.Repo

  alias Links.Posts.Post
  alias Links.Posts.Comment
  alias Links.Posts.Vote
  alias Links.Accounts.User
  alias Req
  alias Floki
  require Floki

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Repo.all(from p in Post, order_by: [desc: p.inserted_at], preload: [:user])
  end

  @doc """
  Returns the list of posts ordered by points.

  ## Examples

      iex> list_posts_by_points()
      [%Post{}, ...]

  """
  def list_posts_by_points do
    Repo.all(from p in Post, order_by: [desc: p.points, desc: p.inserted_at], preload: [:user])
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
        offset: ^offset,
        preload: [:user]
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
  def get_post!(id), do: Repo.get!(Post, id) |> Repo.preload(:user)

  @doc """
  Gets a single post.

  ## Examples

      iex> get_post(123)
      %Post{}

      iex> get_post(456)
      nil

  """
  def get_post(id), do: Repo.get(Post, id) |> Repo.preload(:user)

  @doc """
  Gets a single post with comments preloaded.

  ## Examples

      iex> get_post_with_comments!(123)
      %Post{comments: [%Comment{}, ...]}

  """
  def get_post_with_comments!(id) do
    post = Repo.get!(Post, id) |> Repo.preload(:user)
    comments = list_comments_for_post(id)
    Map.put(post, :comments, comments)
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
    result =
      %Post{}
      |> Post.create_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, post} ->
        # Preload user for broadcasting
        post_with_user = get_post!(post.id)
        
        # Broadcast the new post to all subscribers
        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "posts",
          {:new_post, post_with_user}
        )

        {:ok, post_with_user}

      error ->
        error
    end
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
    result = Repo.delete(post)

    case result do
      {:ok, deleted_post} ->
        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "posts",
          {:post_deleted, deleted_post}
        )

        {:ok, deleted_post}

      error ->
        error
    end
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

  @doc """
  Votes on a post by a user. Only allows one vote per user per post.
  If user already voted, updates the vote. Returns updated post with new points.

  ## Examples

      iex> vote_on_post(user, post, "up")
      {:ok, %Post{}}

      iex> vote_on_post(user, post, "down")
      {:ok, %Post{}}

  """
  def vote_on_post(%User{} = user, %Post{} = post, vote_type) when vote_type in ["up", "down"] do
    existing_vote = get_user_vote_for_post(user.id, post.id)

    case handle_vote(existing_vote, user, post, vote_type) do
      {:ok, _vote_result} ->
        # Recalculate points based on votes
        new_points = calculate_post_points(post.id)
        update_post(post, %{points: new_points})

      error ->
        error
    end
  end

  @doc """
  Gets the current user's vote for a specific post.

  ## Examples

      iex> get_user_vote_for_post(user_id, post_id)
      %Vote{}

      iex> get_user_vote_for_post(user_id, post_id)
      nil

  """
  def get_user_vote_for_post(user_id, post_id) do
    Repo.get_by(Vote, user_id: user_id, post_id: post_id)
  end

  @doc """
  Gets all votes for a specific post with user information.

  ## Examples

      iex> get_post_votes(post_id)
      [%Vote{}, ...]

  """
  def get_post_votes(post_id) do
    Repo.all(from v in Vote, where: v.post_id == ^post_id, preload: [:user])
  end

  @doc """
  Calculates the total points for a post based on votes.

  ## Examples

      iex> calculate_post_points(post_id)
      5

  """
  def calculate_post_points(post_id) do
    from(v in Vote,
      where: v.post_id == ^post_id,
      select: %{
        upvotes: fragment("COUNT(CASE WHEN ? = 'up' THEN 1 END)", v.type),
        downvotes: fragment("COUNT(CASE WHEN ? = 'down' THEN 1 END)", v.type)
      }
    )
    |> Repo.one()
    |> case do
      %{upvotes: upvotes, downvotes: downvotes} -> upvotes - downvotes
      _ -> 0
    end
  end

  @doc """
  Gets user votes for multiple posts in batch for efficiency.

  ## Examples

      iex> get_user_votes_for_posts(user_id, [1, 2, 3])
      [%Vote{}, ...]

  """
  def get_user_votes_for_posts(user_id, post_ids) do
    Repo.all(from v in Vote, where: v.user_id == ^user_id and v.post_id in ^post_ids)
  end

  # Comments

  @doc """
  Returns the list of comments for a post organized hierarchically.

  ## Examples

      iex> list_comments_for_post(123)
      [%Comment{replies: [%Comment{}, ...]}, ...]

  """
  def list_comments_for_post(post_id) do
    # Get all comments for the post
    all_comments = Repo.all(
      from c in Comment,
        where: c.link_id == ^post_id,
        order_by: [asc: c.inserted_at]
    )

    # Build hierarchical structure
    build_comment_tree(all_comments)
  end

  @doc """
  Returns flat list of comments for a post (original behavior).

  ## Examples

      iex> list_comments_for_post_flat(123)
      [%Comment{}, ...]

  """
  def list_comments_for_post_flat(post_id) do
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

        # Broadcast the new comment to all subscribers
        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "comments:#{comment.link_id}",
          {:new_comment, comment}
        )

        # Also broadcast post update for comment count
        updated_post = get_post!(comment.link_id)

        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "posts",
          {:post_updated, updated_post}
        )

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

        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "comments:#{deleted_comment.link_id}",
          {:comment_deleted, deleted_comment}
        )

        updated_post = get_post!(deleted_comment.link_id)
        Phoenix.PubSub.broadcast(
          Links.PubSub,
          "posts",
          {:post_updated, updated_post}
        )

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

  @doc """
  Creates a post by fetching the title from the given URL.
  """
  def create_post_with_title(url, user_id) do
    case get_title_from_url(url) do
      {:ok, title} ->
        create_post(%{url: url, title: title, user_id: user_id})

      {:error, reason} ->
        changeset =
          %Post{}
          |> change_post(%{url: url, user_id: user_id})
          |> Ecto.Changeset.add_error(:url, "could not fetch title: #{reason}")
          |> Map.put(:action, :insert)

        {:error, changeset}
    end
  end

  defp get_title_from_url(url) do
    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        document = Floki.parse_document!(body)

        case Floki.find(document, "title") do
          [title_element | _] ->
            title = Floki.text(title_element) |> String.trim()
            {:ok, title}

          [] ->
            {:error, "no title element found"}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP status #{status}"}

      {:error, reason} ->
        {:error, "network error: #{inspect(reason)}"}
    end
  end

  # Private functions

  defp handle_vote(nil, user, post, vote_type) do
    # Create new vote
    %Vote{}
    |> Vote.changeset(%{user_id: user.id, post_id: post.id, type: vote_type})
    |> Repo.insert()
  end

  defp handle_vote(existing_vote, _user, _post, vote_type) when existing_vote.type == vote_type do
    # Same vote type - remove the vote (toggle off)
    Repo.delete(existing_vote)
  end

  defp handle_vote(existing_vote, _user, _post, vote_type) do
    # Different vote type - update the vote
    existing_vote
    |> Vote.changeset(%{type: vote_type})
    |> Repo.update()
  end

  defp update_post_comment_count(post_id) do
    count =
      Repo.aggregate(
        from(c in Comment, where: c.link_id == ^post_id),
        :count,
        :id
      )

    case get_post(post_id) do
      nil ->
        :ok

      post ->
        post
        |> Post.update_comment_count_changeset(count)
        |> Repo.update()
    end
  end

  defp build_comment_tree(comments) do
    # Create a map of all comments for quick lookup
    comment_map = Enum.into(comments, %{}, fn comment -> {comment.id, Map.put(comment, :replies, [])} end)
    
    # Group comments by parent_id to build relationships
    grouped_by_parent = Enum.group_by(comments, fn comment -> comment.parent_id end)
    
    # Build the tree by adding children to their parents
    updated_comment_map = Enum.reduce(grouped_by_parent, comment_map, fn {parent_id, children}, acc ->
      if parent_id do
        # These are child comments, add them to their parent
        case Map.get(acc, parent_id) do
          nil -> acc  # Parent doesn't exist, skip
          parent ->
            # Sort children by inserted_at to maintain chronological order
            sorted_children = Enum.sort_by(children, &(&1.inserted_at), DateTime)
            updated_parent = Map.put(parent, :replies, sorted_children)
            Map.put(acc, parent_id, updated_parent)
        end
      else
        # These are root comments, no parent to update
        acc
      end
    end)
    
    # Recursively build the full tree structure
    root_comments = Map.get(grouped_by_parent, nil, [])
    |> Enum.sort_by(&(&1.inserted_at), DateTime)
    |> Enum.map(fn root_comment ->
      build_nested_replies(root_comment, updated_comment_map)
    end)
    
    root_comments
  end
  
  defp build_nested_replies(comment, comment_map) do
    updated_comment = Map.get(comment_map, comment.id, comment)
    
    # Recursively build nested replies
    nested_replies = Enum.map(updated_comment.replies, fn reply ->
      build_nested_replies(reply, comment_map)
    end)
    
    Map.put(updated_comment, :replies, nested_replies)
  end
end
