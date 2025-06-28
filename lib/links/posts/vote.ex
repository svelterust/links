defmodule Links.Posts.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Links.Accounts.User
  alias Links.Posts.Post

  @vote_types ~w(up down)

  schema "votes" do
    field :type, :string
    belongs_to :user, User
    belongs_to :post, Post

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:type, :user_id, :post_id])
    |> validate_required([:type, :user_id, :post_id])
    |> validate_inclusion(:type, @vote_types)
    |> unique_constraint([:user_id, :post_id], message: "You can only vote once per post")
  end

  def valid_vote_types, do: @vote_types
end