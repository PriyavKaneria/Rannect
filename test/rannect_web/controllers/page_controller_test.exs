defmodule RannectWeb.PageControllerTest do
  use RannectWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) == Routes.user_session_path(conn, :new)
  end
end
