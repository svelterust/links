defmodule Links.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :title, :string, null: false
      add :url, :string, null: false
      add :author, :string, null: false
      add :points, :integer, default: 0, null: false
      add :comment_count, :integer, default: 0, null: false
      add :tags, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:links, [:url])
    create index(:links, [:author])
    create index(:links, [:points])
    create index(:links, [:inserted_at])
  end
end