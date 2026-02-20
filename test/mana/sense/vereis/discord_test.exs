defmodule Mana.Sense.Vereis.DiscordTest do
  use ExUnit.Case, async: false

  alias Mana.Sense.Vereis.Discord
  alias Mana.Utils.ETS

  @table Discord

  setup do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table)
    end

    :ets.new(@table, [:named_table, :public, read_concurrency: true, write_concurrency: true])
    ETS.put(@table, :current, %{presence: :offline})
    ETS.put(@table, :deltas, [])

    on_exit(fn ->
      if :ets.whereis(@table) != :undefined do
        :ets.delete(@table)
      end
    end)

    :ok
  end

  test "presence update populates current and deltas" do
    payload = %{
      "op" => 0,
      "t" => "PRESENCE_UPDATE",
      "d" => %{
        "discord_status" => "online",
        "listening_to_spotify" => true,
        "spotify" => %{
          "song" => "Genesis",
          "artist" => "Grimes",
          "album" => "Art Angels",
          "timestamps" => %{"start" => 1_700_000_000_000, "end" => 1_700_000_100_000}
        },
        "activities" => [
          %{"type" => 0, "name" => "Factorio", "details" => "Factory", "state" => "Spaghetti"},
          %{"type" => 0, "name" => "Neovim", "details" => "Editing foo.ex", "state" => "coding"}
        ]
      }
    }

    state = %{discord_user_id: "382588737441497088", heartbeat_ref: nil, heartbeat_interval: 30_000, backoff: 1_000}
    json = Jason.encode!(payload)

    assert {:ok, _state} = Discord.handle_frame({:text, json}, state)

    {:ok, current, deltas} = Discord.get_state()

    assert current.presence == :online
    assert current.listening_to.track == "Genesis"
    assert current.playing.name == "Factorio"
    assert current.editing.name == "Neovim"
    assert deltas != []
    assert Enum.any?(deltas, fn d -> d.kind == "presence_changed" end)
  end

  test "invalid payload crashes fast" do
    state = %{discord_user_id: "382588737441497088", heartbeat_ref: nil, heartbeat_interval: 30_000, backoff: 1_000}

    assert_raise Jason.DecodeError, fn ->
      Discord.handle_frame({:text, "not-json"}, state)
    end
  end

  test "clear_state clears deltas only" do
    ETS.put(@table, :current, %{presence: :online})
    ETS.put(@table, :deltas, [%{kind: "presence_changed", delta: %{from: :offline, to: :online}}])

    assert :ok == Discord.clear_state()

    {:ok, current, deltas} = Discord.get_state()
    assert current.presence == :online
    assert deltas == []
  end
end
