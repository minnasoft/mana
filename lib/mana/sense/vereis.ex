defmodule Mana.Sense.Vereis do
  @moduledoc "Canonical Vereis sense schema + callbacks."

  use Ecto.Schema
  use Mana.Sense, queue: :senses

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

  @impl Mana.Sense
  def source do
    :vereis
  end

  @impl Mana.Sense
  def poll do
    Discord.get_state()
  end

  @impl Mana.Sense
  def canonical_schema do
    __MODULE__
  end

  @impl Mana.Sense
  def match_key(_current) do
    %{}
  end

  @impl Mana.Sense
  def to_canonical(current) do
    %{
      presence: current[:presence] || :offline,
      listening_to: current[:listening_to],
      playing: current[:playing],
      editing: current[:editing]
    }
  end

  @impl Mana.Sense
  def ack_poll(_current, _deltas) do
    Discord.clear_state()
  end
end
