defmodule Mana.Service do
  @moduledoc "Represents the running API service instance."

  alias Mana.Repo

  @doc "Returns the current git SHA (or RELEASE_SHA if set)."
  @spec version() :: String.t()
  def version do
    release_sha = System.get_env("RELEASE_SHA")

    if release_sha in [nil, ""] do
      "git"
      |> System.cmd(["rev-parse", "HEAD"])
      |> then(fn {sha, 0} -> String.trim(sha) end)
    else
      release_sha
    end
  end

  @doc "Returns true if database is reachable."
  @spec readiness?() :: boolean()
  def readiness? do
    match?({:ok, _resp}, Repo.query("SELECT 1", []))
  end

  @doc "Status for GraphQL/REST checks."
  @spec status() :: String.t()
  def status do
    if readiness?(), do: "ok", else: "error"
  end
end
