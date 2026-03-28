defmodule ElixirMiteTest do
  use ExUnit.Case
  doctest ElixirMite

  test "greets the world" do
    assert ElixirMite.hello() == :world
  end
end
