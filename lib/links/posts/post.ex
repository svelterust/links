defmodule Links.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "links" do
    field :title, :string
    field :url, :string
    field :points, :integer, default: 0
    field :comment_count, :integer, default: 0
    field :tags, {:array, :string}, default: []

    belongs_to :user, Links.Accounts.User
    has_many :comments, Links.Posts.Comment, foreign_key: :link_id
    has_many :votes, Links.Posts.Vote, foreign_key: :post_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :url, :user_id, :points, :comment_count, :tags])
    |> validate_required([:url, :user_id])
    |> validate_url(:url)
    |> validate_length(:title, min: 1, max: 255)
    |> unique_constraint(:url)
    |> foreign_key_constraint(:user_id)
  end

  @doc false
  def create_changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :url, :user_id, :tags])
    |> validate_required([:url, :user_id])
    |> validate_url(:url)
    |> validate_length(:title, min: 1, max: 255)
    |> unique_constraint(:url)
    |> foreign_key_constraint(:user_id)
    |> put_change(:points, 0)
    |> put_change(:comment_count, 0)
  end

  @doc false
  def update_comment_count_changeset(post, count) do
    post
    |> cast(%{comment_count: count}, [:comment_count])
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
          []
        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end
end