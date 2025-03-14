defmodule Server.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "events" do
    field :node, :string
    field :type, :string
    field :message, :string
    field :metadata, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:node, :type, :message, :metadata])
    |> validate_required([:node, :type, :message])
  end

  def list_recent(limit \\ 100) do
    from(e in __MODULE__,
      order_by: [desc: e.inserted_at],
      limit: ^limit
    )
  end

  def list_by_node(node, limit \\ 100) do
    from(e in __MODULE__,
      where: e.node == ^node,
      order_by: [desc: e.inserted_at],
      limit: ^limit
    )
  end

  def list_by_type(type, limit \\ 100) do
    from(e in __MODULE__,
      where: e.type == ^type,
      order_by: [desc: e.inserted_at],
      limit: ^limit
    )
  end
end
