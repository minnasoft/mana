defmodule Mana.Sense.Vereis do
  @moduledoc "Vereis sense supervision tree and canonical schema owner."

  use Supervisor
  use Ecto.Schema

  import Ecto.Changeset
  import Mana.Utils, only: [embedded_changeset: 2]

  alias Mana.Sense.Vereis.Discord

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  @presence_states [:online, :idle, :dnd, :offline]

  schema "vereis" do
    field :presence, Ecto.Enum, values: @presence_states, default: :offline

    embeds_one :listening_to, ListeningTo, primary_key: false do
      field :track, :string
      field :artist, :string
      field :album, :string
      field :started_at, :utc_datetime_usec
      field :ends_at, :utc_datetime_usec
    end

    embeds_one :playing, Playing, primary_key: false do
      field :name, :string
      field :details, :string
      field :state, :string
      field :started_at, :utc_datetime_usec
      field :ends_at, :utc_datetime_usec
    end

    embeds_one :editing, Editing, primary_key: false do
      field :name, :string
      field :details, :string
      field :state, :string
      field :started_at, :utc_datetime_usec
      field :ends_at, :utc_datetime_usec
    end

    timestamps()
  end

  def changeset(vereis, attrs) do
    vereis
    |> cast(attrs, [:presence])
    |> cast_embed(:listening_to, with: &embedded_changeset/2)
    |> cast_embed(:playing, with: &embedded_changeset/2)
    |> cast_embed(:editing, with: &embedded_changeset/2)
    |> validate_required([:presence])
  end

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      Discord
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
