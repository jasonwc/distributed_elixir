defmodule ServerWeb.WorkspaceDashboardLive do
  use ServerWeb, :live_view
  require Logger
  alias Server.WorkspaceServer

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Server.PubSub, "workspace_events")
      workspaces = WorkspaceServer.get_workspaces()
      {:ok, assign(socket, workspaces: workspaces, command: "", selected_node: nil, command_results: %{})}
    else
      {:ok, assign(socket, workspaces: %{}, command: "", selected_node: nil, command_results: %{})}
    end
  end

  @impl true
  def handle_info({:workspace_status, status}, socket) do
    workspaces = Map.put(socket.assigns.workspaces, status.node, status)
    {:noreply, assign(socket, :workspaces, workspaces)}
  end

  @impl true
  def handle_info({:workspace_connected, _node}, socket) do
    workspaces = WorkspaceServer.get_workspaces()
    {:noreply, assign(socket, :workspaces, workspaces)}
  end

  @impl true
  def handle_info({:workspace_disconnected, node}, socket) do
    workspaces = Map.delete(socket.assigns.workspaces, node)
    command_results = Map.delete(socket.assigns.command_results, node)
    {:noreply, assign(socket, workspaces: workspaces, command_results: command_results)}
  end

  @impl true
  def handle_info({:command_completed, node, command, output}, socket) do
    command_results = Map.put(socket.assigns.command_results, node, {:ok, command, output})
    {:noreply, assign(socket, :command_results, command_results)}
  end

  @impl true
  def handle_info({:command_failed, node, command, error}, socket) do
    command_results = Map.put(socket.assigns.command_results, node, {:error, command, error})
    {:noreply, assign(socket, :command_results, command_results)}
  end

  @impl true
  def handle_event("select-node", %{"node" => node}, socket) do
    {:noreply, assign(socket, :selected_node, String.to_atom(node))}
  end

  @impl true
  def handle_event("update-command", %{"command" => command}, socket) do
    {:noreply, assign(socket, :command, command)}
  end

  @impl true
  def handle_event("execute-command", _params, socket) do
    node = socket.assigns.selected_node
    command = socket.assigns.command

    if node && command && command != "" do
      WorkspaceServer.execute_command(node, command)
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Please select a workspace and enter a command")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h1 class="text-2xl font-bold mb-4">Workspace Dashboard</h1>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="bg-white rounded-lg shadow p-4">
          <h2 class="text-xl font-semibold mb-4">Connected Workspaces</h2>
          <div class="space-y-4">
            <%= for {node, status} <- @workspaces do %>
              <div class={"p-4 rounded-lg border #{if @selected_node == node, do: "border-blue-500 bg-blue-50", else: "border-gray-200"}"}>
                <div class="flex items-center justify-between">
                  <div>
                    <h3 class="font-medium"><%= node %></h3>
                    <p class="text-sm text-gray-500">
                      Uptime: <%= format_uptime(status.uptime) %><br/>
                      Memory: <%= format_memory(status.memory) %><br/>
                      Last Update: <%= format_timestamp(status.timestamp) %>
                    </p>
                  </div>
                  <button
                    phx-click="select-node"
                    phx-value-node={node}
                    class={"px-4 py-2 rounded #{if @selected_node == node, do: "bg-blue-500 text-white", else: "bg-gray-100 hover:bg-gray-200"}"}
                  >
                    <%= if @selected_node == node, do: "Selected", else: "Select" %>
                  </button>
                </div>

                <%= if Map.has_key?(@command_results, node) do %>
                  <div class="mt-4">
                    <%= case Map.get(@command_results, node) do %>
                      <% {:ok, cmd, output} -> %>
                        <div class="bg-green-50 border border-green-200 rounded p-2">
                          <p class="text-sm font-medium text-green-800">Command: <%= cmd %></p>
                          <pre class="mt-2 text-sm text-green-700 whitespace-pre-wrap"><%= output %></pre>
                        </div>
                      <% {:error, cmd, error} -> %>
                        <div class="bg-red-50 border border-red-200 rounded p-2">
                          <p class="text-sm font-medium text-red-800">Command: <%= cmd %></p>
                          <p class="mt-2 text-sm text-red-700">Error: <%= inspect(error) %></p>
                        </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow p-4">
          <h2 class="text-xl font-semibold mb-4">Execute Command</h2>
          <form phx-submit="execute-command" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Selected Workspace</label>
              <p class="mt-1 text-sm text-gray-500">
                <%= if @selected_node, do: @selected_node, else: "No workspace selected" %>
              </p>
            </div>
            <div>
              <label for="command" class="block text-sm font-medium text-gray-700">Command</label>
              <input
                type="text"
                name="command"
                id="command"
                value={@command}
                phx-change="update-command"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="Enter command..."
              />
            </div>
            <button
              type="submit"
              disabled={is_nil(@selected_node)}
              class={"w-full px-4 py-2 rounded text-white #{if is_nil(@selected_node), do: "bg-gray-400 cursor-not-allowed", else: "bg-blue-500 hover:bg-blue-600"}"}
            >
              Execute Command
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  defp format_uptime(uptime) do
    {days, {hours, minutes, seconds}} = :calendar.seconds_to_daystime(div(uptime, 1000))
    "#{days}d #{hours}h #{minutes}m #{seconds}s"
  end

  defp format_memory(memory) when is_map(memory) do
    total = memory[:total]
    mb = Float.round(total / 1024 / 1024, 2)
    "#{mb} MB"
  end
  defp format_memory(_), do: "N/A"

  defp format_timestamp(%DateTime{} = timestamp) do
    Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S")
  end
  defp format_timestamp(_), do: "N/A"
end 