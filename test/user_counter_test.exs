defmodule UserCounterTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, counter} = UserCounter.start_link(name: :initialize_test)
    %{counter: counter}
  end

  test "initializes to zero", %{counter: counter} do
    assert UserCounter.count(counter) == 0
  end

  test "increments", %{counter: counter} do
    UserCounter.increment(counter)
    assert UserCounter.count(counter) == 1

    UserCounter.increment(counter)
    assert UserCounter.count(counter) == 2
  end

  test "decrements, but does not go negative", %{counter: counter} do
    UserCounter.decrement(counter)
    assert UserCounter.count(counter) == 0

    UserCounter.increment(counter)
    UserCounter.increment(counter)
    UserCounter.increment(counter)

    UserCounter.decrement(counter)
    assert UserCounter.count(counter) == 2
  end
end
