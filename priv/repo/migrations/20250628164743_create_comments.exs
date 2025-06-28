defmodule Links.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :text, null: false
      add :author, :string, null: false
      add :link_id, references(:links, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:link_id])
    create index(:comments, [:author])
    create index(:comments, [:inserted_at])
  end
end