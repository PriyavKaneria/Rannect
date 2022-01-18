defmodule RannectWeb.UsersLive do
  use RannectWeb, :live_view
  alias Rannect.Users
  alias Rannect.Rannections

  alias Rannect.Presence
  alias Rannect.PubSub
  # alias Rannect.Users.Invite

  @online_user_presence "rannect:online-user-presence"
  defp invitation_presence(user_id), do: "rannect:invitation-presence#{user_id}"

  @impl true
  def mount(_params, %{"user_token" => token}, socket) do
    user_struct = Users.get_user_by_session_token(token)
    user = Map.from_struct(user_struct)

    sent_invites_users = Users.get_user_sent_invites(user_struct)
    received_invites_users = Users.get_user_received_invites(user_struct)
    rannections = Rannections.get_rannections_users(user[:rannections], user[:id])

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @online_user_presence, user[:id], %{
          username: user[:username],
          gender: user[:gender],
          age: user[:age],
          location: user[:location],
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @online_user_presence)
      Phoenix.PubSub.subscribe(PubSub, invitation_presence(user[:id]))
    end

    {
      :ok,
      socket
      |> assign(:current_user, user)
      |> assign(:users, %{})
      |> assign(:user_sent_invites, sent_invites_users)
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:rannections, rannections)
      |> assign(:online_rannections, %{})
      |> handle_joins(Presence.list(@online_user_presence))
    }
  end

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

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
    }
  end

  @impl true
  def handle_info({"invite_accepted", inviteeid}, socket) do
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_user_sent_invites(user_struct)
    rannections = Rannections.get_rannections_users(user_struct.rannections, user_struct.id)
    invitee = Users.get_user!(inviteeid)

    {
      :noreply,
      socket
      |> assign(:user_sent_invites, sent_invites_users)
      |> assign(:rannections, rannections)
      |> assign(:users, Map.delete(socket.assigns.users, inviteeid))
      |> assign(
        :online_rannections,
        Map.put(socket.assigns.online_rannections, inviteeid, invitee)
      )
    }
  end

  @impl true
  def handle_info("invite_rejected", socket) do
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_user_sent_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_sent_invites, sent_invites_users)
    }
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      cond do
        String.to_integer(user) in socket.assigns.rannections ->
          assign(
            socket,
            :online_rannections,
            Map.put(socket.assigns.online_rannections, user, meta)
          )

        true ->
          assign(socket, :users, Map.put(socket.assigns.users, user, meta))
      end
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      cond do
        String.to_integer(user) in socket.assigns.rannections ->
          assign(socket, :online_rannections, Map.delete(socket.assigns.online_rannections, user))

        true ->
          assign(socket, :users, Map.delete(socket.assigns.users, user))
      end
    end)
  end

  @impl true
  def handle_event("invite", params, socket) do
    # IO.puts(params["invitee"]<>" "<>params["inviter"])
    user_struct = Users.get_user!(socket.assigns.current_user[:id])

    case Users.invite_user(%{
           :invitee => params["invitee"],
           :inviter => params["inviter"]
         }) do
      {:ok, :ok} ->
        Phoenix.PubSub.broadcast(
          PubSub,
          invitation_presence(params["invitee"]),
          "invite_received"
        )

        sent_invites_users = Users.get_user_sent_invites(user_struct)
        received_invites_users = Users.get_user_received_invites(user_struct)

        {
          :noreply,
          socket
          |> assign(:user_sent_invites, sent_invites_users)
          |> assign(:user_received_invites, received_invites_users)
        }

      {:error, :already_invited} ->
        {:noreply,
         socket |> put_flash("error", "You have already sent an invitation to this user")}

      {:error, :already_invited_user} ->
        {:noreply,
         socket |> put_flash("error", "You already have a pending invitation of this user")}

      {:error, :error} ->
        {:noreply, socket |> put_flash("error", "An error occurred")}
    end
  end

  @impl true
  def handle_event("accept_invite", params, socket) do
    user = socket.assigns.current_user

    Users.accept_invite(params["inviteid"], user[:id])
    user_struct = Users.get_user!(user[:id])

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      {"invite_accepted", user[:id]}
    )

    inviter = Users.get_user!(params["inviter"])

    received_invites_users = Users.get_user_received_invites(user_struct)
    rannections = Rannections.get_rannections_users(user_struct.rannections, user[:id])

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
      |> assign(:rannections, rannections)
      |> assign(:users, Map.delete(socket.assigns.users, params["inviter"]))
      |> assign(
        :online_rannections,
        Map.put(socket.assigns.online_rannections, params["inviter"], inviter)
      )
    }
  end

  @impl true
  def handle_event("reject_invite", params, socket) do
    user = socket.assigns.current_user
    user_struct = Users.get_user!(user[:id])

    Users.reject_invite(params["inviteid"], user[:id])

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
end
