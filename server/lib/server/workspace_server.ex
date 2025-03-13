defmodule Server.WorkspaceServer do
  use GenServer
  require Logger
  alias Phoenix.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: :WorkspaceServer)
  end

  @impl true
  def init(_state) do
    # Subscribe to node connection events
    :net_kernel.monitor_nodes(true)
    {:ok, %{workspaces: %{}}}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    if is_workspace_node?(node) do
      Logger.info("Workspace node connected: #{node}")
      PubSub.broadcast(Server.PubSub, "workspace_events", {:workspace_connected, node})
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    if is_workspace_node?(node) do
      Logger.info("Workspace node disconnected: #{node}")
      new_workspaces = Map.delete(state.workspaces, node)
      PubSub.broadcast(Server.PubSub, "workspace_events", {:workspace_disconnected, node})
      {:noreply, %{state | workspaces: new_workspaces}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:workspace_status, status}, _from, state) do
    node = status.node
    new_workspaces = Map.put(state.workspaces, node, status)
    
    # Broadcast the status update
    PubSub.broadcast(Server.PubSub, "workspace_events", {:workspace_status, status})
    
    {:reply, :ok, %{state | workspaces: new_workspaces}}
  end

  @impl true
  def handle_call({:execute_command, node, command}, _from, state) do
    if Map.has_key?(state.workspaces, node) do
      try do
        case GenServer.call({Workspace, node}, {:execute_command, command}) do
          {:ok, output} = result ->
            PubSub.broadcast(Server.PubSub, "workspace_events", {:command_completed, node, command, output})
            {:reply, result, state}
          {:error, %{output: output} = error} ->
            PubSub.broadcast(Server.PubSub, "workspace_events", {:command_failed, node, command, output})
            {:reply, {:error, error}, state}
        end
      catch
        :exit, _ ->
          error = {:error, :node_unavailable}
          PubSub.broadcast(Server.PubSub, "workspace_events", {:command_failed, node, command, "Node is unavailable"})
          {:reply, error, state}
      end
    else
      {:reply, {:error, :workspace_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_workspaces, _from, state) do
    {:reply, state.workspaces, state}
  end

  # Public API
  def get_workspaces do
    GenServer.call(:WorkspaceServer, :get_workspaces)
  end

  def execute_command(node, command) do
    GenServer.call(:WorkspaceServer, {:execute_command, node, command})
  end

  # Private helpers
  defp is_workspace_node?(node) do
    node
    |> Atom.to_string()
    |> String.contains?("workspace")
  end
end 