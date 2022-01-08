defmodule RannectWeb.Components.OnlineUsers do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap">
      <%= for {user_id, user} <- @users do %>
          <div>
            <%= if String.to_integer(user_id) == @current_user[:id] do %>
              <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:username] %> (me) </span>
            <% else %>
              <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:username] %></span>
            <% end %>
            <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:gender] %> </span>
            <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:age] %> </span>
            <span class="text-xs bg-green-200 rounded px-2 py-1"><%= user[:location][:state] %> </span>
          </div>
      <% end %>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
