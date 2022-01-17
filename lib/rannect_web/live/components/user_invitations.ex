defmodule RannectWeb.Components.UserInvitations do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
    <ul role="list" class="flex flex-col">
      <%= for user <- @users do %>
        <li class="flex flex-row space-x-2">
          <span><%= user[:username] %></span>
          <button phx-click="accept_invite" phx-value-inviteid={user[:inviteid]} phx-value-inviter={user[:id]}>
            Accept
          </button>
          <button phx-click="reject_invite" phx-value-inviteid={user[:inviteid]} phx-value-inviter={user[:id]}>
            Reject
          </button>
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
