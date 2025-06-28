defmodule Links.Repo.Migrations.CreateVotesTable do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :type, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:links, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:votes, [:user_id, :post_id])
    create index(:votes, [:post_id])
    create index(:votes, [:user_id])
  end
end
