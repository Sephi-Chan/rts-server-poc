defmodule RoomEngineTest do
  use ExUnit.Case


  test "Can move unit to destination" do
    {:ok, pid} = Rts.RoomEngine.start_link([%{id: "Corwin", location: {0, 200}}])
    Rts.RoomEngine.move_to(pid, "Corwin", {200, 0})
    Rts.RoomEngine.stop(pid)
  end


  test "Can handle many units" do
    {:ok, _pid} = Rts.RoomEngine.start_link([
      %{id: "Corwin", location: {0, 200}},
      %{id: "Mandor", location: {0, 200}}
    ])
  end
end
