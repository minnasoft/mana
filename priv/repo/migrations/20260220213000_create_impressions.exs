defmodule Mana.Repo.Migrations.CreateImpressions do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists table(:impressions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :kind, :string, null: false
      add :delta, :map, null: false
      add :occurred_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create_if_not_exists index(:impressions, [:occurred_at], concurrently: true)
    create_if_not_exists index(:impressions, [:kind, :occurred_at], concurrently: true)
  end
end
