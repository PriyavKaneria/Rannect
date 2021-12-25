defmodule Rannect.Repo do
  use Ecto.Repo,
    otp_app: :rannect,
    adapter: Ecto.Adapters.Postgres
end
