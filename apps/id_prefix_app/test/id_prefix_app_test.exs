defmodule IdPrefixAppTest do
  use ExUnit.Case
  doctest IdPrefixApp

  test "greets the world" do
    assert IdPrefixApp.hello() == :world
  end
end
