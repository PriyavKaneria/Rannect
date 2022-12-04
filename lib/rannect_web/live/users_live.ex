defmodule RannectWeb.UsersLive do
  use RannectWeb, :live_view
  alias Rannect.Users
  # alias Rannect.Rannections
  alias Rannect.Rannections.Chat

  alias Rannect.PubSub
  alias Rannect.Presence
  # alias Rannect.Users.Invite

  @online_user_presence "rannect:online-user-presence"
  defp invitation_presence(user_id), do: "rannect:invitation-presence#{user_id}"
  defp chat_presence(user_id), do: "rannect:chat-presence#{user_id}"

  @impl true
  def mount(_params, %{"user_token" => token}, socket) do
    user_struct = Users.get_user_by_session_token(token)
    user = Map.from_struct(user_struct)

    sent_invites_users = Users.get_user_sent_invites(user_struct)
    received_invites_users = Users.get_user_received_invites(user_struct)
    accepted_invites = Users.get_user_accepted_invites(user_struct)
    rannections = Users.get_rannections_users(user.rannections)

    # IO.inspect(rannections)

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @online_user_presence, user[:id], %{
          username: user[:username],
          gender: user[:gender],
          age: user[:age],
          location: user[:location],
          joined_at: :os.system_time(:seconds),
          type: :user
        })

      Phoenix.PubSub.subscribe(PubSub, @online_user_presence)
      Phoenix.PubSub.subscribe(PubSub, invitation_presence(user[:id]))
      Phoenix.PubSub.subscribe(PubSub, chat_presence(user[:id]))
    end

    {
      :ok,
      socket
      |> assign(:current_user, user |> Map.put(:type, :user))
      |> assign(:users, %{})
      |> assign(:user_sent_invites, sent_invites_users)
      |> assign(:user_sent_temp_invites, [])
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:user_received_temp_invites, %{})
      |> assign(:accepted_invites, accepted_invites)
      |> assign(:rannections, rannections)
      # |> assign(:online_rannections, %{})
      |> assign(:chats, %{})
      |> assign(:chat_changeset, Chat.changeset(%Chat{}, %{}))
      |> handle_joins(Presence.list(@online_user_presence))
    }
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      # IO.inspect(user)
      # IO.inspect(meta)
      # Phoenix.PubSub.broadcast_from(
      #   PubSub,
      #   @online_user_presence,
      #   "update_marker"
      # )

      assign(
        socket,
        :users,
        socket.assigns.users
        |> Map.put(user, meta |> Map.put(:chatting, false))
      )
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end

  # @impl true
  # def handle_info("update_marker", socket) do
  #   {:noreply, socket}
  # end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  @impl true
  def handle_info("invite_received", socket) do
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    received_invites_users = Users.get_user_received_invites(user_struct)
    received_temp_invites_users = Users.get_user_received_temp_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:user_received_temp_invites, received_temp_invites_users)
    }
  end

  @impl true
  def handle_info({"invite_accepted", invitertype, inviteeid}, socket) do
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_user_sent_invites(user_struct)
    sent_temp_invites_users = Users.get_user_sent_temp_invites(user_struct)

    accepted_invites = Users.get_user_accepted_invites(user_struct)
    # rannections = Rannections.get_rannections_users(user_struct.rannections, user_struct.id)

    invitee =
      case invitertype do
        "user" ->
          Users.get_user!(String.to_integer(inviteeid))

        "temp" ->
          Users.get_temp_user!(String.to_integer(inviteeid))

        _ ->
          raise "Invalid invite type"
      end

    invitee_map = Map.from_struct(invitee) |> Map.put(:chatting, false) |> Map.put(:type, :user)

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
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_user_sent_invites(user_struct)
    sent_temp_invites_users = Users.get_user_sent_temp_invites(user_struct)

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
    invite_with_chats = Users.preload_invite_chats(invite)

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
          invite_with_chats.chats
        )
      )
    }
  end

  @impl true
  def handle_info({"chat_message", userid, inviteid}, socket) do
    invite = Users.get_temp_invite!(inviteid)
    invite_with_chats = Users.preload_invite_chats(invite)

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
          invite_with_chats.chats
        )
      )
    }
  end

  @impl true
  def handle_event("update_user_location", _params, socket) do
    # IO.inspect(params)
    # IO.inspect(socket.assigns.users)
    user = Users.get_user!(Integer.to_string(socket.assigns.current_user.id))

    Presence.update(self(), @online_user_presence, user.id, %{
      username: user.username,
      location: user.location,
      joined_at: :os.system_time(:seconds),
      type: :user
    })

    {:noreply,
     socket
     |> assign(
       :users,
       Map.put(
         socket.assigns.users,
         Integer.to_string(user.id),
         Map.from_struct(user |> Map.put(:type, :user))
       )
     )}
  end

  @impl true
  def handle_event("invite", params, socket) do
    # IO.puts(params["invitee"]<>" "<>params["inviter"])
    user_struct = Users.get_user!(socket.assigns.current_user[:id])

    case params["type"] do
      "temp" ->
        case Users.user_invite_temp(%{
               :user_temp_receiver => params["invitee"],
               :user_temp_sender => params["inviter"]
             }) do
          {:ok, :ok} ->
            Phoenix.PubSub.broadcast(
              PubSub,
              invitation_presence(params["invitee"]),
              "invite_received"
            )

            sent_invites_users = Users.get_user_sent_invites(user_struct)
            sent_temp_invites_users = Users.get_user_sent_temp_invites(user_struct)
            received_invites_users = Users.get_user_received_invites(user_struct)
            received_temp_invites_users = Users.get_user_received_temp_invites(user_struct)

            # IO.inspect(received_invites_users)
            # IO.inspect(received_temp_invites_users)

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
        case Users.user_invite_user(%{
               :user_user_receiver => params["invitee"],
               :user_user_sender => params["inviter"]
             }) do
          {:ok, :ok} ->
            Phoenix.PubSub.broadcast(
              PubSub,
              invitation_presence(params["invitee"]),
              "invite_received"
            )

            sent_invites_users = Users.get_user_sent_invites(user_struct)
            sent_temp_invites_users = Users.get_user_sent_temp_invites(user_struct)
            received_invites_users = Users.get_user_received_invites(user_struct)
            received_temp_invites_users = Users.get_user_received_temp_invites(user_struct)

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

    case params["inviteetype"] do
      "user" ->
        Users.accept_invite(params["inviteid"], :user_user, user[:id])

      "temp" ->
        Users.accept_invite(params["inviteid"], :temp_user, user[:id])

      _ ->
        raise "Invite Type invalid"
    end

    user_struct = Users.get_user!(user[:id])

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      {"invite_accepted", params["inviteetype"], params["inviter"]}
    )

    inviter =
      case params["inviteetype"] do
        "user" ->
          Users.get_user!(params["inviter"])

        "temp" ->
          Users.get_temp_user!(params["inviter"])

        _ ->
          raise "Invite Type invalid"
      end

    inviter_map =
      Map.from_struct(inviter)
      |> Map.put(:chatting, false)
      |> Map.put(:type, String.to_atom(params["inviteetype"]))

    received_invites_users = Users.get_user_received_invites(user_struct)
    received_temp_invites_users = Users.get_user_received_temp_invites(user_struct)

    accepted_invites = Users.get_user_accepted_invites(user_struct)
    # rannections = Rannections.get_rannections_users(user_struct.rannections, user[:id])

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
    user_struct = Users.get_user!(user[:id])

    case params["inviteetype"] do
      "user" ->
        Users.reject_invite(params["inviteid"], :user_user, user[:id])

      "temp" ->
        Users.reject_invite(params["inviteid"], :temp_user, user[:id])

      _ ->
        raise "Invite Type invalid"
    end

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      "invite_rejected"
    )

    received_invites_users = Users.get_user_received_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
    }
  end

  @impl true
  def handle_event("chat", params, socket) do
    invite = Users.get_invite!(params["inviteid"])

    invite_with_chats = Users.preload_invite_chats(invite)

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
          invite_with_chats.chats
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
      %Chat{}
      |> Chat.changeset(params["chat"])

    {:noreply,
     socket
     |> assign(:chat_changeset, changeset)}
  end

  @impl true
  def handle_event("send_message", params, socket) do
    invite = Users.get_invite!(params["chat"]["inviteid"])

    invite
    |> Users.create_chat(%{
      message: params["chat"]["message"],
      sender: socket.assigns.current_user[:id]
    })

    Phoenix.PubSub.broadcast(
      PubSub,
      chat_presence(params["chat"]["userid"]),
      {"chat_message", socket.assigns.current_user[:id], params["chat"]["inviteid"]}
    )

    invite_with_chats = Users.preload_invite_chats(invite)

    {
      :noreply,
      socket
      |> assign(
        :chats,
        socket.assigns.chats
        |> Map.put(
          String.to_integer(params["chat"]["userid"]),
          invite_with_chats.chats
        )
      )
      |> assign(:chat_changeset, Chat.changeset(%Chat{}, %{}))
    }
  end

  @impl true
  def handle_event("add_rannection", params, socket) do
    case Users.add_rannection(socket.assigns.current_user[:id], params["userid"]) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> assign(
            :rannections,
            socket.assigns.rannections
            |> Map.put(
              Integer.to_string(socket.assigns.current_user[:id]),
              Users.get_user!(params["userid"])
            )
          )
        }

      _ ->
        raise "Add Rannection failed"
    end
  end

  @impl true
  def handle_event("remove_rannection", params, socket) do
    case Users.remove_rannection(socket.assigns.current_user[:id], params["userid"]) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> assign(
            :rannections,
            socket.assigns.rannections |> Map.delete(params["userid"])
          )
        }

      _ ->
        raise "Remove Rannection failed"
    end
  end
end
