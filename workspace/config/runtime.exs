import Config

# Configure the node name and cookie from environment variables
config :workspace,
  server_node: System.get_env("SERVER_NODE", "server@127.0.0.1"),
  node_cookie: System.get_env("NODE_COOKIE", "distributed_workspace_cookie"),
  connect_retry_interval: String.to_integer(System.get_env("CONNECT_RETRY_INTERVAL", "1000"))

# Configure the node name for distribution
if config_env() == :prod do
  host = System.get_env("NODE_HOST") || raise "NODE_HOST must be set in production"
  name = System.get_env("NODE_NAME") || raise "NODE_NAME must be set in production"

  config :workspace,
    node_name: :"#{name}@#{host}"
end 