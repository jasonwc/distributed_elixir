defmodule Server.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Server.Repo
  alias Server.Events.Event
  alias Phoenix.PubSub

  @doc """
  Returns a list of recent events.
  """
  def list_events(opts \\ []) do
    node = Keyword.get(opts, :node)
    type = Keyword.get(opts, :type)
    limit = Keyword.get(opts, :limit, 100)

    cond do
      node && type ->
        from(e in Event,
          where: e.node == ^node and e.type == ^type,
          order_by: [desc: e.inserted_at],
          limit: ^limit
        )
        |> Repo.all()

      node ->
        Event.list_by_node(node, limit) |> Repo.all()

      type ->
        Event.list_by_type(type, limit) |> Repo.all()

      true ->
        Event.list_recent(limit) |> Repo.all()
    end
  end

  @doc """
  Gets a single event.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a new event.
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
    |> broadcast_event()
  end

  @doc """
  Records an event from a workspace node.
  """
  def record_workspace_event(node, type, message, metadata \\ %{}) do
    attrs = %{
      node: to_string(node),
      type: to_string(type),
      message: message,
      metadata: metadata
    }

    create_event(attrs)
  end

  defp broadcast_event({:ok, event} = result) do
    PubSub.broadcast(Server.PubSub, "workspace_events", {:new_event, event})
    result
  end

  defp broadcast_event(error), do: error
end
