defmodule Workspace.TestEvents do
  @moduledoc """
  Module for testing event sending functionality.
  """

  @doc """
  Sends a series of test events to demonstrate the event system.
  """
  def send_test_events do
    # Send a simple event
    Workspace.send_event("test", "This is a test event")
    Process.sleep(1000)

    # Send an event with metadata
    Workspace.send_event("test", "Event with metadata", %{
      "number" => 42,
      "boolean" => true,
      "nested" => %{
        "key" => "value"
      }
    })
    Process.sleep(1000)

    # Send an error event
    Workspace.send_event("error", "Something went wrong", %{
      "error_code" => 500,
      "reason" => "Internal server error"
    })
    Process.sleep(1000)

    # Send a custom event
    Workspace.send_event("custom", "Custom event type", %{
      "data" => "Custom data"
    })
    Process.sleep(1000)

    # Send a performance event
    Workspace.send_event("performance", "High CPU usage detected", %{
      "cpu_usage" => "85%",
      "memory_usage" => "60%",
      "threshold" => "80%",
      "timestamp" => DateTime.utc_now() |> DateTime.to_string()
    })

    :ok
  end
end
