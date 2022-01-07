defmodule RannectWeb.Components.OnlineUsers do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
      <%= for {user_id, user} <- @users do %>
        <%= if user_id == @current_user[:id] do %>
          <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:username] %> (me)</span>
        <% else %>
          <span class="text-xs bg-blue-200 rounded px-2 py-1"><%= user[:username] %></span>
        <% end %>
      <% end %>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
