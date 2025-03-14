# List available commands
default:
    @just --list

# Install dependencies for both applications
setup:
    cd server && mix deps.get
    cd workspace && mix deps.get

# Start the server node with proper distributed configuration
server:
    cd server && iex --name server@127.0.0.1 --cookie distributed_workspace_cookie -S mix phx.server

# Start a workspace node with proper distributed configuration
workspace node="workspace1":
    cd workspace && iex --name {{node}}@127.0.0.1 --cookie distributed_workspace_cookie -S mix

# Start both server and workspace in separate tmux windows
start:
    #!/usr/bin/env bash
    # Kill any existing tmux session
    tmux kill-session -t distributed_workspace 2>/dev/null || true
    # Create new session
    tmux new-session -d -s distributed_workspace -n server
    # Start server with explicit cookie
    tmux send-keys -t distributed_workspace:server "cd $(pwd)/server && iex --name server@127.0.0.1 --cookie distributed_workspace_cookie -S mix phx.server" C-m
    # Create workspace window
    tmux new-window -t distributed_workspace -n workspace
    # Start workspace with same cookie after a longer delay
    tmux send-keys -t distributed_workspace:workspace "cd $(pwd)/workspace && sleep 5 && iex --name workspace1@127.0.0.1 --cookie distributed_workspace_cookie -S mix" C-m
    # Select server window and attach
    tmux select-window -t distributed_workspace:server
    tmux attach-session -t distributed_workspace

# Run test events on the workspace node
test-events node="workspace1@127.0.0.1":
    #!/usr/bin/env bash
    echo "Running test events on {{node}}..."
    elixir --name tester@127.0.0.1 --cookie distributed_workspace_cookie -e '
      Node.connect(:"{{node}}")
      IO.puts("Connected to workspace node")
      :rpc.call(:"{{node}}", Workspace.TestEvents, :send_test_events, [])
      IO.puts("Test events sent successfully")
    '
    echo "Done."

# Database commands
db-start:
    echo "Starting PostgreSQL database..."
    docker-compose up -d postgres
    echo "Database started. Waiting for it to be ready..."
    sleep 3
    echo "Database is ready."

db-stop:
    echo "Stopping PostgreSQL database..."
    docker-compose down postgres
    echo "Database stopped."

db-status:
    #!/usr/bin/env bash
    echo "Checking PostgreSQL database status..."
    if docker-compose ps postgres | grep -q "Up"; then
        echo "Database is running."
    else
        echo "Database is not running."
    fi

db-setup: db-start
    echo "Setting up the database..."
    cd server && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
    echo "Database setup complete."

db-reset: db-start
    echo "Resetting the database..."
    cd server && mix ecto.drop && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
    echo "Database reset complete."

# Full system setup
full-setup: setup db-setup
    echo "Full system setup complete."

# Full system start
full-start: db-start start
    echo "Full system started." 