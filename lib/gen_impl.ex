defmodule GenImpl do
  @moduledoc "Simple utilities for avoiding boilerplate in a GenServer implementation."

  @doc """
  If your GenServer is a thin wrapper around a struct, you can make its handle_call/3 and/or
  handle_cast/2 implementations be "just this."

  Use it like this:

      GenImpl.apply_call(&MyGenServer.Impl.update/3, %MyGenServer.Impl{}, [arg2, arg3])

  This will result in a call that looks like:

      MyGenServer.Impl.update(%MyGenServer.Impl{}, arg2, arg3)

  Supports operations that:

  - Update the state struct
  - Return a result tuple, or even just :error
  - Query the state and return a value

  ...but not operations that both modify the state *and* query something.
  """
  def apply_call(impl_function, impl_struct, additional_args)
      when is_struct(impl_struct) and is_function(impl_function) and is_list(additional_args) do
    case apply(impl_function, [impl_struct | additional_args]) do
      updated_state when is_struct(updated_state) -> {:reply, :ok, updated_state}
      {:ok, updated_state} when is_struct(updated_state) -> {:reply, :ok, updated_state}
      :error -> {:reply, :error, impl_struct}
      {:error, explanation} = e when is_binary(explanation) -> {:reply, e, impl_struct}
      return_value -> {:reply, return_value, impl_struct}
    end
  end
end
