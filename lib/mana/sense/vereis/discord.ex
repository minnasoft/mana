defmodule Mana.Sense.Vereis.Discord do
  @moduledoc "Lanyard websocket client with ETS-backed current/deltas state."

  use WebSockex

  alias Mana.Utils.ETS

  require Logger

  @websocket_url "wss://api.lanyard.rest/socket"

  @op_event 0
  @op_hello 1
  @op_initialize 2
  @op_heartbeat 3

  @table __MODULE__
  @initial_backoff 1_000
  @max_backoff 60_000
  @discord_user_id_key :discord_user_id

  @presence_by_status %{
    "online" => :online,
    "idle" => :idle,
    "dnd" => :dnd,
    "offline" => :offline
  }

  @type current :: %{
          optional(:presence) => :online | :idle | :dnd | :offline,
          optional(:listening_to) => map() | nil,
          optional(:playing) => map() | nil,
          optional(:editing) => map() | nil,
          optional(:last_event_at) => DateTime.t()
        }

  @spec get_state() :: {:ok, current(), [map()]}
  def get_state do
    current = ETS.get(@table, :current, %{presence: :offline})
    deltas = ETS.get(@table, :deltas, [])
    {:ok, current, deltas}
  end

  @spec clear_state() :: :ok
  def clear_state do
    @table = ETS.put(@table, :deltas, [])
    :ok
  end

  def start_link(_opts) do
    discord_user_id = discord_user_id()

    if is_binary(discord_user_id) and discord_user_id != "" do
      :ok = ensure_table()

      initial_state = %{
        discord_user_id: discord_user_id,
        heartbeat_interval: 30_000,
        heartbeat_ref: nil,
        backoff: @initial_backoff
      }

      WebSockex.start_link(@websocket_url, __MODULE__, initial_state, name: __MODULE__)
    else
      :ignore
    end
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("[Vereis.Discord] connected")
    {:ok, %{state | backoff: @initial_backoff}}
  end

  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("[Vereis.Discord] disconnected: #{inspect(reason)}; reconnect in #{state.backoff}ms")
    Process.sleep(state.backoff)
    new_backoff = min(state.backoff * 2, @max_backoff)
    {:reconnect, %{state | backoff: new_backoff}}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    payload = Jason.decode!(msg)
    {:ok, handle_payload(payload, state)}
  end

  @impl WebSockex
  def handle_frame(_frame, state) do
    {:ok, state}
  end

  @impl WebSockex
  def handle_info(:heartbeat, state) do
    heartbeat_ref = Process.send_after(self(), :heartbeat, state.heartbeat_interval)
    payload = Jason.encode!(%{op: @op_heartbeat})
    {:reply, {:text, payload}, %{state | heartbeat_ref: heartbeat_ref}}
  end

  @impl WebSockex
  def handle_info(_msg, state) do
    {:ok, state}
  end

  defp handle_payload(%{"op" => @op_hello, "d" => %{"heartbeat_interval" => interval}}, state) do
    cancel_heartbeat(state.heartbeat_ref)

    heartbeat_ref = Process.send_after(self(), :heartbeat, interval)

    identify = %{
      op: @op_initialize,
      d: %{subscribe_to_id: state.discord_user_id}
    }

    {:ok, encoded_identify} = Jason.encode(identify)
    :ok = WebSockex.send_frame(self(), {:text, encoded_identify})

    %{state | heartbeat_interval: interval, heartbeat_ref: heartbeat_ref, backoff: @initial_backoff}
  end

  defp handle_payload(%{"op" => @op_event, "t" => type, "d" => data}, state)
       when type in ["INIT_STATE", "PRESENCE_UPDATE"] do
    new_current = transform(data)
    old_current = ETS.get(@table, :current, %{presence: :offline})
    deltas = build_deltas(old_current, new_current)

    @table = ETS.put(@table, :current, new_current)
    existing = ETS.get(@table, :deltas, [])
    @table = ETS.put(@table, :deltas, existing ++ deltas)

    state
  end

  defp handle_payload(payload, _state) do
    raise "unsupported lanyard payload: #{inspect(payload)}"
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, read_concurrency: true, write_concurrency: true])
        @table = ETS.put(@table, :current, %{presence: :offline})
        @table = ETS.put(@table, :deltas, [])
        :ok

      _ ->
        :ok
    end
  end

  defp discord_user_id do
    Application.get_env(:mana, @discord_user_id_key)
  end

  defp cancel_heartbeat(nil) do
    :ok
  end

  defp cancel_heartbeat(ref) do
    Process.cancel_timer(ref)
    :ok
  end

  defp transform(data) do
    %{
      presence: map_presence(data["discord_status"]),
      listening_to: extract_listening(data),
      playing: extract_playing(data),
      editing: extract_editing(data),
      last_event_at: DateTime.utc_now()
    }
  end

  defp build_deltas(old_current, new_current) do
    now = DateTime.utc_now()

    [
      {:presence_changed, old_current[:presence], new_current[:presence]},
      {:listening_changed, old_current[:listening_to], new_current[:listening_to]},
      {:playing_changed, old_current[:playing], new_current[:playing]},
      {:editing_changed, old_current[:editing], new_current[:editing]}
    ]
    |> Enum.filter(fn {_kind, from, to} ->
      from != to
    end)
    |> Enum.map(fn {kind, from, to} ->
      %{kind: to_string(kind), delta: %{from: from, to: to}, occurred_at: now}
    end)
  end

  defp map_presence(status) do
    Map.get(@presence_by_status, status, :offline)
  end

  defp extract_listening(%{"listening_to_spotify" => true, "spotify" => spotify}) when is_map(spotify) do
    %{
      track: spotify["song"],
      artist: spotify["artist"],
      album: spotify["album"],
      started_at: parse_timestamp(get_in(spotify, ["timestamps", "start"])),
      ends_at: parse_timestamp(get_in(spotify, ["timestamps", "end"]))
    }
  end

  defp extract_listening(_data) do
    nil
  end

  defp extract_playing(data) do
    data
    |> find_activity(&game_activity?/1)
    |> to_activity_payload()
  end

  defp extract_editing(data) do
    data
    |> find_activity(&vim_activity?/1)
    |> to_activity_payload()
  end

  defp find_activity(data, predicate) do
    data
    |> Map.get("activities", [])
    |> Enum.find(predicate)
  end

  defp to_activity_payload(nil) do
    nil
  end

  defp to_activity_payload(activity) do
    %{
      name: activity["name"],
      details: activity["details"],
      state: activity["state"],
      started_at: parse_timestamp(get_in(activity, ["timestamps", "start"])),
      ends_at: parse_timestamp(get_in(activity, ["timestamps", "end"]))
    }
  end

  defp game_activity?(activity) do
    activity["type"] == 0 and not vim_activity?(activity)
  end

  defp vim_activity?(activity) do
    String.match?(activity["name"] || "", ~r/n?vim/i)
  end

  defp parse_timestamp(ms) when is_integer(ms) do
    DateTime.from_unix!(ms, :millisecond)
  end

  defp parse_timestamp(_ms) do
    nil
  end
end
