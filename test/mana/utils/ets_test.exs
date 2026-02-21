defmodule Mana.Utils.ETSTest do
  use ExUnit.Case, async: true

  alias Mana.Utils.ETS

  test "get/3 and put/3 work with ets table" do
    table = :ets_test_table

    if :ets.whereis(table) != :undefined do
      :ets.delete(table)
    end

    :ets.new(table, [:named_table, :public])

    on_exit(fn ->
      if :ets.whereis(table) != :undefined do
        :ets.delete(table)
      end
    end)

    assert ETS.get(table, :a, :missing) == :missing
    assert ETS.put(table, :a, 1) == table
    assert ETS.get(table, :a, :missing) == 1
  end
end
