defmodule Mana.Repo.Migrations.EnsureVereisColumns do
  use Ecto.Migration

  def change do
    alter table(:vereis) do
      add_if_not_exists :presence, :string
      add_if_not_exists :listening_to, :map
      add_if_not_exists :playing, :map
      add_if_not_exists :editing, :map
    end
  end
end
