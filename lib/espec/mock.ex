defmodule ESpec.Mock do
  @moduledoc """
  Defines 'expect` function to mock function using 'meck'.
  :meck.new is called with options :non_strict and :passthrough.
  The :non_strict allows create mocks for modules and functions that do not exist.
  The :passthroug options allow call other functions in the module.
  Information about mock is stored in the ':espec_mock_agent' set.
  Mock are being unloaded after each example.
  """
  @agent_name :espec_mock_agent

  @doc """
  Creates new mock using :meck. The :meck options are [:non_strict, :passthrough]
  Stores mock in agent to remove it after spec.
  """
  def expect(module, name, function) do
    try do
      :meck.new(module, [:non_strict, :passthrough])
    rescue
      error in [ErlangError] ->
        case error do
          %ErlangError{original: {:already_started, _pid}} -> :ok
          _ -> raise error
        end
    end
    :meck.expect(module, name, function)
    agent_put({module, self})
  end

  @doc "Unloads modules at the end of example"
  def unload do
    modules = agent_get(self) |> Enum.map(fn{m, _p} -> m end)
    :meck.unload(modules)
    agent_del(self)
  end

  @doc "Starts Agent to save mocked modules."
  def start_agent, do: Agent.start_link(fn -> HashSet.new end, name: @agent_name)
  
  @doc "Stops Agent"
  def stop_agent, do: Agent.stop(@agent_name)

  defp agent_get(pid) do
    Agent.get(@agent_name, &(&1))
    |> Enum.filter fn{_m, p} -> p == pid end
  end

  defp agent_del(pid) do
    new_set = Agent.get(@agent_name, &(&1))
    |> Enum.reduce(HashSet.new, fn({m, p}, acc) -> 
      if p != pid, do: HashSet.put(acc, {m, p}), else: acc
    end)
    Agent.update(@agent_name, fn(_state) -> new_set end)
  end

  defp agent_put(key), do: Agent.update(@agent_name, &(Set.put(&1, key)))
end
