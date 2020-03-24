defmodule RtsWeb.PageController do
  use RtsWeb, :controller
  plug :ensure_valid_name when action in [:game]


  def home(conn, _params) do
    render(conn, "home.html")
  end


  def game(conn, _params) do
    render(conn, "game.html")
  end


  defp ensure_valid_name(conn, params) do
    if String.match?(conn.params["name"] || "", ~r/^[[:alnum:]]{3,8}$/) do
      conn
    else
      conn |> halt |> redirect(to: "/")
    end
  end
end
