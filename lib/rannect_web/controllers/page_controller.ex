defmodule RannectWeb.PageController do
  use RannectWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def secure(conn, _params) do
    render(conn, "secure.html")
  end
end
