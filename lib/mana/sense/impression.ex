defmodule Mana.Sense.Impression do
  @moduledoc "Append-only sense event stream."

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec, updated_at: false]

  schema "impressions" do
    field :kind, :string
    field :delta, :map
    field :occurred_at, :utc_datetime_usec

    timestamps()
  end

  def changeset(impression, attrs) do
    impression
    |> cast(attrs, [:kind, :delta, :occurred_at])
    |> validate_required([:kind, :delta, :occurred_at])
  end
end
