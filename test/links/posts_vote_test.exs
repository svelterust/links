defmodule Links.PostsVoteTest do
  use Links.DataCase

  alias Links.Posts
  alias Links.Accounts

  describe "voting" do
    setup do
      {:ok, user1} = Accounts.register_user(%{email: "user1@example.com"})
      {:ok, user2} = Accounts.register_user(%{email: "user2@example.com"})
      
      {:ok, post} = Posts.create_post(%{
        title: "Test Post",
        url: "https://example.com/test",
        author: "test_author"
      })

      %{user1: user1, user2: user2, post: post}
    end

    test "user can upvote a post", %{user1: user1, post: post} do
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "up")
      assert updated_post.points == 1
      
      # Check that vote was recorded
      vote = Posts.get_user_vote_for_post(user1.id, post.id)
      assert vote.type == "up"
    end

    test "user can downvote a post", %{user1: user1, post: post} do
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "down")
      assert updated_post.points == -1
      
      # Check that vote was recorded
      vote = Posts.get_user_vote_for_post(user1.id, post.id)
      assert vote.type == "down"
    end

    test "user can change their vote", %{user1: user1, post: post} do
      # First upvote
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "up")
      assert updated_post.points == 1
      
      # Then change to downvote
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "down")
      assert updated_post.points == -1
      
      # Check that vote was updated
      vote = Posts.get_user_vote_for_post(user1.id, post.id)
      assert vote.type == "down"
    end

    test "user can remove their vote by voting the same way twice", %{user1: user1, post: post} do
      # First upvote
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "up")
      assert updated_post.points == 1
      
      # Vote up again to remove vote
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "up")
      assert updated_post.points == 0
      
      # Check that vote was removed
      vote = Posts.get_user_vote_for_post(user1.id, post.id)
      assert vote == nil
    end

    test "multiple users can vote on the same post", %{user1: user1, user2: user2, post: post} do
      # User1 upvotes
      assert {:ok, updated_post} = Posts.vote_on_post(user1, post, "up")
      assert updated_post.points == 1
      
      # User2 upvotes
      assert {:ok, updated_post} = Posts.vote_on_post(user2, post, "up")
      assert updated_post.points == 2
      
      # User2 changes to downvote
      assert {:ok, updated_post} = Posts.vote_on_post(user2, post, "down")
      assert updated_post.points == 0
    end

    test "calculate_post_points correctly calculates points", %{user1: user1, user2: user2, post: post} do
      # Add some votes directly to database
      Posts.vote_on_post(user1, post, "up")
      Posts.vote_on_post(user2, post, "down")
      
      points = Posts.calculate_post_points(post.id)
      assert points == 0
    end

    test "get_user_votes_for_posts returns correct votes", %{user1: user1, post: post} do
      # Create another post
      {:ok, post2} = Posts.create_post(%{
        title: "Test Post 2",
        url: "https://example.com/test2",
        author: "test_author2"
      })

      # Vote on both posts
      Posts.vote_on_post(user1, post, "up")
      Posts.vote_on_post(user1, post2, "down")
      
      votes = Posts.get_user_votes_for_posts(user1.id, [post.id, post2.id])
      assert length(votes) == 2
      
      vote_types_by_post = votes |> Enum.into(%{}, fn vote -> {vote.post_id, vote.type} end)
      assert vote_types_by_post[post.id] == "up"
      assert vote_types_by_post[post2.id] == "down"
    end
  end
end