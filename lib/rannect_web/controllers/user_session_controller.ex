defmodule RannectWeb.UserSessionController do
  use RannectWeb, :controller

  alias Rannect.Users
  alias RannectWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    with {:ok, user} <- Users.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      {:error, :bad_username_or_password} ->
        render(conn, "new.html", error_message: "Invalid email or password")

      {:error, :not_confirmed} ->
        user = Users.get_user_by_email(email)

        Users.deliver_user_confirmation_instructions(
          user,
          &Routes.user_confirmation_url(conn, :edit, &1)
        )

        render(conn, "new.html",
          error_message:
            "Please confirm your email before signing in.  An email confirmation link has been sent to you."
        )
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
