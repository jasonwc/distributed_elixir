import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :server, ServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "LkA+Qq8i1QgjXu/RMsoCVHQi6D9KXBQz6Dr8ygVSS3yhuPuAhKCL3x7VrGrJqXiY",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure the database
config :server, Server.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
