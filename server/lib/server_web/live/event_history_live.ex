defmodule ServerWeb.EventHistoryLive do
  use ServerWeb, :live_view
  require Logger
  alias Server.Events

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Server.PubSub, "workspace_events")
      events = Events.list_events(limit: 50)
      {:ok, assign(socket, events: events, filter: %{node: nil, type: nil})
            |> assign(page_title: "Event History")}
    else
      {:ok, assign(socket, events: [], filter: %{node: nil, type: nil})
            |> assign(page_title: "Event History")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    node = params["node"]
    type = params["type"]

    filter = %{node: node, type: type}
    events = fetch_events(filter)

    {:noreply, assign(socket, events: events, filter: filter)}
  end

  @impl true
  def handle_info({:new_event, event}, socket) do
    # Only add the event if it matches the current filter
    events = if matches_filter?(event, socket.assigns.filter) do
      [event | socket.assigns.events] |> Enum.take(50)
    else
      socket.assigns.events
    end

    {:noreply, assign(socket, :events, events)}
  end

  @impl true
  def handle_info({:workspace_status, _status}, socket) do
    # We don't need to do anything with workspace status in the event history view
    {:noreply, socket}
  end

  @impl true
  def handle_info({:workspace_connected, _node}, socket) do
    # We don't need to do anything with workspace connections in the event history view
    {:noreply, socket}
  end

  @impl true
  def handle_info({:workspace_disconnected, _node}, socket) do
    # We don't need to do anything with workspace disconnections in the event history view
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear-filter", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/events")}
  end

  @impl true
  def handle_event("filter-node", %{"node" => node}, socket) do
    params = if socket.assigns.filter.type do
      %{"node" => node, "type" => socket.assigns.filter.type}
    else
      %{"node" => node}
    end

    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  @impl true
  def handle_event("filter-type", %{"type" => type}, socket) do
    params = if socket.assigns.filter.node do
      %{"node" => socket.assigns.filter.node, "type" => type}
    else
      %{"type" => type}
    end

    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <div class="mb-4 flex items-center space-x-2">
        <div class="text-sm font-medium text-gray-700">Filters:</div>
        <%= if @filter.node || @filter.type do %>
          <div class="flex items-center space-x-2">
            <%= if @filter.node do %>
              <span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-blue-100 text-blue-800">
                Node: <%= @filter.node %>
                <button phx-click="clear-filter" class="ml-1 text-blue-500 hover:text-blue-700">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                  </svg>
                </button>
              </span>
            <% end %>

            <%= if @filter.type do %>
              <span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-green-100 text-green-800">
                Type: <%= @filter.type %>
                <button phx-click="clear-filter" class="ml-1 text-green-500 hover:text-green-700">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                  </svg>
                </button>
              </span>
            <% end %>
          </div>
        <% else %>
          <span class="text-sm text-gray-500">None</span>
        <% end %>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Timestamp
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Node
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Type
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Message
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Metadata
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for event <- @events do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= format_timestamp(event.inserted_at) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <button
                    phx-click="filter-node"
                    phx-value-node={event.node}
                    class="text-sm font-medium text-blue-600 hover:text-blue-900"
                  >
                    <%= event.node %>
                  </button>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <button
                    phx-click="filter-type"
                    phx-value-type={event.type}
                    class="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 hover:bg-green-200"
                  >
                    <%= event.type %>
                  </button>
                </td>
                <td class="px-6 py-4 text-sm text-gray-500">
                  <%= event.message %>
                </td>
                <td class="px-6 py-4 text-sm text-gray-500">
                  <%= if map_size(event.metadata) > 0 do %>
                    <details>
                      <summary class="cursor-pointer text-blue-500 hover:text-blue-700">View details</summary>
                      <pre class="mt-2 text-xs bg-gray-100 p-2 rounded"><%= Jason.encode!(event.metadata, pretty: true) %></pre>
                    </details>
                  <% else %>
                    <span class="text-gray-400">None</span>
                  <% end %>
                </td>
              </tr>
            <% end %>

            <%= if Enum.empty?(@events) do %>
              <tr>
                <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">
                  No events found
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp fetch_events(filter) do
    opts = []
    opts = if filter.node, do: Keyword.put(opts, :node, filter.node), else: opts
    opts = if filter.type, do: Keyword.put(opts, :type, filter.type), else: opts
    opts = Keyword.put(opts, :limit, 50)

    Events.list_events(opts)
  end

  defp matches_filter?(event, filter) do
    (is_nil(filter.node) || event.node == filter.node) &&
    (is_nil(filter.type) || event.type == filter.type)
  end

  defp format_timestamp(datetime) do
    datetime
    |> NaiveDateTime.to_string()
  end
end
