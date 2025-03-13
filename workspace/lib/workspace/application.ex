defmodule Workspace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start the workspace node
    node_name = Application.get_env(:workspace, :node_name)
    Node.start(String.to_atom(node_name))
    Node.set_cookie(:distributed_workspace_cookie)

    # Connect to the server node
    server_node = Application.get_env(:workspace, :server_node) |> String.to_atom()
    Node.connect(server_node)

    children = [
      # Start the Workspace GenServer
      Workspace
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Workspace.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
