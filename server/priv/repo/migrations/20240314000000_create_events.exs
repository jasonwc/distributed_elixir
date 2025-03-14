defmodule Server.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :node, :string, null: false
      add :type, :string, null: false
      add :message, :text, null: false
      add :metadata, :map, default: "{}"

      timestamps()
    end

    create index(:events, [:node])
    create index(:events, [:type])
    create index(:events, [:inserted_at])
  end
end
