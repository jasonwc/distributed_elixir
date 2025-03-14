# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Server.Repo.insert!(%Server.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Server.Events
alias Server.Events.Event
alias Server.Repo

# Add some sample events if the events table is empty
if Repo.aggregate(Event, :count) == 0 do
  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  # System startup events
  Repo.insert!(%Event{
    node: "server@127.0.0.1",
    type: "system",
    message: "Server node started",
    metadata: %{
      "version" => "0.1.0"
    },
    inserted_at: NaiveDateTime.add(now, -3600, :second),
    updated_at: NaiveDateTime.add(now, -3600, :second)
  })

  # Sample workspace events
  Repo.insert!(%Event{
    node: "workspace1@127.0.0.1",
    type: "connection",
    message: "Workspace connected to server",
    inserted_at: NaiveDateTime.add(now, -1800, :second),
    updated_at: NaiveDateTime.add(now, -1800, :second)
  })

  Repo.insert!(%Event{
    node: "workspace1@127.0.0.1",
    type: "command",
    message: "Command executed: ls -la",
    metadata: %{
      "status" => "success",
      "output" => "total 16\ndrwxr-xr-x  4 user  staff  128 Mar 14 12:00 .\ndrwxr-xr-x  3 user  staff   96 Mar 14 12:00 .."
    },
    inserted_at: NaiveDateTime.add(now, -900, :second),
    updated_at: NaiveDateTime.add(now, -900, :second)
  })

  Repo.insert!(%Event{
    node: "workspace2@127.0.0.1",
    type: "connection",
    message: "Workspace connected to server",
    inserted_at: NaiveDateTime.add(now, -600, :second),
    updated_at: NaiveDateTime.add(now, -600, :second)
  })

  Repo.insert!(%Event{
    node: "workspace2@127.0.0.1",
    type: "system",
    message: "High memory usage detected",
    metadata: %{
      "memory_usage" => "85%",
      "threshold" => "80%"
    },
    inserted_at: NaiveDateTime.add(now, -300, :second),
    updated_at: NaiveDateTime.add(now, -300, :second)
  })
end
