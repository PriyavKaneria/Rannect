defmodule RannectWeb.TempUsersLive do
  use RannectWeb, :live_view
  # alias Rannect.TempUsers
  # alias Rannect.Rannections.TempChat

  # alias Rannect.PubSub
  # alias Rannect.Presence
  # alias Rannect.Users.Invite

  # @online_user_presence "rannect:online-user-presence"
  # defp invitation_presence(user_id), do: "rannect:invitation-presence#{user_id}"
  # defp chat_presence(user_id), do: "rannect:chat-presence#{user_id}"

  @impl true
  def mount(_params, _session, socket) do
    peer_data = get_connect_info(socket, :peer_data)
    IO.inspect(peer_data)
    # user_struct = Users.get_user_by_session_token(token)
    # user = Map.from_struct(user_struct)

    # sent_invites_users = Users.get_user_sent_invites(user_struct)
    # received_invites_users = Users.get_user_received_invites(user_struct)
    # rannections = Rannections.get_rannections_users(user[:rannections], user[:id])

    # if connected?(socket) do
    #   {:ok, _} =
    #     Presence.track(self(), @online_user_presence, user[:id], %{
    #       username: user[:username],
    #       gender: user[:gender],
    #       age: user[:age],
    #       location: user[:location],
    #       joined_at: :os.system_time(:seconds)
    #     })

    #   Phoenix.PubSub.subscribe(PubSub, @online_user_presence)
    #   Phoenix.PubSub.subscribe(PubSub, invitation_presence(user[:id]))
    #   Phoenix.PubSub.subscribe(PubSub, chat_presence(user[:id]))
    # end

    {
      :ok,
      socket
      # |> assign(:current_user, user)
      # |> assign(:users, %{})
      # |> assign(:user_sent_invites, sent_invites_users)
      # |> assign(:user_received_invites, received_invites_users)
      # |> assign(:rannections, rannections)
      # |> assign(:online_rannections, %{})
      # |> assign(:rannection_chats, %{})
      # |> assign(:chat_changeset, TempChat.changeset(%Chat{}, %{}))
      # |> handle_joins(Presence.list(@online_user_presence))
    }
  end

  # defp handle_joins(socket, joins) do
  #   Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
  #     # Phoenix.PubSub.broadcast_from(
  #     #   PubSub,
  #     #   @online_user_presence,
  #     #   "update_marker"
  #     # )

  #     cond do
  #       String.to_integer(user) in socket.assigns.rannections ->
  #         meta_map = meta |> Map.put(:chatting, false)

  #         assign(
  #           socket,
  #           :online_rannections,
  #           Map.put(socket.assigns.online_rannections, user, meta_map)
  #         )

  #       true ->
  #         assign(socket, :users, Map.put(socket.assigns.users, user, meta))
  #     end
  #   end)
  # end

  # defp handle_leaves(socket, leaves) do
  #   Enum.reduce(leaves, socket, fn {user, _}, socket ->
  #     cond do
  #       String.to_integer(user) in socket.assigns.rannections ->
  #         assign(socket, :online_rannections, Map.delete(socket.assigns.online_rannections, user))

  #       true ->
  #         assign(socket, :users, Map.delete(socket.assigns.users, user))
  #     end
  #   end)
  # end

  # @impl true
  # def handle_info("update_marker", socket) do
  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
  #   {
  #     :noreply,
  #     socket
  #     |> handle_leaves(diff.leaves)
  #     |> handle_joins(diff.joins)
  #   }
  # end

  # @impl true
  # def handle_info("invite_received", socket) do
  #   user_struct = Users.get_user!(socket.assigns.current_user[:id])
  #   received_invites_users = Users.get_user_received_invites(user_struct)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:user_received_invites, received_invites_users)
  #   }
  # end

  # @impl true
  # def handle_info({"invite_accepted", inviteeid}, socket) do
  #   user_struct = Users.get_user!(socket.assigns.current_user[:id])
  #   sent_invites_users = Users.get_user_sent_invites(user_struct)
  #   rannections = Rannections.get_rannections_users(user_struct.rannections, user_struct.id)
  #   invitee = Users.get_user!(inviteeid)
  #   invitee_map = Map.from_struct(invitee) |> Map.put(:chatting, false)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:user_sent_invites, sent_invites_users)
  #     |> assign(:rannections, rannections)
  #     |> assign(:users, Map.delete(socket.assigns.users, inviteeid))
  #     |> assign(
  #       :online_rannections,
  #       Map.put(socket.assigns.online_rannections, inviteeid, invitee_map)
  #     )
  #   }
  # end

  # @impl true
  # def handle_info("invite_rejected", socket) do
  #   user_struct = Users.get_user!(socket.assigns.current_user[:id])
  #   sent_invites_users = Users.get_user_sent_invites(user_struct)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:user_sent_invites, sent_invites_users)
  #   }
  # end

  # @impl true
  # def handle_info({"chat_start", userid}, socket) do
  #   newMap =
  #     socket.assigns.online_rannections
  #     |> Map.put(
  #       Integer.to_string(userid),
  #       Map.put(socket.assigns.online_rannections[Integer.to_string(userid)], :chatting, true)
  #     )

  #   rannection = Rannections.get_rannection_from_ids!(userid, socket.assigns.current_user[:id])

  #   rannection = Rannections.preload_rannection_chats(rannection)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:online_rannections, newMap)
  #     |> assign(
  #       :rannection_chats,
  #       socket.assigns.rannection_chats
  #       |> Map.put(
  #         userid,
  #         rannection.chats
  #       )
  #     )
  #   }
  # end

  # @impl true
  # def handle_info({"chat_message", userid}, socket) do
  #   newMap =
  #     socket.assigns.online_rannections
  #     |> Map.put(
  #       Integer.to_string(userid),
  #       Map.put(socket.assigns.online_rannections[Integer.to_string(userid)], :chatting, true)
  #     )

  #   rannection = Rannections.get_rannection_from_ids!(userid, socket.assigns.current_user[:id])

  #   rannection = Rannections.preload_rannection_chats(rannection)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:online_rannections, newMap)
  #     |> assign(
  #       :rannection_chats,
  #       socket.assigns.rannection_chats
  #       |> Map.put(
  #         userid,
  #         rannection.chats
  #       )
  #     )
  #   }
  # end

  # @impl true
  # def handle_event("invite", params, socket) do
  #   # IO.puts(params["invitee"]<>" "<>params["inviter"])
  #   user_struct = Users.get_user!(socket.assigns.current_user[:id])

  #   case Users.invite_user(%{
  #          :invitee => params["invitee"],
  #          :inviter => params["inviter"]
  #        }) do
  #     {:ok, :ok} ->
  #       Phoenix.PubSub.broadcast(
  #         PubSub,
  #         invitation_presence(params["invitee"]),
  #         "invite_received"
  #       )

  #       sent_invites_users = Users.get_user_sent_invites(user_struct)
  #       received_invites_users = Users.get_user_received_invites(user_struct)

  #       {
  #         :noreply,
  #         socket
  #         |> assign(:user_sent_invites, sent_invites_users)
  #         |> assign(:user_received_invites, received_invites_users)
  #       }

  #     {:error, :already_invited} ->
  #       {:noreply,
  #        socket |> put_flash("error", "You have already sent an invitation to this user")}

  #     {:error, :already_invited_user} ->
  #       {:noreply,
  #        socket |> put_flash("error", "You already have a pending invitation of this user")}
  #   end
  # end

  # @impl true
  # def handle_event("accept_invite", params, socket) do
  #   user = socket.assigns.current_user

  #   Users.accept_invite(params["inviteid"], user[:id])
  #   user_struct = Users.get_user!(user[:id])

  #   Phoenix.PubSub.broadcast(
  #     PubSub,
  #     invitation_presence(params["inviter"]),
  #     {"invite_accepted", user[:id]}
  #   )

  #   inviter = Users.get_user!(params["inviter"])
  #   inviter_map = Map.from_struct(inviter) |> Map.put(:chatting, false)

  #   received_invites_users = Users.get_user_received_invites(user_struct)
  #   rannections = Rannections.get_rannections_users(user_struct.rannections, user[:id])

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:user_received_invites, received_invites_users)
  #     |> assign(:rannections, rannections)
  #     |> assign(:users, Map.delete(socket.assigns.users, params["inviter"]))
  #     |> assign(
  #       :online_rannections,
  #       Map.put(socket.assigns.online_rannections, params["inviter"], inviter_map)
  #     )
  #   }
  # end

  # @impl true
  # def handle_event("reject_invite", params, socket) do
  #   user = socket.assigns.current_user
  #   user_struct = Users.get_user!(user[:id])

  #   Users.reject_invite(params["inviteid"], user[:id])

  #   Phoenix.PubSub.broadcast(
  #     PubSub,
  #     invitation_presence(params["inviter"]),
  #     "invite_rejected"
  #   )

  #   received_invites_users = Users.get_user_received_invites(user_struct)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:user_received_invites, received_invites_users)
  #   }
  # end

  # @impl true
  # def handle_event("chat", params, socket) do
  #   rannection =
  #     Rannections.get_rannection_from_ids!(params["userid"], socket.assigns.current_user[:id])

  #   rannection = Rannections.preload_rannection_chats(rannection)

  #   Phoenix.PubSub.broadcast(
  #     PubSub,
  #     chat_presence(params["userid"]),
  #     {"chat_start", socket.assigns.current_user[:id]}
  #   )

  #   {
  #     :noreply,
  #     socket
  #     |> assign(
  #       :online_rannections,
  #       socket.assigns.online_rannections
  #       |> Map.put(
  #         params["userid"],
  #         Map.put(socket.assigns.online_rannections[params["userid"]], :chatting, true)
  #       )
  #     )
  #     |> assign(
  #       :rannection_chats,
  #       socket.assigns.rannection_chats
  #       |> Map.put(
  #         String.to_integer(params["userid"]),
  #         rannection.chats
  #       )
  #     )
  #   }
  # end

  # @impl true
  # def handle_event("close_chat", params, socket) do
  #   newMap =
  #     socket.assigns.online_rannections
  #     |> Map.put(
  #       params["userid"],
  #       Map.put(socket.assigns.online_rannections[params["userid"]], :chatting, false)
  #     )

  #   {
  #     :noreply,
  #     socket
  #     |> assign(:online_rannections, newMap)
  #   }
  # end

  # @impl true
  # def handle_event("validate_message", params, socket) do
  #   changeset =
  #     %Chat{}
  #     |> Chat.changeset(params["chat"])

  #   {:noreply,
  #    socket
  #    |> assign(:chat_changeset, changeset)}
  # end

  # @impl true
  # def handle_event("send_message", params, socket) do
  #   rannection =
  #     Rannections.get_rannection_from_ids!(
  #       params["chat"]["userid"],
  #       socket.assigns.current_user[:id]
  #     )

  #   rannection
  #   |> Rannections.create_chat(%{
  #     message: params["chat"]["message"],
  #     sender: socket.assigns.current_user[:id]
  #   })

  #   Phoenix.PubSub.broadcast(
  #     PubSub,
  #     chat_presence(params["chat"]["userid"]),
  #     {"chat_message", socket.assigns.current_user[:id]}
  #   )

  #   rannection = Rannections.preload_rannection_chats(rannection)

  #   {
  #     :noreply,
  #     socket
  #     |> assign(
  #       :rannection_chats,
  #       socket.assigns.rannection_chats
  #       |> Map.put(
  #         String.to_integer(params["chat"]["userid"]),
  #         rannection.chats
  #       )
  #     )
  #     |> assign(:chat_changeset, Chat.changeset(%Chat{}, %{}))
  #   }
  # end
end
