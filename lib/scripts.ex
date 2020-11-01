defmodule Scripts do
  def run(script, args) do
    Task.Supervisor.start_child(Scripts.Supervisor, fn ->
      script.(args)
    end)
  end
end
