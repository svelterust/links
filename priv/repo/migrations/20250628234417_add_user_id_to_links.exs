defmodule Links.Repo.Migrations.AddUserIdToLinks do
  use Ecto.Migration

  def change do
    drop index(:links, [:author])
    
    alter table(:links) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      remove :author
    end

    create index(:links, [:user_id])
  end
end
