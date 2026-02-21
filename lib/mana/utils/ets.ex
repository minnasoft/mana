defmodule Mana.Utils.ETS do
  @moduledoc "Small get/put helper API for ETS tables only."

  @spec get(atom(), any()) :: any()
  def get(table, key) do
    get(table, key, nil)
  end

  @spec get(atom(), any(), any()) :: any()
  def get(table, key, default) do
    case :ets.lookup(table, key) do
      [{^key, value}] ->
        value

      _ ->
        default
    end
  end

  @spec put(atom(), any(), any()) :: atom()
  def put(table, key, value) do
    true = :ets.insert(table, {key, value})
    table
  end
end
