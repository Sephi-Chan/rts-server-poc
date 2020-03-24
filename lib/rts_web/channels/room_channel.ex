defmodule RtsWeb.RoomChannel do
  use Phoenix.Channel


  def join("rooms:any", _message, socket) do
    units = Rts.RoomEngine.add_unit(Rts.RoomEngine, socket.assigns.player_id, [Enum.random(20..380), Enum.random(20..380)], self())
    RtsWeb.Endpoint.broadcast!("rooms:any", "player_joined", units[socket.assigns.player_id])
    {:ok, units, socket}
  end


  def terminate(_reason, socket) do
    Rts.RoomEngine.remove_unit(Rts.RoomEngine, socket.assigns.player_id)
    RtsWeb.Endpoint.broadcast!("rooms:any", "player_left", %{unit_id: socket.assigns.player_id})
  end


  def handle_in("move_to", %{"x" => x, "y" => y}, socket) do
    Rts.RoomEngine.move_to(Rts.RoomEngine, socket.assigns.player_id, [x, y])
    {:noreply, socket}
  end


  def handle_info({:step, unit}, socket) do
    RtsWeb.Endpoint.broadcast!("rooms:any", "unit_stepped", unit)
    {:noreply, socket}
  end
end
