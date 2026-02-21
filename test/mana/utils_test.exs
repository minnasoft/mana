defmodule Mana.UtilsTest do
  use ExUnit.Case, async: true

  alias Mana.Sense.Vereis.ListeningTo
  alias Mana.Utils

  test "embedded_changeset casts known embedded fields" do
    changeset =
      Utils.embedded_changeset(%ListeningTo{}, %{
        "track" => "Genesis",
        "artist" => "Grimes",
        "album" => "Art Angels"
      })

    assert changeset.valid?
    assert changeset.changes.track == "Genesis"
    assert changeset.changes.artist == "Grimes"
    assert changeset.changes.album == "Art Angels"
  end
end
