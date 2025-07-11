defmodule Links.Posts.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    field :author, :string
    
    belongs_to :post, Links.Posts.Post, foreign_key: :link_id
    # Note: We keep link_id as the foreign key to maintain database compatibility
    
    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :replies, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :author, :link_id, :parent_id])
    |> validate_required([:content, :author, :link_id])
    |> validate_length(:content, min: 1, max: 10000)
    |> validate_length(:author, min: 1, max: 100)
    |> foreign_key_constraint(:link_id)
    |> foreign_key_constraint(:parent_id)
  end

  @doc false
  def create_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :author, :link_id, :parent_id])
    |> validate_required([:content, :author, :link_id])
    |> validate_length(:content, min: 1, max: 10000)
    |> validate_length(:author, min: 1, max: 100)
    |> foreign_key_constraint(:link_id)
    |> foreign_key_constraint(:parent_id)
  end
end