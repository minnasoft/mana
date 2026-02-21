defmodule Mana.Sense do
  @moduledoc "Sense behaviour + default Oban execution engine."

  alias Mana.Repo
  alias Mana.Sense.Impression

  @type change :: %{action: :insert | :update, record: Ecto.Schema.t(), prev: map() | nil}

  @callback source() :: atom()
  @callback poll() :: {:ok, map(), [map()]} | {:error, term()}
  @callback canonical_schema() :: module()
  @callback match_key(map()) :: map()
  @callback to_canonical(map()) :: map()
  @callback summarize(change()) :: String.t()
  @callback derive_intentions([change()]) :: [map()]
  @callback ack_poll(map(), [map()]) :: :ok | {:error, term()}

  defmacro __using__(opts) do
    queue = Keyword.get(opts, :queue, :senses)
    max_attempts = Keyword.get(opts, :max_attempts, 5)

    quote do
      @behaviour Mana.Sense

      use Oban.Worker, queue: unquote(queue), max_attempts: unquote(max_attempts)

      @impl Mana.Sense
      def summarize(change) do
        "#{source()}: #{change.action}"
      end

      @impl Mana.Sense
      def derive_intentions(_changes) do
        []
      end

      @impl Mana.Sense
      def ack_poll(_current, _deltas) do
        :ok
      end

      defoverridable summarize: 1, derive_intentions: 1, ack_poll: 2

      @impl Oban.Worker
      def perform(%Oban.Job{}) do
        Mana.Sense.run(__MODULE__)
      end
    end
  end

  @spec run(module()) :: {:ok, map()} | {:error, term()}
  def run(module) do
    with {:ok, current, deltas} <- module.poll(),
         {:ok, result} <- persist(module, current, deltas),
         :ok <- module.ack_poll(current, deltas) do
      {:ok, result}
    end
  end

  defp persist(module, current, deltas) do
    Repo.transaction(fn ->
      changes = upsert_canonical(module, current)
      impressions = insert_impressions(deltas)
      intentions = module.derive_intentions(changes)

      %{changes: length(changes), impressions: impressions, intentions: length(intentions)}
    end)
  end

  defp upsert_canonical(module, current) do
    schema = module.canonical_schema()
    key = module.match_key(current)
    attrs = module.to_canonical(current)

    existing = Repo.get_by(schema, key)
    record = existing || struct(schema)
    prev = if existing, do: Map.from_struct(existing)

    changeset =
      if function_exported?(schema, :changeset, 2) do
        apply(schema, :changeset, [record, attrs])
      else
        Ecto.Changeset.change(record, attrs)
      end

    if map_size(changeset.changes) == 0 do
      []
    else
      saved = Repo.insert_or_update!(changeset)
      action = if existing, do: :update, else: :insert
      [%{action: action, record: saved, prev: prev}]
    end
  end

  defp insert_impressions(deltas) do
    rows =
      Enum.map(deltas, fn delta ->
        %{
          id: Ecto.UUID.generate(),
          kind: delta.kind,
          delta: delta.delta,
          occurred_at: delta.occurred_at || DateTime.utc_now(),
          inserted_at: DateTime.utc_now()
        }
      end)

    case rows do
      [] ->
        0

      _ ->
        {count, _} = Repo.insert_all(Impression, rows)
        count
    end
  end
end
