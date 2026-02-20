defmodule Mana.Sense.VereisJobTest do
  use Mana.DataCase, async: false
  use Oban.Testing, repo: Mana.Repo

  alias Mana.Sense.Impression
  alias Mana.Sense.Vereis
  alias Mana.Sense.Vereis.Discord
  alias Mana.Utils.ETS

  @table Discord

  setup do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table)
    end

    :ets.new(@table, [:named_table, :public, read_concurrency: true, write_concurrency: true])

    ETS.put(@table, :current, %{
      presence: :online,
      listening_to: %{track: "Genesis", artist: "Grimes", album: "Art Angels"},
      playing: %{name: "Factorio"},
      editing: %{name: "Neovim"}
    })

    ETS.put(@table, :deltas, [
      %{kind: "presence_changed", delta: %{from: :offline, to: :online}, occurred_at: DateTime.utc_now()}
    ])

    on_exit(fn ->
      if :ets.whereis(@table) != :undefined do
        :ets.delete(@table)
      end
    end)

    :ok
  end

  test "perform_job persists canonical row and impressions, then clears deltas" do
    assert {:ok, _result} = perform_job(Vereis, %{})

    assert Repo.aggregate(Vereis, :count, :id) == 1
    assert Repo.aggregate(Impression, :count, :id) == 1

    {:ok, current, deltas} = Discord.get_state()
    assert current.presence == :online
    assert deltas == []
  end
end
