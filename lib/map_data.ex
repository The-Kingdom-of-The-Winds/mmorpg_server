defmodule MapData do
  @moduledoc """
  Reads and parses map binary data from disk. This is only the raw map tile data and does not represent a
  room/map/instance in the game.
  """

  require Logger

  @map_path "/var/lib/maps"

  def load(filename) do
    case :ets.lookup(:map_cache, {filename, :tiles}) do
      [] ->
        {:ok, fd} = File.open(filename)
        # Read the first 4 bytes, which is the width and height of the map
        <<width::16, height::16, tiles::binary>> = IO.binread(fd, :all)
        File.close(fd)

        :ets.insert(:map_cache, {{filename, :tiles}, width, height, tiles})
        :ets.insert(:map_cache, {{filename, :metadata}, width, height})

        {:ok, width, height, tiles}

      [{_filename, width, height, tiles}] ->
        {:ok, width, height, tiles}
    end
  end

  def metadata(map_id) do
    with [{_, width, height}] <- :ets.lookup(:map_cache, {map_id, :metadata}) do
      {:ok, width, height}
    else
      ####
      _ ->
        nil
    end
  end

  def read_tiles(map_id, opts) when is_integer(map_id) do
    Integer.to_string(map_id) |> read_tiles(opts)
  end

  def read_tiles(map_id, from: {from_x, from_y}, to: {to_x, to_y}) do
    map_id = String.pad_leading(map_id, 6, "0")
    {:ok, w, h, data} = MapData.load(@map_path <> "TK#{map_id}.map")
    read_tile_bytes(data, {w, h}, from: {from_x, from_y}, to: {to_x, to_y})
  end

  @doc """
  Reads a subset of the map data as a diagonal window from an x,y to an x,y and returns the raw tile data.
  """
  def read_tile_bytes(<<tiles::binary>>, {width, _height}, from: {from_x, from_y}, to: {to_x, to_y}) do
    from_y..to_y
    |> Enum.map(fn y -> {(width * y + from_x) * 6, to_x * 6 - from_x * 6} end)
    |> Enum.map(fn {offset, bytes} ->
      <<_::size(offset)-bytes, data::size(bytes)-bytes, _::binary>> = tiles
      data
    end)
  end
end
