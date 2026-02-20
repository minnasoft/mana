defmodule Mana.Repo.Migrations.CreateVereis do
  use Ecto.Migration

  def change do
    create table(:vereis, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :presence, :string, null: false, default: "offline"
      add :listening_to, :map
      add :playing, :map
      add :editing, :map

      timestamps(type: :utc_datetime_usec)
    end
  end
end
