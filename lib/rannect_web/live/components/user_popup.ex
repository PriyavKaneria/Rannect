defmodule RannectWeb.Components.UserPopup do
  use RannectWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
