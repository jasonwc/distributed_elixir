defmodule Workspace do
  @moduledoc """
  Main module for the workspace node.
  Handles status reporting and communication with the server.
  """

  use GenServer
  require Logger

  @server_node :"server@127.0.0.1"
  @connect_retry_interval 1_000 # 1 second

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    # Start connection process
    send(self(), :connect_to_server)
    {:ok, %{connected: false}}
  end

  @impl true
  def handle_info(:connect_to_server, state) do
    if Node.connect(@server_node) do
      Logger.info("Connected to server node")
      # Start sending status updates
      send_status()
      schedule_status_update()
      {:noreply, %{state | connected: true}}
    else
      Logger.warning("Failed to connect to server node, retrying in #{@connect_retry_interval}ms")
      Process.send_after(self(), :connect_to_server, @connect_retry_interval)
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:update_status, state) do
    if state.connected do
      send_status()
      schedule_status_update()
    end
    {:noreply, state}
  end

  @impl true
  def handle_call({:execute_command, command}, _from, state) do
    Logger.info("Executing command: #{command}")
    
    try do
      case System.shell(command) do
        {output, 0} -> 
          Logger.info("Command completed successfully")
          {:reply, {:ok, output}, state}
        {output, status} -> 
          Logger.warning("Command failed with status #{status}")
          {:reply, {:error, %{output: output, status: status}}, state}
      end
    rescue
      e -> 
        Logger.error("Command execution failed: #{inspect(e)}")
        {:reply, {:error, %{output: "Command execution failed", error: e}}, state}
    end
  end

  defp send_status do
    status = %{
      node: Node.self(),
      timestamp: DateTime.utc_now(),
      memory: :erlang.memory(),
      uptime: :erlang.statistics(:wall_clock) |> elem(0)
    }

    try do
      GenServer.call({:WorkspaceServer, @server_node}, {:workspace_status, status})
    catch
      :exit, _ -> 
        Logger.warning("Could not send status to server")
        # Try to reconnect
        send(self(), :connect_to_server)
      :error, _ -> 
        Logger.warning("Could not send status to server")
        # Try to reconnect
        send(self(), :connect_to_server)
    end
  end

  defp schedule_status_update do
    Process.send_after(self(), :update_status, 5000) # Update every 5 seconds
  end
end
