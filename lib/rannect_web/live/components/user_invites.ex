defmodule RannectWeb.Components.UserInvites do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
    <ul role="list" class="flex flex-col">
      <%= for user <- @users do %>
        <li class="">
          <%= user[:username] %>
        </li>
      <% end %>
    </ul>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
