defmodule RannectWeb.TempUsersLive do
  use RannectWeb, :live_view
  alias Rannect.Users.TempUser
  alias Rannect.Users
  alias Rannect.Rannections.TempChat

  alias Rannect.PubSub
  alias Rannect.Presence
  # alias Rannect.Users.Invite
  # alias Rannect.Users.TempInvite

  @online_user_presence "rannect:online-user-presence"
  defp invitation_presence(user_id), do: "rannect:invitation-presence#{user_id}"
  defp chat_presence(user_id), do: "rannect:chat-presence#{user_id}"

  @impl true
  def mount(_params, _session, socket) do
    ip =
      get_connect_info(socket, :x_headers) |> RemoteIp.from() |> Tuple.to_list() |> Enum.join(".")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(PubSub, @online_user_presence)
    end

    # IO.inspect(Presence.list(@online_user_presence))

    {
      :ok,
      socket
      |> assign(:user_ip, ip)
      |> assign(:current_user, %{:username => "", :id => ""})
      |> assign(:users, %{})
      |> assign(:user_changeset, TempUser.changeset(%TempUser{}, %{}))
      |> assign(:user_sent_invites, [])
      |> assign(:user_sent_temp_invites, [])
      |> assign(:user_received_invites, %{})
      |> assign(:user_received_temp_invites, %{})
      |> assign(:accepted_invites, %{})
      # |> assign(:rannections, rannections)
      # |> assign(:online_rannections, %{})
      |> assign(:chats, %{})
      |> assign(:chat_changeset, TempChat.changeset(%TempChat{}, %{}))
      |> handle_joins(Presence.list(@online_user_presence))
    }
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns.current_user.username != "" do
      Users.delete_temporary_users(socket.assigns.current_user.id)
    end
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(
        socket,
        :users,
        socket.assigns.users
        |> Map.put(user, meta |> Map.put(:type, :temp) |> Map.put(:chatting, false))
      )
    end)
  end

  defp handle_leaves(socket, leaves, joins) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      if !is_nil(user) && !Map.has_key?(joins, user) &&
           user == socket.assigns.current_user.id do
        Users.delete_temporary_users(user)
      end

      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end

  @impl true
  def handle_info("update_marker", socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    # IO.inspect(diff)

    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves, diff.joins)
      |> handle_joins(diff.joins)
    }
  end

  @impl true
  def handle_info("invite_received", socket) do
    user_struct = Users.get_temp_user!(socket.assigns.current_user[:id])
    received_invites_users = Users.get_temp_user_received_invites(user_struct)
    received_temp_invites_users = Users.get_temp_user_received_temp_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:user_received_temp_invites, received_temp_invites_users)
    }
  end

  @impl true
  def handle_info({"invite_accepted", inviteeid}, socket) do
    user_struct = Users.get_temp_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_temp_user_sent_invites(user_struct)
    sent_temp_invites_users = Users.get_temp_user_sent_temp_invites(user_struct)

    accepted_invites = Users.get_temp_user_accepted_invites(user_struct)
    # rannections = Rannections.get_rannections_users(user_struct.rannections, user_struct.id)
    invitee = Users.get_temp_user!(String.to_integer(inviteeid))
    invitee_map = Map.from_struct(invitee) |> Map.put(:chatting, false) |> Map.put(:type, :temp)

    # IO.puts("invitee_map")
    # IO.inspect(accepted_invites)

    {
      :noreply,
      socket
      |> assign(:user_sent_invites, sent_invites_users)
      |> assign(:user_sent_temp_invites, sent_temp_invites_users)
      # |> assign(:rannections, rannections)
      |> assign(
        :users,
        Map.replace!(socket.assigns.users, inviteeid, invitee_map)
      )
      |> assign(:accepted_invites, accepted_invites)
    }
  end

  @impl true
  def handle_info("invite_rejected", socket) do
    user_struct = Users.get_temp_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_temp_user_sent_invites(user_struct)
    sent_temp_invites_users = Users.get_temp_user_sent_temp_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_sent_invites, sent_invites_users)
      |> assign(:user_sent_temp_invites, sent_temp_invites_users)
    }
  end

  @impl true
  def handle_info({"chat_start", userid, inviteid}, socket) do
    invite = Users.get_temp_invite!(inviteid)
    invite_with_chats = Users.preload_invite_temp_chats(invite)

    {
      :noreply,
      socket
      |> assign(
        :users,
        socket.assigns.users
        |> Map.put(
          Integer.to_string(userid),
          Map.put(socket.assigns.users[Integer.to_string(userid)], :chatting, true)
        )
      )
      |> assign(
        :chats,
        socket.assigns.chats
        |> Map.put(
          userid,
          invite_with_chats.temp_chats
        )
      )
    }
  end

  @impl true
  def handle_info({"chat_message", userid, inviteid}, socket) do
    invite = Users.get_temp_invite!(inviteid)
    invite_with_chats = Users.preload_invite_temp_chats(invite)

    {
      :noreply,
      socket
      |> assign(
        :users,
        socket.assigns.users
        |> Map.put(
          Integer.to_string(userid),
          Map.put(socket.assigns.users[Integer.to_string(userid)], :chatting, true)
        )
      )
      |> assign(
        :chats,
        socket.assigns.chats
        |> Map.put(
          userid,
          invite_with_chats.temp_chats
        )
      )
    }
  end

  @impl true
  def handle_event("validate_username", params, socket) do
    changeset =
      %TempUser{}
      |> TempUser.changeset(params["temp_user"])

    # IO.inspect(changeset)

    {:noreply,
     socket
     |> assign(:user_changeset, changeset)}
  end

  @impl true
  def handle_event("set_username", params, socket) do
    IO.inspect(params)

    case Users.register_temporary_user(params["temp_user"]) do
      {:ok, user} ->
        IO.puts("here?")
        sent_invites_users = Users.get_temp_user_sent_invites(user)
        sent_temp_invites_users = Users.get_temp_user_sent_temp_invites(user)
        received_invites_users = Users.get_temp_user_received_invites(user)
        received_temp_invites_users = Users.get_temp_user_received_temp_invites(user)

        if connected?(socket) do
          {:ok, _} =
            Presence.track(self(), @online_user_presence, user.id, %{
              username: user.username,
              location: user.location,
              joined_at: :os.system_time(:seconds)
            })

          Phoenix.PubSub.subscribe(PubSub, invitation_presence(user.id))
          Phoenix.PubSub.subscribe(PubSub, chat_presence(user.id))
        end

        # IO.inspect(Map.from_struct(user))

        {
          :noreply,
          socket
          |> assign(:current_user, Map.from_struct(user |> Map.put(:type, :temp)))
          |> assign(:user_sent_invites, sent_invites_users)
          |> assign(:user_sent_temp_invites, sent_temp_invites_users)
          |> assign(:user_received_invites, received_invites_users)
          |> assign(:user_received_temp_invites, received_temp_invites_users)
        }

      {:error, changeset} ->
        {
          :noreply,
          socket
          |> assign(:user_changeset, changeset)
        }
    end
  end

  @impl true
  def handle_event("update_user_location", _params, socket) do
    # IO.inspect(params)
    # IO.inspect(socket.assigns.users)
    user = Users.get_temp_user!(Integer.to_string(socket.assigns.current_user.id))

    Presence.update(self(), @online_user_presence, user.id, %{
      username: user.username,
      location: user.location,
      joined_at: :os.system_time(:seconds)
    })

    {:noreply,
     socket
     |> assign(
       :users,
       Map.put(
         socket.assigns.users,
         Integer.to_string(user.id),
         Map.from_struct(user)
       )
     )}
  end

  @impl true
  def handle_event("invite", params, socket) do
    # IO.puts(params["invitee"]<>" "<>params["inviter"])
    user_struct = Users.get_temp_user!(socket.assigns.current_user[:id])

    case params["type"] do
      "temp" ->
        case Users.temp_invite_temp_user(%{
               :temp_invitee => params["invitee"],
               :temp_inviter => params["inviter"]
             }) do
          {:ok, :ok} ->
            Phoenix.PubSub.broadcast(
              PubSub,
              invitation_presence(params["invitee"]),
              "invite_received"
            )

            sent_invites_users = Users.get_temp_user_sent_invites(user_struct)
            sent_temp_invites_users = Users.get_temp_user_sent_temp_invites(user_struct)
            received_invites_users = Users.get_temp_user_received_invites(user_struct)
            received_temp_invites_users = Users.get_temp_user_received_temp_invites(user_struct)

            IO.inspect(received_invites_users)
            IO.inspect(received_temp_invites_users)

            {
              :noreply,
              socket
              |> assign(:user_sent_invites, sent_invites_users)
              |> assign(:user_sent_temp_invites, sent_temp_invites_users)
              |> assign(:user_received_invites, received_invites_users)
              |> assign(:user_received_temp_invites, received_temp_invites_users)
            }

          {:error, :already_invited} ->
            {:noreply,
             socket |> put_flash("error", "You have already sent an invitation to this user")}

          {:error, :already_invited_user} ->
            {:noreply,
             socket |> put_flash("error", "You already have a pending invitation of this user")}
        end

      "user" ->
        case Users.temp_invite_user(%{
               :invitee => params["invitee"],
               :temp_inviter => params["inviter"]
             }) do
          {:ok, :ok} ->
            Phoenix.PubSub.broadcast(
              PubSub,
              invitation_presence(params["invitee"]),
              "invite_received"
            )

            sent_invites_users = Users.get_temp_user_sent_invites(user_struct)
            sent_temp_invites_users = Users.get_temp_user_sent_temp_invites(user_struct)
            received_invites_users = Users.get_temp_user_received_invites(user_struct)
            received_temp_invites_users = Users.get_temp_user_received_temp_invites(user_struct)

            {
              :noreply,
              socket
              |> assign(:user_sent_invites, sent_invites_users)
              |> assign(:user_sent_temp_invites, sent_temp_invites_users)
              |> assign(:user_received_invites, received_invites_users)
              |> assign(:user_received_temp_invites, received_temp_invites_users)
            }

          {:error, :already_invited} ->
            {:noreply,
             socket |> put_flash("error", "You have already sent an invitation to this user")}

          {:error, :already_invited_user} ->
            {:noreply,
             socket |> put_flash("error", "You already have a pending invitation of this user")}
        end
    end
  end

  @impl true
  def handle_event("accept_invite", params, socket) do
    user = socket.assigns.current_user
    Users.accept_temp_invite(params["inviteid"], user[:id])
    user_struct = Users.get_temp_user!(user[:id])

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      {"invite_accepted", Integer.to_string(user[:id])}
    )

    inviter = Users.get_temp_user!(params["inviter"])
    inviter_map = Map.from_struct(inviter) |> Map.put(:chatting, false) |> Map.put(:type, :temp)

    received_invites_users = Users.get_temp_user_received_invites(user_struct)
    received_temp_invites_users = Users.get_temp_user_received_temp_invites(user_struct)

    accepted_invites = Users.get_temp_user_accepted_invites(user_struct)
    # rannections = Rannections.get_rannections_users(user_struct.rannections, user[:id])

    # IO.puts("accepted_invites")
    # IO.inspect(accepted_invites)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:user_received_temp_invites, received_temp_invites_users)
      # |> assign(:rannections, rannections)
      |> assign(
        :users,
        Map.replace!(socket.assigns.users, params["inviter"], inviter_map)
      )
      |> assign(:accepted_invites, accepted_invites)
    }
  end

  @impl true
  def handle_event("reject_invite", params, socket) do
    user = socket.assigns.current_user
    user_struct = Users.get_temp_user!(user[:id])

    Users.reject_temp_invite(params["inviteid"], user[:id])

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      "invite_rejected"
    )

    received_invites_users = Users.get_temp_user_received_invites(user_struct)
    received_temp_invites_users = Users.get_temp_user_received_temp_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:user_received_temp_invites, received_temp_invites_users)
    }
  end

  @impl true
  def handle_event("chat", params, socket) do
    invite = Users.get_temp_invite!(params["inviteid"])

    invite_with_chats = Users.preload_invite_temp_chats(invite)

    Phoenix.PubSub.broadcast(
      PubSub,
      chat_presence(params["userid"]),
      {"chat_start", socket.assigns.current_user[:id], params["inviteid"]}
    )

    {
      :noreply,
      socket
      |> assign(
        :users,
        socket.assigns.users
        |> Map.put(
          params["userid"],
          Map.put(socket.assigns.users[params["userid"]], :chatting, true)
        )
      )
      |> assign(
        :chats,
        socket.assigns.chats
        |> Map.put(
          String.to_integer(params["userid"]),
          invite_with_chats.temp_chats
        )
      )
    }
  end

  @impl true
  def handle_event("close_chat", params, socket) do
    {
      :noreply,
      socket
      |> assign(
        :users,
        socket.assigns.users
        |> Map.put(
          params["userid"],
          Map.put(socket.assigns.users[params["userid"]], :chatting, false)
        )
      )
    }
  end

  @impl true
  def handle_event("validate_message", params, socket) do
    changeset =
      %TempChat{}
      |> TempChat.changeset(params["temp_chat"])

    {:noreply,
     socket
     |> assign(:chat_changeset, changeset)}
  end

  @impl true
  def handle_event("send_message", params, socket) do
    invite = Users.get_temp_invite!(params["temp_chat"]["inviteid"])

    invite
    |> Users.create_temp_chat(%{
      message: params["temp_chat"]["message"],
      temp_sender: socket.assigns.current_user[:id]
    })

    Phoenix.PubSub.broadcast(
      PubSub,
      chat_presence(params["temp_chat"]["userid"]),
      {"chat_message", socket.assigns.current_user[:id], params["temp_chat"]["inviteid"]}
    )

    invite_with_chats = Users.preload_invite_temp_chats(invite)

    {
      :noreply,
      socket
      |> assign(
        :chats,
        socket.assigns.chats
        |> Map.put(
          String.to_integer(params["temp_chat"]["userid"]),
          invite_with_chats.temp_chats
        )
      )
      |> assign(:chat_changeset, TempChat.changeset(%TempChat{}, %{}))
    }
  end
end
