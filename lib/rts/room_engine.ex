defmodule Rts.RoomEngine do
  use GenServer
  @speed 200/1000 # per seconds.
  @step_duration round(1000/5) # milliseconds


  def start_link(units) do
    GenServer.start_link(__MODULE__, units, name: Rts.RoomEngine)
  end


  def stop(pid) do
    GenServer.call(pid, :stop)
  end


  def move_to(pid, unit_id, [x, y]) do
    GenServer.call(pid, {:move_to, unit_id, [x, y], :os.system_time(:millisecond)})
  end


  def add_unit(pid, unit_id, [x, y], socket_pid) do
    GenServer.call(pid, {:add_unit, unit_id, [x, y], socket_pid})
  end


  def remove_unit(pid, unit_id) do
    GenServer.call(pid, {:remove_unit, unit_id})
  end



  def init(units_as_list) do
    {units, metadatas} = Enum.reduce(units_as_list, {%{}, %{}}, fn (unit, {units, metadatas}) ->
      {
        Map.put(units, unit.id, unit),
        Map.put(metadatas, unit.id, %{socket_pid: nil, step_timer: nil})
      }
    end)

    {:ok, {units, metadatas}}
  end


  def handle_call(:stop, _from, state) do
    {:stop, :normal, state, state}
  end


  def handle_call({:add_unit, unit_id, [x, y], socket_pid}, _from, {units, metadatas}) do
    units = Map.put(units, unit_id, %{id: unit_id, location: [x, y], destination: nil})
    metadatas = Map.put(metadatas, unit_id, %{socket_pid: socket_pid, step_timer: nil})
    {:reply, units, {units, metadatas}}
  end


  def handle_call({:remove_unit, unit_id}, _from, {units, metadatas}) do
    units = Map.delete(units, unit_id)
    metadatas = Map.delete(metadatas, unit_id)
    {:reply, units, {units, metadatas}}
  end


  def handle_call({:move_to, unit_id, [toX, toY], now}, _from, {units, metadatas}) do
    if units[unit_id].location != [toX, toY] do
      if metadatas[unit_id].step_timer do Process.cancel_timer(metadatas[unit_id].step_timer) end
      timer = Process.send_after(self(), {:step, unit_id, now}, @step_duration)
      unit = Map.put(units[unit_id], :destination, [toX, toY])
      metadata = Map.put(metadatas[unit_id], :step_timer, timer)

      {:reply, :ok, {Map.put(units, unit_id, unit), Map.put(metadatas, unit_id, metadata)}}
    else
      {:reply, :ok, {units, metadatas}}
    end
  end


  def handle_info({:step, unit_id, began_step_at}, {units, metadatas}) do
    now = :os.system_time(:millisecond)
    unit = units[unit_id]
    metadata = metadatas[unit_id]
    [fromX, fromY] = unit.location
    [toX, toY] = unit.destination
    duration = now - began_step_at
    distance = distance(fromX, fromY, toX, toY)
    total_duration = distance / @speed
    distance_ratio = min(duration / total_duration, 1)

    {unit, metadata} = if distance_ratio == 1 do
      Process.cancel_timer(metadata.step_timer)
      {
        Map.merge(unit, %{location: [toX, toY], destination: nil}),
        Map.put(metadata, :step_timer, nil)
      }
    else
      x = fromX + (toX - fromX) * duration / total_duration
      y = fromY + (toY - fromY) * duration / total_duration
      timer = Process.send_after(self(), {:step, unit_id, now}, @step_duration)
      {
        Map.put(unit, :location, [x, y]),
        Map.put(metadata, :step_timer, timer)
      }
    end

    Process.send(metadata.socket_pid, {:step, unit}, [])
    {:noreply, {Map.put(units, unit_id, unit), Map.put(metadatas, unit_id, metadata)}}
  end



  defp distance(fromX, fromY, toX, toY) do
    :math.sqrt(:math.pow(toX - fromX, 2) + :math.pow(toY - fromY, 2))
  end
end
