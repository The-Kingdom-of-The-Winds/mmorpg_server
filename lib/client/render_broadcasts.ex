defmodule Client.RenderBroadcasts do
  import TkServer.Commands, only: [add_broadcast: 1]

  def render([broadcast | rest]) do
    [add_broadcast(type: broadcast.type, message: broadcast.message) | render(rest)]
  end

  def render([]), do: []
end
