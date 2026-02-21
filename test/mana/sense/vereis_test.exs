defmodule Mana.Sense.VereisTest do
  use ExUnit.Case, async: true

  alias Mana.Sense.Vereis

  test "changeset casts presence and embedded activities" do
    attrs = %{
      "presence" => "online",
      "listening_to" => %{"track" => "Genesis", "artist" => "Grimes"},
      "playing" => %{"name" => "Factorio"},
      "editing" => %{"name" => "Neovim", "details" => "Elixir"}
    }

    changeset = Vereis.changeset(%Vereis{}, attrs)

    assert changeset.valid?
    assert changeset.changes.presence == :online
    assert changeset.changes.listening_to.changes.track == "Genesis"
    assert changeset.changes.playing.changes.name == "Factorio"
    assert changeset.changes.editing.changes.name == "Neovim"
  end
end
