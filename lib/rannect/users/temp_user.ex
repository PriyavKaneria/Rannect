defmodule Rannect.Users.TempUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.Invite
  alias Rannect.Users.TempInvite
  # alias Rannect.Rannections.Rannection

  schema "temp_users" do
    field :username, :string
    field :ip_address, :string, required: true
    field :location, :map, default: %{}

    has_many :sent_invites, Invite, foreign_key: :inviter
    has_many :sent_temp_invites, TempInvite, foreign_key: :temp_inviter
    has_many :received_invites, Invite, foreign_key: :invitee
    has_many :received_temp_invites, TempInvite, foreign_key: :temp_invitee

    timestamps()
  end

  def key_to_atom(map) do
    Enum.reduce(map, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      # String.to_existing_atom saves us from overloading the VM by
      # creating too many atoms. It'll always succeed because all the fields
      # in the database already exist as atoms at runtime.
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  @doc """
  A user changeset for registration.
  
  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  
  ## Options
  
    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :ip_address])
    |> validate_required([:username, :ip_address])
    |> validate_length(:username, min: 3, max: 32)
    |> unique_constraint(:username,
      name: :temp_users_username_index,
      message: "Username already taken ☹️"
    )
    |> unique_constraint(:ip_address,
      name: :temp_users_ip_address_index,
      message: "Same device already using as Guest"
    )
  end

  @doc """
  Sets the location of the user.
  """
  def location_changeset(user, location) do
    # change(user, location: location)
    user
    |> cast(%{location: location}, [:location])
  end
end
