defmodule Mana.Utils do
  @moduledoc false

  import Ecto.Changeset, only: [cast: 3]

  @spec embedded_changeset(struct(), map()) :: Ecto.Changeset.t()
  def embedded_changeset(%module{} = struct, attrs) when is_map(attrs) do
    cast(struct, attrs, module.__schema__(:fields))
  end
end
