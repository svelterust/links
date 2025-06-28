defmodule Links.Fixtures do
  @moduledoc """
  This module defines test fixtures for generating test data.
  """

  alias Links.Posts

  @doc """
  Generate a post with valid attributes.
  """
  def post_fixture(attrs \\ %{}) do
    unique_url = "https://example#{System.unique_integer([:positive])}.com"
    
    default_attrs = %{
      title: "Test Post Title",
      url: unique_url,
      author: "test_author",
      tags: ["test", "fixture"]
    }

    attrs = Enum.into(attrs, default_attrs)
    
    {:ok, post} = Posts.create_post(attrs)
    post
  end

  @doc """
  Generate post attributes for testing.
  """
  def post_attrs(attrs \\ %{}) do
    unique_url = "https://example#{System.unique_integer([:positive])}.com"
    
    default_attrs = %{
      title: "Test Post Title",
      url: unique_url,
      author: "test_author",
      tags: ["test", "fixture"]
    }

    Enum.into(attrs, default_attrs)
  end

  @doc """
  Generate invalid post attributes for testing.
  """
  def invalid_post_attrs do
    %{
      title: "",
      url: "not-a-url",
      author: ""
    }
  end

  @doc """
  Generate a comment with valid attributes.
  """
  def comment_fixture(attrs \\ %{}) do
    # Create a post if link_id is not provided
    link_id = case Map.get(attrs, :link_id) do
      nil ->
        post = post_fixture()
        post.id
      id ->
        id
    end

    default_attrs = %{
      content: "This is a test comment content.",
      author: "comment_author",
      link_id: link_id
    }

    attrs = Enum.into(attrs, default_attrs)
    
    {:ok, comment} = Posts.create_comment(attrs)
    comment
  end

  @doc """
  Generate comment attributes for testing.
  """
  def comment_attrs(attrs \\ %{}) do
    # Create a post if link_id is not provided
    link_id = case Map.get(attrs, :link_id) do
      nil ->
        post = post_fixture()
        post.id
      id ->
        id
    end

    default_attrs = %{
      content: "This is a test comment content.",
      author: "comment_author",
      link_id: link_id
    }

    Enum.into(attrs, default_attrs)
  end

  @doc """
  Generate invalid comment attributes for testing.
  """
  def invalid_comment_attrs do
    %{
      content: "",
      author: "",
      link_id: nil
    }
  end

  @doc """
  Generate a post with comments.
  """
  def post_with_comments_fixture(comment_count \\ 3) do
    post = post_fixture()
    
    comments = for _ <- 1..comment_count do
      comment_fixture(%{link_id: post.id})
    end

    %{post | comments: comments}
  end
end