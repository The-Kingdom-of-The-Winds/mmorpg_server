defmodule Game.Component.Broadcast do
  defstruct [:type, :message]

  def add_status(entity_id, message) do
    Game.Component.new(:broadcast, entity_id, %__MODULE__{type: :status, message: message})
  end
end
