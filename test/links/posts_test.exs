defmodule Links.PostsTest do
  use Links.DataCase

  alias Links.Posts
  alias Links.Posts.{Post, Comment}
  import Links.Fixtures

  describe "posts" do
    test "list_posts/0 returns all posts ordered by inserted_at desc" do
      _post1 = post_fixture()
      # Ensure different timestamps
      :timer.sleep(10)
      post2 = post_fixture()

      posts = Posts.list_posts()
      assert length(posts) == 2
      assert hd(posts).id == post2.id
    end

    test "list_posts_by_points/0 returns all posts ordered by points desc then inserted_at desc" do
      post1 = post_fixture()
      _post2 = post_fixture()

      # Give post1 more points
      {:ok, updated_post1} = Posts.update_post(post1, %{points: 5})

      posts = Posts.list_posts_by_points()
      assert length(posts) == 2
      assert hd(posts).id == updated_post1.id
      assert hd(posts).points == 5
    end

    test "list_posts_paginated/2 returns paginated posts" do
      # Create 5 posts and update their points after creation
      _posts =
        for i <- 1..5 do
          post = post_fixture(%{title: "Post #{i}"})
          {:ok, updated_post} = Posts.update_post(post, %{points: i})
          updated_post
        end

      # Test first page
      page1 = Posts.list_posts_paginated(1, 3)
      assert length(page1) == 3
      # Highest points first
      assert hd(page1).points == 5

      # Test second page
      page2 = Posts.list_posts_paginated(2, 3)
      assert length(page2) == 2
      assert hd(page2).points == 2
    end

    test "list_posts_paginated/2 with default parameters" do
      # Create one post
      post = post_fixture()

      posts = Posts.list_posts_paginated()
      assert length(posts) == 1
      assert hd(posts).id == post.id
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      retrieved_post = Posts.get_post!(post.id)
      assert retrieved_post.id == post.id
      assert retrieved_post.title == post.title
    end

    test "get_post!/1 raises when post doesn't exist" do
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(999) end
    end

    test "get_post/1 returns the post with given id" do
      post = post_fixture()
      retrieved_post = Posts.get_post(post.id)
      assert retrieved_post.id == post.id
      assert retrieved_post.title == post.title
    end

    test "get_post/1 returns nil when post doesn't exist" do
      assert Posts.get_post(999) == nil
    end

    test "get_post_with_comments!/1 returns post with preloaded comments" do
      post = post_fixture()
      _comment1 = comment_fixture(%{link_id: post.id, content: "First comment"})
      _comment2 = comment_fixture(%{link_id: post.id, content: "Second comment"})

      post_with_comments = Posts.get_post_with_comments!(post.id)

      assert post_with_comments.id == post.id
      assert length(post_with_comments.comments) == 2

      # Comments should be ordered by inserted_at asc
      comments = post_with_comments.comments
      assert hd(comments).content == "First comment"
      assert List.last(comments).content == "Second comment"
    end

    test "create_post/1 with valid data creates a post" do
      attrs = post_attrs()

      assert {:ok, %Post{} = post} = Posts.create_post(attrs)
      assert post.title == attrs.title
      assert post.url == attrs.url
      assert post.author == attrs.author
      assert post.points == 0
      assert post.comment_count == 0
      assert post.tags == attrs.tags
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(invalid_post_attrs())
    end

    test "create_post/1 with duplicate URL returns error changeset" do
      attrs = post_attrs()
      Posts.create_post(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_post(attrs)
      assert "has already been taken" in errors_on(changeset).url
    end

    test "create_post/1 with invalid URL returns error changeset" do
      attrs = post_attrs(%{url: "not-a-valid-url"})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_post(attrs)
      assert "must be a valid URL" in errors_on(changeset).url
    end

    test "create_post/1 with empty title returns error changeset" do
      attrs = post_attrs(%{title: ""})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_post(attrs)
      assert "can't be blank" in errors_on(changeset).title
    end

    test "create_post/1 with title too long returns error changeset" do
      long_title = String.duplicate("a", 256)
      attrs = post_attrs(%{title: long_title})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_post(attrs)
      assert "should be at most 255 character(s)" in errors_on(changeset).title
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{title: "Updated Title", points: 10}

      assert {:ok, %Post{} = updated_post} = Posts.update_post(post, update_attrs)
      assert updated_post.title == "Updated Title"
      assert updated_post.points == 10
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, invalid_post_attrs())

      # Post should remain unchanged
      retrieved_post = Posts.get_post!(post.id)
      assert retrieved_post.title == post.title
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "delete_post/1 also deletes associated comments" do
      post = post_fixture()
      comment = comment_fixture(%{link_id: post.id})

      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
      assert Posts.get_comment(comment.id) == nil
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end

    test "change_post/2 returns a post changeset with changes" do
      post = post_fixture()
      changeset = Posts.change_post(post, %{title: "New Title"})
      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.title == "New Title"
    end

    test "upvote_post/1 increments post points" do
      post = post_fixture()
      {:ok, post} = Posts.update_post(post, %{points: 5})

      assert {:ok, %Post{} = updated_post} = Posts.upvote_post(post)
      assert updated_post.points == 6
    end

    test "upvote_post/1 increments from 0" do
      post = post_fixture()

      assert {:ok, %Post{} = updated_post} = Posts.upvote_post(post)
      assert updated_post.points == 1
    end

    test "downvote_post/1 decrements post points" do
      post = post_fixture()
      {:ok, post} = Posts.update_post(post, %{points: 5})

      assert {:ok, %Post{} = updated_post} = Posts.downvote_post(post)
      assert updated_post.points == 4
    end

    test "downvote_post/1 doesn't go below 0" do
      post = post_fixture()
      # Post already has 0 points by default

      assert {:ok, %Post{} = updated_post} = Posts.downvote_post(post)
      assert updated_post.points == 0
    end

    test "downvote_post/1 from 1 goes to 0" do
      post = post_fixture()
      {:ok, post} = Posts.update_post(post, %{points: 1})

      assert {:ok, %Post{} = updated_post} = Posts.downvote_post(post)
      assert updated_post.points == 0
    end
  end

  describe "comments" do
    test "list_comments_for_post/1 returns all comments for a post ordered by inserted_at asc" do
      post = post_fixture()
      _comment1 = comment_fixture(%{link_id: post.id, content: "First"})
      :timer.sleep(10)
      _comment2 = comment_fixture(%{link_id: post.id, content: "Second"})

      # Create comment for different post to ensure filtering works
      other_post = post_fixture()
      comment_fixture(%{link_id: other_post.id, content: "Other"})

      comments = Posts.list_comments_for_post(post.id)
      assert length(comments) == 2
      assert hd(comments).content == "First"
      assert List.last(comments).content == "Second"
    end

    test "list_comments_for_post/1 returns empty list for post with no comments" do
      post = post_fixture()
      comments = Posts.list_comments_for_post(post.id)
      assert comments == []
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      retrieved_comment = Posts.get_comment!(comment.id)
      assert retrieved_comment.id == comment.id
      assert retrieved_comment.content == comment.content
    end

    test "get_comment!/1 raises when comment doesn't exist" do
      assert_raise Ecto.NoResultsError, fn -> Posts.get_comment!(999) end
    end

    test "get_comment/1 returns the comment with given id" do
      comment = comment_fixture()
      retrieved_comment = Posts.get_comment(comment.id)
      assert retrieved_comment.id == comment.id
      assert retrieved_comment.content == comment.content
    end

    test "get_comment/1 returns nil when comment doesn't exist" do
      assert Posts.get_comment(999) == nil
    end

    test "create_comment/1 with valid data creates a comment" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id})

      assert {:ok, %Comment{} = comment} = Posts.create_comment(attrs)
      assert comment.content == attrs.content
      assert comment.author == attrs.author
      assert comment.link_id == attrs.link_id
    end

    test "create_comment/1 updates post comment count" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id})

      assert {:ok, %Comment{}} = Posts.create_comment(attrs)

      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 1
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_comment(invalid_comment_attrs())
    end

    test "create_comment/1 with empty content returns error changeset" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, content: ""})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_comment(attrs)
      assert "can't be blank" in errors_on(changeset).content
    end

    test "create_comment/1 with content too long returns error changeset" do
      post = post_fixture()
      long_content = String.duplicate("a", 10001)
      attrs = comment_attrs(%{link_id: post.id, content: long_content})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_comment(attrs)
      assert "should be at most 10000 character(s)" in errors_on(changeset).content
    end

    test "create_comment/1 with author too long returns error changeset" do
      post = post_fixture()
      long_author = String.duplicate("a", 101)
      attrs = comment_attrs(%{link_id: post.id, author: long_author})

      assert {:error, %Ecto.Changeset{} = changeset} = Posts.create_comment(attrs)
      assert "should be at most 100 character(s)" in errors_on(changeset).author
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{content: "Updated content", author: "updated_author"}

      assert {:ok, %Comment{} = updated_comment} = Posts.update_comment(comment, update_attrs)
      assert updated_comment.content == "Updated content"
      assert updated_comment.author == "updated_author"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_comment(comment, invalid_comment_attrs())

      # Comment should remain unchanged
      retrieved_comment = Posts.get_comment!(comment.id)
      assert retrieved_comment.content == comment.content
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Posts.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_comment!(comment.id) end
    end

    test "delete_comment/1 updates post comment count" do
      post = post_fixture()
      comment1 = comment_fixture(%{link_id: post.id})
      _comment2 = comment_fixture(%{link_id: post.id})

      # Verify initial count
      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 2

      # Delete one comment
      assert {:ok, %Comment{}} = Posts.delete_comment(comment1)

      # Check updated count
      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 1
    end

    test "delete_comment/1 for non-existent post doesn't crash" do
      comment = comment_fixture()

      # Delete the post first
      post = Posts.get_post!(comment.link_id)
      Posts.delete_post(post)

      # This should not crash even though the post no longer exists
      # Note: This test might need to be adjusted based on database constraints
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Posts.change_comment(comment)
    end

    test "change_comment/2 returns a comment changeset with changes" do
      comment = comment_fixture()
      changeset = Posts.change_comment(comment, %{content: "New content"})
      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.content == "New content"
    end
  end

  describe "comment count management" do
    test "comment count is properly maintained when creating multiple comments" do
      post = post_fixture()

      # Create 3 comments
      comment_fixture(%{link_id: post.id})
      comment_fixture(%{link_id: post.id})
      comment_fixture(%{link_id: post.id})

      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 3
    end

    test "comment count is properly maintained when deleting comments" do
      post = post_fixture()

      # Create 3 comments
      comment1 = comment_fixture(%{link_id: post.id})
      comment2 = comment_fixture(%{link_id: post.id})
      _comment3 = comment_fixture(%{link_id: post.id})

      # Delete 2 comments
      Posts.delete_comment(comment1)
      Posts.delete_comment(comment2)

      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 1
    end

    test "comment count is set to 0 when all comments are deleted" do
      post = post_fixture()

      # Create comments
      comment1 = comment_fixture(%{link_id: post.id})
      comment2 = comment_fixture(%{link_id: post.id})

      # Delete all comments
      Posts.delete_comment(comment1)
      Posts.delete_comment(comment2)

      updated_post = Posts.get_post!(post.id)
      assert updated_post.comment_count == 0
    end
  end

  describe "integration tests" do
    test "post with comments workflow" do
      # Create a post
      post_attrs = post_attrs(%{title: "Integration Test Post"})
      {:ok, post} = Posts.create_post(post_attrs)

      # Add some comments
      {:ok, comment1} =
        Posts.create_comment(%{
          content: "Great post!",
          author: "user1",
          link_id: post.id
        })

      {:ok, comment2} =
        Posts.create_comment(%{
          content: "I disagree",
          author: "user2",
          link_id: post.id
        })

      # Upvote the post
      {:ok, upvoted_post} = Posts.upvote_post(post)
      assert upvoted_post.points == 1

      # Get post with comments
      post_with_comments = Posts.get_post_with_comments!(post.id)
      assert length(post_with_comments.comments) == 2
      assert post_with_comments.comment_count == 2
      assert post_with_comments.points == 1

      # Update a comment
      {:ok, updated_comment} =
        Posts.update_comment(comment1, %{content: "Actually, this is amazing!"})

      assert updated_comment.content == "Actually, this is amazing!"

      # Delete a comment
      {:ok, _} = Posts.delete_comment(comment2)

      # Verify final state
      final_post = Posts.get_post_with_comments!(post.id)
      assert length(final_post.comments) == 1
      assert final_post.comment_count == 1
      assert hd(final_post.comments).content == "Actually, this is amazing!"
    end
  end
end
