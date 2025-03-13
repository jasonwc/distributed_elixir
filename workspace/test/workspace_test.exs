defmodule WorkspaceTest do
  use ExUnit.Case
  doctest Workspace

  test "greets the world" do
    assert Workspace.hello() == :world
  end
end
