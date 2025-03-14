defmodule Workspace do
  @moduledoc """
  Main module for the workspace node.
  Handles status reporting and communication with the server.
  """

  use GenServer
  require Logger

  @server_node :"server@127.0.0.1"
  @connect_retry_interval 1_000 # 1 second

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Start connection process
    send(self(), :connect_to_server)
    {:ok, %{connected: false}}
  end

  @impl true
  def handle_info(:connect_to_server, state) do
    if Node.connect(@server_node) do
      Logger.info("Connected to server node")
      # Start sending status updates
      schedule_status_update()
      # Send initial connection event
      send_event_to_server("system", "Workspace node started", %{"node_name" => to_string(Node.self())})
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

    # Use port to capture both stdout and stderr
    port = Port.open({:spawn, "#{command} 2>&1"}, [:exit_status, :binary, :stderr_to_stdout])

    result = receive do
      {^port, {:data, output}} ->
        receive do
          {^port, {:exit_status, 0}} ->
            {:ok, output}
          {^port, {:exit_status, status}} ->
            {:error, %{output: output, status: status}}
        end
    after
      30_000 ->
        Port.close(port)
        {:error, %{output: "Command timed out after 30 seconds", status: 1}}
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:send_event, type, message, metadata}, _from, state) do
    if state.connected do
      result = send_event_to_server(type, message, metadata)
      {:reply, result, state}
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  defp send_status do
    try do
      {total_time, _} = :erlang.statistics(:wall_clock)
      {cpu_time, _} = :erlang.statistics(:runtime)
      status = %{
        node: Node.self(),
        uptime: total_time,
        memory: :erlang.memory(),
        cpu: cpu_time,
        timestamp: DateTime.utc_now()
      }
      GenServer.call({:WorkspaceServer, @server_node}, {:workspace_status, status})
    catch
      :exit, _ ->
        # If sending status fails, try reconnecting to server
        send(self(), :connect_to_server)
    end
  end

  defp send_event_to_server(type, message, metadata \\ %{}) do
    try do
      Logger.info("Sending event to server: type=#{type}, message=#{message}, metadata=#{inspect(metadata)}")
      result = GenServer.call({:WorkspaceServer, @server_node}, {:workspace_event, Node.self(), type, message, metadata})
      Logger.info("Event sent successfully: #{inspect(result)}")
      result
    catch
      :exit, reason ->
        # If sending event fails, try reconnecting to server
        Logger.error("Failed to send event to server: #{inspect(reason)}")
        send(self(), :connect_to_server)
        {:error, :server_unavailable}
    end
  end

  defp schedule_status_update do
    Process.send_after(self(), :update_status, 5000) # Update every 5 seconds
  end

  # Public API

  @doc """
  Sends a custom event to the server.

  ## Parameters

    * `type` - The event type (e.g., "system", "application", "error")
    * `message` - A descriptive message for the event
    * `metadata` - Optional map of additional data related to the event

  ## Examples

      iex> Workspace.send_event("application", "User logged in", %{"user_id" => 123})
      {:ok, %Event{}}

  """
  def send_event(type, message, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:send_event, type, message, metadata})
  end
end
