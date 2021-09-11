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

  def put(server, user_id, region), do: GenServer.call(server, {&UserCounter.Impl.put/3, [user_id, region]})
  def drop(server, user_id), do: GenServer.call(server, {&UserCounter.Impl.drop/2, [user_id]})

  def count(server), do: GenServer.call(server, {&UserCounter.Impl.count/1, []})
  def count(server, region), do: GenServer.call(server, {&UserCounter.Impl.count/2, [region]})

  def empty?(server), do: GenServer.call(server, {&UserCounter.Impl.empty?/1, []})
  def empty?(server, region), do: GenServer.call(server, {&UserCounter.Impl.empty?/2, [region]})

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

  # Nobody ever said the first element of your tuple has to be an atom...
  @impl GenServer
  def handle_call({implementation_function, args}, _from, state) when is_function(implementation_function) do
    GenImpl.apply_call(implementation_function, state, args)
  end

  @impl GenServer
  def handle_info({:garbage_collect, max_age_ms}, state) do
    cutoff_time = DateTime.add(DateTime.utc_now(), max_age_ms, :millisecond)
    {:noreply, UserCounter.Impl.drop_older_than(state, cutoff_time)}
  end
end