defmodule RannectWeb.UsersLive do
  use RannectWeb, :live_view
  alias Rannect.Users

  alias Rannect.Presence
  alias Rannect.PubSub
  alias Rannect.Users.Invite

  @online_user_presence "rannect:online-user-presence"
  defp invitation_presence(user_id), do: "rannect:invitation-presence#{user_id}"

  @impl true
  def mount(_params, %{"user_token" => token}, socket) do
    user_struct = Users.get_user_by_session_token(token)
    user = Map.from_struct(user_struct)

    sent_invites_users = Users.get_user_sent_invites(user_struct)
    received_invites_users = Users.get_user_received_invites(user_struct)

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
      |> handle_joins(Presence.list(@online_user_presence))
    }
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    IO.puts("Presence diff")

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
  def handle_info("invite_accepted", socket) do
    user_struct = Users.get_user!(socket.assigns.current_user[:id])
    sent_invites_users = Users.get_user_sent_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_sent_invites, sent_invites_users)
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
    # IO.inspect(socket)

    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
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
        {:noreply, socket |> put_flash("error", "You have already sent an invitation to this user")}

      {:error, :already_invited_user} ->
        {:noreply, socket |> put_flash("error", "You already have a pending invitation of this user")}

      {:error, :error} ->
        {:noreply, socket |> put_flash("error", "An error occurred")}
    end
  end

  @impl true
  def handle_event("accept_invite", params, socket) do
    user = socket.assigns.current_user
    user_struct = Users.get_user!(user[:id])

    Users.accept_invite(params["inviteid"], user[:id])

    Phoenix.PubSub.broadcast(
      PubSub,
      invitation_presence(params["inviter"]),
      "invite_accepted"
    )

    received_invites_users = Users.get_user_received_invites(user_struct)

    {
      :noreply,
      socket
      |> assign(:user_received_invites, received_invites_users)
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
