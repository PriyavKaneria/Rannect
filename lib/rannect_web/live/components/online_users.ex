defmodule RannectWeb.Components.OnlineUsers do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
    <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      <%= for {user_id, user} <- @users do %>
        <%= if String.to_integer(user_id) != @current_user[:id] do %>
          <li class="col-span-1 flex flex-col text-center bg-white rounded-lg shadow divide-y divide-gray-200 hover:shadow-xl duration-600">
            <div class="flex-1 flex flex-col p-8">
              <img class="w-32 h-32 flex-shrink-0 mx-auto rounded-full" src="https://picsum.photos/300" alt="">
              <h3 class="mt-6 text-gray-900 text-sm font-medium capitalize"><%= user[:username] %></h3>
              <dl class="mt-1 flex-grow flex flex-col justify-between">
                <dt class="sr-only">Age</dt>
                <dd class="text-gray-500 text-sm"><%= user[:age] %></dd>
                <dd class="text-gray-500 text-sm"><%= "#{user[:location]["city"]}, #{user[:location]["state"]} - #{user[:location]["country"]}" %></dd>
                <dt class="sr-only">Gender</dt>
                <dd class="mt-3">
                  <span class="px-2 py-1 text-green-800 text-xs font-medium bg-green-100 rounded-full capitalize"><%= user[:gender] %></span>
                </dd>
              </dl>
            </div>
            <div>
              <div class="-mt-px flex divide-x divide-gray-200">
                <div class="w-0 flex-1 flex">
                  <div href="mailto:janecooper@example.com" class="relative -mr-px w-0 flex-1 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium border border-transparent rounded-bl-lg hover:text-gray-500">
                    <!-- Heroicon name: solid/mail -->
                    <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                      <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                    </svg>
                    <span class="ml-3">Make Friend</span>
                  </div>
                </div>
                <div class="-ml-px w-0 flex-1 flex" phx-click="invite" phx-value-inviter={@current_user[:id]} phx-value-invitee={user_id}>
                  <div class="relative w-0 flex-1 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium border border-transparent rounded-br-lg hover:text-gray-500">
                    <!-- Heroicon name: solid/phone -->
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M18 5v8a2 2 0 01-2 2h-5l-5 4v-4H4a2 2 0 01-2-2V5a2 2 0 012-2h12a2 2 0 012 2zM7 8H5v2h2V8zm2 0h2v2H9V8zm6 0h-2v2h2V8z" clip-rule="evenodd" />
                    </svg>
                    <span class="ml-3">Request Chat</span>
                  </div>
                </div>
              </div>
            </div>
          </li>
        <% end %>
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
