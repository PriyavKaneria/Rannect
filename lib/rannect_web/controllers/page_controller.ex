defmodule RannectWeb.PageController do
  use RannectWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
