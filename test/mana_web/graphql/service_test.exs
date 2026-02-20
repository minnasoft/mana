defmodule ManaWeb.GraphQL.ServiceTest do
  use Mana.DataCase, async: true

  alias ManaWeb.GraphQL.Schema

  test "version query returns SHA string" do
    query = "{ version }"

    assert {:ok, %{data: %{"version" => version}}} =
             Absinthe.run(query, Schema)

    assert is_binary(version)
    assert String.length(version) > 0
  end

  test "status query returns ok when db is reachable" do
    query = "{ status }"

    assert {:ok, %{data: %{"status" => "ok"}}} =
             Absinthe.run(query, Schema)
  end
end
