defmodule Links.Posts.CommentTest do
  use Links.DataCase

  alias Links.Posts.Comment
  import Links.Fixtures

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
      assert changeset.changes.content == attrs.content
      assert changeset.changes.author == attrs.author
      assert changeset.changes.link_id == attrs.link_id
    end

    test "invalid changeset with missing required fields" do
      changeset = Comment.changeset(%Comment{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).content
      assert "can't be blank" in errors_on(changeset).author
      assert "can't be blank" in errors_on(changeset).link_id
    end

    test "invalid changeset with empty content" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, content: ""})
      changeset = Comment.changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).content
    end

    test "invalid changeset with content too long" do
      post = post_fixture()
      long_content = String.duplicate("a", 10001)
      attrs = comment_attrs(%{link_id: post.id, content: long_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "should be at most 10000 character(s)" in errors_on(changeset).content
    end

    test "valid changeset with content at max length" do
      post = post_fixture()
      max_content = String.duplicate("a", 10000)
      attrs = comment_attrs(%{link_id: post.id, content: max_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "valid changeset with content at min length" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, content: "a"})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset with empty author" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, author: ""})
      changeset = Comment.changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).author
    end

    test "invalid changeset with author too long" do
      post = post_fixture()
      long_author = String.duplicate("a", 101)
      attrs = comment_attrs(%{link_id: post.id, author: long_author})
      changeset = Comment.changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).author
    end

    test "valid changeset with author at max length" do
      post = post_fixture()
      max_author = String.duplicate("a", 100)
      attrs = comment_attrs(%{link_id: post.id, author: max_author})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "valid changeset with author at min length" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, author: "a"})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset with nil link_id" do
      attrs = comment_attrs(%{link_id: nil})
      changeset = Comment.changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).link_id
    end

    test "valid changeset with multiline content" do
      post = post_fixture()

      multiline_content = """
      This is a multiline comment.
      It has several lines.
      And it should be valid.
      """

      attrs = comment_attrs(%{link_id: post.id, content: multiline_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
      assert changeset.changes.content == multiline_content
    end

    test "valid changeset with special characters in content" do
      post = post_fixture()
      special_content = "This comment has special chars: !@#$%^&*()_+-=[]{}|;:,.<>?"
      attrs = comment_attrs(%{link_id: post.id, content: special_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
      assert changeset.changes.content == special_content
    end

    test "valid changeset with unicode content" do
      post = post_fixture()
      unicode_content = "This comment has unicode: 你好世界 🌍 café résumé"
      attrs = comment_attrs(%{link_id: post.id, content: unicode_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
      assert changeset.changes.content == unicode_content
    end
  end

  describe "create_changeset/2" do
    test "valid create changeset with all required fields" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id})
      changeset = Comment.create_changeset(%Comment{}, attrs)

      assert changeset.valid?
      assert changeset.changes.content == attrs.content
      assert changeset.changes.author == attrs.author
      assert changeset.changes.link_id == attrs.link_id
    end

    test "create changeset has same validations as regular changeset" do
      _post = post_fixture()

      # Test with invalid data
      invalid_attrs = %{content: "", author: "", link_id: nil}
      changeset = Comment.create_changeset(%Comment{}, invalid_attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).content
      assert "can't be blank" in errors_on(changeset).author
      assert "can't be blank" in errors_on(changeset).link_id
    end

    test "create changeset with content length validation" do
      post = post_fixture()
      long_content = String.duplicate("a", 10001)
      attrs = comment_attrs(%{link_id: post.id, content: long_content})
      changeset = Comment.create_changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "should be at most 10000 character(s)" in errors_on(changeset).content
    end

    test "create changeset with author length validation" do
      post = post_fixture()
      long_author = String.duplicate("a", 101)
      attrs = comment_attrs(%{link_id: post.id, author: long_author})
      changeset = Comment.create_changeset(%Comment{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).author
    end
  end

  describe "associations" do
    test "comment belongs to post" do
      post = post_fixture()
      comment = comment_fixture(%{link_id: post.id})

      comment_with_post =
        Links.Repo.get!(Comment, comment.id)
        |> Links.Repo.preload(:post)

      assert comment_with_post.post.id == post.id
      assert comment_with_post.post.title == post.title
    end

    test "comment association uses link_id as foreign key" do
      post = post_fixture()
      comment = comment_fixture(%{link_id: post.id})

      assert comment.link_id == post.id
    end
  end

  describe "timestamps" do
    test "comment has utc_datetime timestamps" do
      post = post_fixture()
      {:ok, comment} = Links.Posts.create_comment(comment_attrs(%{link_id: post.id}))

      assert %DateTime{} = comment.inserted_at
      assert %DateTime{} = comment.updated_at
      assert comment.inserted_at.time_zone == "Etc/UTC"
      assert comment.updated_at.time_zone == "Etc/UTC"
    end
  end

  describe "edge cases" do
    test "comment with exactly 1 character content" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, content: "a"})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "comment with exactly 10000 character content" do
      post = post_fixture()
      max_content = String.duplicate("a", 10000)
      attrs = comment_attrs(%{link_id: post.id, content: max_content})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "comment with exactly 1 character author" do
      post = post_fixture()
      attrs = comment_attrs(%{link_id: post.id, author: "a"})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end

    test "comment with exactly 100 character author" do
      post = post_fixture()
      max_author = String.duplicate("a", 100)
      attrs = comment_attrs(%{link_id: post.id, author: max_author})
      changeset = Comment.changeset(%Comment{}, attrs)

      assert changeset.valid?
    end
  end
end
