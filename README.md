# Distributed Workspace

A distributed Elixir application consisting of a central server and multiple workspace nodes.

## Overview

This project demonstrates a distributed Elixir application with:

- A central Phoenix server that collects and displays events
- Multiple workspace nodes that can connect to the server
- Event logging system for tracking activities across nodes
- PostgreSQL database for persistent storage

## Requirements

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL (via Docker)
- [just](https://github.com/casey/just) command runner
- tmux (optional, for running server and workspace in split windows)

## Setup

1. Install dependencies:

```bash
just setup
```

2. Set up the database:

```bash
just db-setup
```

Or run the full setup:

```bash
just full-setup
```

## Running the Application

### Start the Server

```bash
just server
```

### Start a Workspace Node

```bash
just workspace
```

Or specify a custom workspace name:

```bash
just workspace workspace2
```

### Start Both Server and Workspace (using tmux)

```bash
just start
```

### Database Management

- Start the database: `just db-start`
- Stop the database: `just db-stop`
- Check database status: `just db-status`
- Reset the database: `just db-reset`

### Testing

Send test events from a workspace node:

```bash
just test-events
```

Or specify a custom workspace node:

```bash
just test-events workspace2@127.0.0.1
```

## Available Commands

Run `just --list` to see all available commands:

```
Available recipes:
    db-reset                                # Reset the database
    db-setup                                # Set up the database
    db-start                                # Start the database
    db-status                               # Check database status
    db-stop                                 # Stop the database
    default                                 # List available commands
    full-setup                              # Full system setup
    full-start                              # Full system start
    server                                  # Start the server node
    setup                                   # Install dependencies
    start                                   # Start both server and workspace
    test-events node="workspace1@127.0.0.1" # Run test events
    workspace node="workspace1"             # Start a workspace node
```

## Web Interface

Once the server is running, you can access the web interface at:

- Dashboard: http://localhost:4000/
- Event History: http://localhost:4000/events 