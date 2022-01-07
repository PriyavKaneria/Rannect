defmodule Rannect.Presence do
  use Phoenix.Presence, otp_app: :rannect, pubsub_server: Rannect.PubSub
end
