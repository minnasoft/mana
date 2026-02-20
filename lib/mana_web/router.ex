defmodule ManaWeb.Router do
  use ManaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/api/graphql", Absinthe.Plug, schema: ManaWeb.GraphQL.Schema
  end

  get "/healthz", ManaWeb.ServiceController, :readiness
  get "/version", ManaWeb.ServiceController, :version
end
