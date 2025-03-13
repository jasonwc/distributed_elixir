# List available commands
default:
    @just --list

# Install dependencies for both applications
setup:
    cd server && mix deps.get
    cd workspace && mix deps.get

# Start the server node
server:
    cd server && iex --name server@127.0.0.1 -S mix phx.server

# Start a workspace node
workspace:
    cd workspace && iex --name workspace1@127.0.0.1 -S mix

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