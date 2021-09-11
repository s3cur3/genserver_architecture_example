defmodule UserCounter.Impl do
  @moduledoc "'Private' implementation for UserCounter"

  @regions [:north_america, :south_america, :africa, :europe, :asia, :australia]
  @default_regions_to_users Map.new(@regions, fn region -> {region, MapSet.new()} end)

  defstruct region_to_users: @default_regions_to_users, heartbeats: Map.new()

  @doc """
  Associates the user with the given region. Removes them from whatever region they were
  previously associated with, if any.
  """
  def put(%{region_to_users: regions_to_users, heartbeats: heartbeats}, user_id, region)
      when region in @regions do
    other_regions = Enum.filter(@regions, &(&1 != region))

    {_, added_to_new_region} =
      regions_to_users
      |> remove_from_regions(user_id, other_regions)
      |> Map.get_and_update!(region, fn users ->
        {users, MapSet.put(users, user_id)}
      end)

    updated_heartbeats = Map.put(heartbeats, user_id, DateTime.utc_now())

    %__MODULE__{region_to_users: added_to_new_region, heartbeats: updated_heartbeats}
  end

  @doc """
  Removes a user from the data set, if they were present at all.
  """
  def drop(%{region_to_users: regions_to_users, heartbeats: heartbeats}, user_id) do
    updated_regions = remove_from_regions(regions_to_users, user_id, @regions)
    updated_heartbeats = Map.delete(heartbeats, user_id)
    %__MODULE__{region_to_users: updated_regions, heartbeats: updated_heartbeats}
  end

  @doc """
  Removes all users that were most recently "put" before the specified datetime.
  Users without a "heartbeat" expire and are not counted toward future totals.
  """
  def drop_older_than(%{region_to_users: regions_to_users, heartbeats: heartbeats}, cutoff_datetime) do
    IO.inspect(heartbeats, label: "heartbeats", limit: :infinity)
    {expired_heartbeats, live_heartbeats} =
        Enum.split_with(heartbeats, fn {_user_id, last_heartbeat} ->
          DateTime.compare(cutoff_datetime, last_heartbeat) == :gt
        end)

    old_user_ids = Enum.map(expired_heartbeats, &elem(&1, 0))

    updated_regions_to_users =
      Enum.reduce(old_user_ids, regions_to_users, fn old_user_id, acc ->
        remove_from_regions(acc, old_user_id, @regions)
      end)

    %__MODULE__{region_to_users: updated_regions_to_users, heartbeats: Map.new(live_heartbeats)}
  end

  @doc """
  The number of users logged in to the current region.
  """
  def count(%{region_to_users: regions_to_users}, region) when region in @regions do
    MapSet.size(regions_to_users[region])
  end

  @doc """
  The total number of users logged in to any region.
  """
  def count(%{heartbeats: heartbeats}) do
    map_size(heartbeats)
  end

  def empty?(%{region_to_users: regions_to_users}, region) when region in @regions do
    Enum.empty?(regions_to_users[region])
  end

  def empty?(%{heartbeats: heartbeats}) do
    Enum.empty?(heartbeats)
  end

  defp remove_from_regions(regions_to_users, user_id, regions) do
    Enum.reduce(regions, regions_to_users, fn remove_from_region, acc ->
      {_, updated_region_to_users} =
        Map.get_and_update!(acc, remove_from_region, fn users ->
          {users, MapSet.delete(users, user_id)}
        end)

      updated_region_to_users
    end)
  end
end

defmodule UserCounter do
  @moduledoc "Tracks the number of users logged in to our web app, storing them by region"
  use GenServer

  def start_link(opts \\ [name: __MODULE__, garbage_collection_ms: 1_000, max_age_ms: 60_000]) do
    server_name = Keyword.get(opts, :name, __MODULE__)
    garbage_collection_ms = Keyword.get(opts, :garbage_collection_ms, 1_000)
    max_age_ms = Keyword.get(opts, :max_age_ms, 60_000)

    # Our state is a tuple of {state struct, timer for dropping old heartbeats}
    GenServer.start_link(__MODULE__, {garbage_collection_ms, max_age_ms}, name: server_name)
  end

  def put(server, user_id, region), do: GenServer.call(server, {:apply, &UserCounter.Impl.put/3, [user_id, region]})
  def drop(server, user_id), do: GenServer.call(server, {:apply, &UserCounter.Impl.drop/2, [user_id]})

  def count(server), do: GenServer.call(server, {:apply, &UserCounter.Impl.count/1, []})
  def count(server, region), do: GenServer.call(server, {:apply, &UserCounter.Impl.count/2, [region]})

  def empty?(server), do: GenServer.call(server, {:apply, &UserCounter.Impl.empty?/1, []})
  def empty?(server, region), do: GenServer.call(server, {:apply, &UserCounter.Impl.empty?/2, [region]})

  ############## GenServer Implementation ################
  @impl GenServer
  def init({garbage_collection_ms, max_age_ms}) do
    {:ok, _} = :timer.send_interval(garbage_collection_ms, self(), {:garbage_collect, max_age_ms})
    {:ok, %UserCounter.Impl{}}
  end

  @impl GenServer
  def handle_call({:apply, implementation_function, args}, _from, state) do
    GenImpl.apply_call(implementation_function, state, args)
  end

  @impl GenServer
  def handle_info({:garbage_collect, max_age_ms}, state) do
    cutoff_time = DateTime.add(DateTime.utc_now(), max_age_ms, :millisecond)
    {:noreply, UserCounter.Impl.drop_older_than(state, cutoff_time)}
  end
end