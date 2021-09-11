defmodule UserCounterTest do
  use ExUnit.Case, async: true

  describe "UserCounter.Impl" do
    test "Tracks users added by region" do
      users =
        %UserCounter.Impl{}
        |> UserCounter.Impl.put("user1", :europe)
        |> UserCounter.Impl.put("user2", :africa)
        |> UserCounter.Impl.put("user3", :africa)
        |> UserCounter.Impl.put("user4", :asia)
        |> UserCounter.Impl.put("user5", :europe)
        |> UserCounter.Impl.put("user6", :africa)

      assert UserCounter.Impl.count(users, :europe) == 2
      assert UserCounter.Impl.count(users, :africa) == 3
      assert UserCounter.Impl.count(users, :asia) == 1
      assert UserCounter.Impl.count(users, :north_america) == 0
    end

    test "Removes users from other regions when adding to a new one" do
      users =
        %UserCounter.Impl{}
        |> UserCounter.Impl.put("user1", :europe)
        |> UserCounter.Impl.put("user2", :africa)
        |> UserCounter.Impl.put("user1", :africa)
        |> UserCounter.Impl.put("user1", :asia)
        |> UserCounter.Impl.put("user2", :europe)

      assert UserCounter.Impl.count(users) == 2
    end

    test "Drops users" do
      users =
        %UserCounter.Impl{}
        |> UserCounter.Impl.put("user1", :europe)
        |> UserCounter.Impl.put("user2", :africa)
        |> UserCounter.Impl.put("user3", :africa)
        |> UserCounter.Impl.put("user4", :asia)
        |> UserCounter.Impl.put("user5", :europe)
        |> UserCounter.Impl.put("user6", :africa)
        |> UserCounter.Impl.drop("user6")
        |> UserCounter.Impl.drop("user1")
        |> UserCounter.Impl.drop("user4")

      assert UserCounter.Impl.count(users, :europe) == 1
      assert UserCounter.Impl.count(users, :africa) == 2
      assert UserCounter.Impl.empty?(users, :asia)
      assert UserCounter.Impl.empty?(users, :north_america)
    end

    test "Expires old heartbeats" do
      now = DateTime.utc_now()
      then = DateTime.add(now, 60)

      users =
        %UserCounter.Impl{}
        |> UserCounter.Impl.put("user1", :europe)
        |> UserCounter.Impl.put("user2", :africa)
        |> UserCounter.Impl.put("user3", :africa)

      expired = UserCounter.Impl.drop_older_than(users, then)
      assert UserCounter.Impl.empty?(expired)
    end

    test "Counts users across all regions" do
      users =
        %UserCounter.Impl{}
        |> UserCounter.Impl.put("user1", :europe)
        |> UserCounter.Impl.put("user2", :africa)
        |> UserCounter.Impl.put("user3", :africa)
        |> UserCounter.Impl.put("user4", :asia)
        |> UserCounter.Impl.put("user5", :europe)
        |> UserCounter.Impl.put("user6", :africa)

      assert UserCounter.Impl.count(users) == 6

      post_drop_users =
        users
        |> UserCounter.Impl.drop("user6")
        |> UserCounter.Impl.drop("user1")
        |> UserCounter.Impl.drop("user4")

      assert UserCounter.Impl.count(post_drop_users) == 3
    end
  end

  test "UserCounter smoke test" do
    {:ok, genserver} =
      UserCounter.start_link(
        name: :user_counter_smoke_test,
        garbage_collection_ms: 1_000_000,
        max_age_ms: 1_000_000
      )

    assert UserCounter.empty?(genserver)
    assert UserCounter.empty?(genserver, :africa)

    UserCounter.put(genserver, "user1", :north_america)
    UserCounter.put(genserver, "user2", :asia)
    UserCounter.put(genserver, "user3", :africa)
    UserCounter.put(genserver, "user2", :africa)

    assert UserCounter.count(genserver) == 3
    assert UserCounter.count(genserver, :africa) == 2
    refute UserCounter.empty?(genserver)
    refute UserCounter.empty?(genserver, :africa)

    UserCounter.drop(genserver, "user3")
    assert UserCounter.count(genserver) == 2
    assert UserCounter.count(genserver, :africa) == 1
  end

  test "UserCounter garbage collection" do
    {:ok, genserver} =
      UserCounter.start_link(
        name: :garbage_collection_test,
        garbage_collection_ms: 10,
        max_age_ms: 1
      )

    UserCounter.put(genserver, "user1", :north_america)
    :timer.sleep(10)
    assert UserCounter.empty?(genserver)
  end
end
