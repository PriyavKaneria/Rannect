defmodule RannectWeb.Components.OnlineUsers do
  use RannectWeb, :live_component

  def render(assigns) do
    ~H"""
    <ul role="list" class="flex flex-wrap w-full duration-200">
      <%= for {user_id, user} <- @users do %>
        <%= if String.to_integer(user_id) != @current_user[:id] do %>
          <li class="col-span-1 flex flex-col text-center bg-white rounded-lg shadow divide-y divide-gray-200 hover:shadow-xl duration-600">
            <div class="flex-1 flex flex-col p-5">
              <img class="w-16 h-16 flex-shrink-0 mx-auto rounded-full" src="https://picsum.photos/300" alt="">
              <h3 class="mt-6 text-gray-900 text-sm font-medium capitalize"><%= user[:username] %></h3>
              <dl class="mt-1 flex-grow flex flex-col justify-between">
                <dt class="sr-only">Age</dt>
                <dd class="text-gray-500 text-sm"><%= user[:age] %></dd>
                <dd class="text-gray-500 text-sm flex space-x-3">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                  </svg>
                  <%= "#{user[:location]["city"]}, #{user[:location]["state"]} - #{user[:location]["country"]}" %>
                </dd>
                <dt class="sr-only">Gender</dt>
                <dd class="mt-3">
                  <span class="px-2 py-1 text-green-800 text-xs font-medium bg-green-100 rounded-full capitalize"><%= user[:gender] %></span>
                </dd>
              </dl>
            </div>
            <div>
                <%= if @type == "users" do %>
                  <%= if Enum.find_value(@sent, false, fn x -> x[:id] == String.to_integer(user_id) end)==true do %>
                    <div class="flex-1 flex px-1 text-green-200-contrast hover:text-green-300-contrast bg-green-200 hover:bg-green-300 rounded-b rounded-sm">
                      <div class="relative px-1 flex-1 inline-flex items-center justify-center py-4 text-sm font-medium border border-transparent rounded-br-lg">
                        <!-- Heroicon name: solid/phone -->
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.707l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clip-rule="evenodd" />
                        </svg>
                        <span class="ml-3 whitespace-nowrap">Invitation sent</span>
                      </div>
                    </div>
                  <% else %>
                    <%= if Enum.find_value(@received, false, fn x -> x[:id] == String.to_integer(user_id) end)==true do %>
                      <div class="flex-1 flex px-1 text-blue-200-contrast hover:text-blue-300-contrast bg-blue-200 hover:bg-blue-300 rounded-b rounded-sm">
                        <div class="relative px-1 flex-1 inline-flex items-center justify-center py-4 text-sm font-medium border border-transparent rounded-br-lg">
                          <!-- Heroicon name: solid/phone -->
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v3.586L7.707 9.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L11 10.586V7z" clip-rule="evenodd" />
                          </svg>
                          <span class="ml-3 whitespace-nowrap">Invitation Received</span>
                        </div>
                      </div>
                    <% else %>
                      <div class="flex-1 flex px-1 text-cyan-200-contrast hover:text-cyan-300-contrast bg-cyan-200 hover:bg-cyan-300 rounded-b rounded-sm" phx-click="invite" phx-value-inviter={@current_user[:id]} phx-value-invitee={user_id}>
                        <div class="relative px-1 flex-1 inline-flex items-center justify-center py-4 text-sm font-medium border border-transparent rounded-br-lg">
                          <!-- Heroicon name: solid/phone -->
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                          </svg>
                          <span class="ml-3 whitespace-nowrap">Invite to Chat</span>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>
                <%= if @type == "rannections" do %>
                  <div class="flex-1 flex px-1 text-indigo-200-contrast hover:text-indigo-300-contrast bg-indigo-200 hover:bg-indigo-300 rounded-b rounded-sm" phx-click="chat">
                    <div class="relative px-1 flex-1 inline-flex items-center justify-center py-4 text-sm font-medium border border-transparent rounded-br-lg">
                      <!-- Heroicon name: solid/phone -->
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M18 5v8a2 2 0 01-2 2h-5l-5 4v-4H4a2 2 0 01-2-2V5a2 2 0 012-2h12a2 2 0 012 2zM7 8H5v2h2V8zm2 0h2v2H9V8zm6 0h-2v2h2V8z" clip-rule="evenodd" />
                      </svg>
                      <span class="ml-3 whitespace-nowrap">Chat</span>
                    </div>
                  </div>
                <% end %>
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
