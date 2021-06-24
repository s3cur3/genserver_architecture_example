defmodule UserCounterTest do
  use ExUnit.Case, async: true

  test "initializes to zero" do
    # Woohoo, it works!
    assert UserCounter.count() == 0
  end
end
