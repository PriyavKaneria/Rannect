defmodule RannectWeb.Components.UserForm do
  use RannectWeb, :live_component

  alias RannectWeb.ErrorHelpers

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
