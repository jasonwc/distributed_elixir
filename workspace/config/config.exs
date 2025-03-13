import Config

config :workspace,
  server_node: "server@127.0.0.1"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs" 