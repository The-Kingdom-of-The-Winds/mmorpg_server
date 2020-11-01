defmodule Game.System.CameraRender do
  use GenServer

  alias Game.Component.{Camera}

  def start_link(_, _opts \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(_) do
    {:ok, %{}}
  end

  def tick(tick) do
    GenServer.call(__MODULE__, {:tick, {tick}})
  end

  def render_cameras([camera | cameras], new) do
    render_cameras(cameras, [render(camera) | new])
  end

  def render_cameras([], new), do: new

  def render({_, camera}) do
    positions = :ets.tab2list(:position)

    camera
    |> filter_in_frame(positions)
    |> render_entities()
    |> Enum.into(%{})
    |> Client.render(:camera, camera.client_id)
  end

  def render_entities([in_frame | rest]) do
    [render_entity(in_frame) | render_entities(rest)]
  end

  def render_entities([]), do: []

  def render_entity({entity_id, pos}) do
    {entity_id,
     [
       {:position, pos},
       {:transform_position, Game.Component.lookup(:transform_position, entity_id)},
       {:damage_entity, Game.Component.lookup(:damage_entity, entity_id)},
       {:sound, Game.Component.lookup(:sound, entity_id)},
       {:animation, Game.Component.lookup(:animation, entity_id)},
       {:look, Game.Component.lookup(:look, entity_id)},
       {:action, Game.Component.lookup(:action, entity_id)},
       {:talking, Game.Component.lookup(:talking, entity_id)},
       {:name, Game.Component.lookup(:name, entity_id)}
     ]}
  end

  def filter_in_frame(camera, positions) do
    Enum.filter(positions, fn {_, pos} -> within_camera(pos, camera) end)
  end

  def within_camera(%{instance_id: i, x: x, y: y}, %Camera{instance_id: ci, x0: x0, y0: y0, x1: x1, y1: y1}) do
    if i == ci and y >= y0 and y <= y1 and x >= x0 and x <= x1 do
      true
    else
      false
    end
  end

  def handle_call({:tick, {_tick}}, _from, state) do
    cameras = :ets.tab2list(:camera)
    render_cameras(cameras, [])

    {:reply, :ok, state}
  end
end
