defmodule Links.Posts.PostTest do
  use Links.DataCase

  alias Links.Posts.Post
  import Links.Fixtures

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = post_attrs()
      changeset = Post.changeset(%Post{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.title == attrs.title
      assert changeset.changes.url == attrs.url
      assert changeset.changes.author == attrs.author
    end

    test "invalid changeset with missing required fields" do
      changeset = Post.changeset(%Post{}, %{})
      
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).url
      assert "can't be blank" in errors_on(changeset).author
    end

    test "invalid changeset with empty title" do
      attrs = post_attrs(%{title: ""})
      changeset = Post.changeset(%Post{}, attrs)
      
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "invalid changeset with title too long" do
      long_title = String.duplicate("a", 256)
      attrs = post_attrs(%{title: long_title})
      changeset = Post.changeset(%Post{}, attrs)
      
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).title
    end

    test "valid changeset with title at max length" do
      max_title = String.duplicate("a", 255)
      attrs = post_attrs(%{title: max_title})
      changeset = Post.changeset(%Post{}, attrs)
      
      assert changeset.valid?
    end

    test "invalid changeset with invalid URL" do
      invalid_urls = [
        "not-a-url",
        "ftp://example.com",
        "example.com"
      ]

      for invalid_url <- invalid_urls do
        attrs = post_attrs(%{url: invalid_url})
        changeset = Post.changeset(%Post{}, attrs)
        
        refute changeset.valid?, "Expected #{invalid_url} to be invalid"
        assert "must be a valid URL" in errors_on(changeset).url
      end
    end

    test "valid changeset with valid URLs" do
      valid_urls = [
        "http://example.com",
        "https://example.com",
        "http://sub.example.com",
        "https://example.com/path",
        "https://example.com/path?param=value",
        "https://example.com:8080/path"
      ]

      for valid_url <- valid_urls do
        attrs = post_attrs(%{url: valid_url})
        changeset = Post.changeset(%Post{}, attrs)
        
        assert changeset.valid?, "Expected #{valid_url} to be valid"
      end
    end

    test "valid changeset allows optional fields" do
      attrs = post_attrs(%{
        points: 10,
        comment_count: 5,
        tags: ["elixir", "phoenix"]
      })
      changeset = Post.changeset(%Post{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.points == 10
      assert changeset.changes.comment_count == 5
      assert changeset.changes.tags == ["elixir", "phoenix"]
    end



    test "valid changeset with nil tags sets empty array as default" do
      attrs = %{title: "Test", url: "https://example.com", author: "test"}
      changeset = Post.changeset(%Post{}, attrs)
      
      # tags field should not be in changes when not provided
      # and the default value should be used
      refute Map.has_key?(changeset.changes, :tags)
    end
  end

  describe "create_changeset/2" do
    test "valid create changeset sets default values" do
      attrs = %{title: "Test", url: "https://example.com", author: "test"}
      changeset = Post.create_changeset(%Post{}, attrs)
      
      assert changeset.valid?
      {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)
      assert data.points == 0
      assert data.comment_count == 0
    end

    test "create changeset ignores points and comment_count in attrs" do
      attrs = %{title: "Test", url: "https://example.com", author: "test", points: 100, comment_count: 50}
      changeset = Post.create_changeset(%Post{}, attrs)
      
      assert changeset.valid?
      {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)
      assert data.points == 0
      assert data.comment_count == 0
    end

    test "create changeset with all validations" do
      attrs = post_attrs(%{
        title: "Test Post",
        url: "https://example.com",
        author: "test_author",
        tags: ["test"]
      })
      changeset = Post.create_changeset(%Post{}, attrs)
      
      assert changeset.valid?
      assert changeset.changes.title == "Test Post"
      assert changeset.changes.url == "https://example.com"
      assert changeset.changes.author == "test_author"
      assert changeset.changes.tags == ["test"]
      {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)
      assert data.points == 0
      assert data.comment_count == 0
    end

    test "invalid create changeset with missing required fields" do
      changeset = Post.create_changeset(%Post{}, %{})
      
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).url
      assert "can't be blank" in errors_on(changeset).author
    end
  end

  describe "update_comment_count_changeset/2" do
    test "updates comment count" do
      post = %Post{comment_count: 5}
      changeset = Post.update_comment_count_changeset(post, 10)
      
      assert changeset.valid?
      assert changeset.changes.comment_count == 10
    end

    test "updates comment count to zero" do
      post = %Post{comment_count: 5}
      changeset = Post.update_comment_count_changeset(post, 0)
      
      assert changeset.valid?
      assert changeset.changes.comment_count == 0
    end

    test "only changes comment_count field" do
      post = %Post{
        title: "Original Title",
        url: "https://original.com",
        author: "original_author",
        points: 10,
        comment_count: 5
      }
      
      changeset = Post.update_comment_count_changeset(post, 3)
      
      assert changeset.valid?
      assert Map.keys(changeset.changes) == [:comment_count]
      assert changeset.changes.comment_count == 3
    end
  end

  describe "schema defaults" do
    test "post has correct default values" do
      post = %Post{}
      
      assert post.points == 0
      assert post.comment_count == 0
      assert post.tags == []
    end
  end

  describe "associations" do
    test "post has many comments association" do
      post = post_fixture()
      comment1 = comment_fixture(%{link_id: post.id})
      comment2 = comment_fixture(%{link_id: post.id})
      
      post_with_comments = Links.Repo.get!(Post, post.id)
        |> Links.Repo.preload(:comments)
      
      assert length(post_with_comments.comments) == 2
      comment_ids = Enum.map(post_with_comments.comments, & &1.id)
      assert comment1.id in comment_ids
      assert comment2.id in comment_ids
    end
  end

  describe "timestamps" do
    test "post has utc_datetime timestamps" do
      {:ok, post} = Links.Posts.create_post(post_attrs())
      
      assert %DateTime{} = post.inserted_at
      assert %DateTime{} = post.updated_at
      assert post.inserted_at.time_zone == "Etc/UTC"
      assert post.updated_at.time_zone == "Etc/UTC"
    end
  end
end