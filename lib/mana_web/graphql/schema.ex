defmodule ManaWeb.GraphQL.Schema do
  @moduledoc false
  use Absinthe.Schema

  query do
    @desc "Current git SHA"
    field :version, non_null(:string) do
      resolve(fn _, _, _ -> {:ok, Mana.version()} end)
    end

    @desc "Service readiness status"
    field :status, non_null(:string) do
      resolve(fn _, _, _ -> {:ok, Mana.status()} end)
    end
  end
end
