defmodule Timey.UserSocket do
  require Logger
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "tcpish:*", Timey.MainChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token, "prefix" => prefix}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "ZDtplvkLkLh8@NPwtH^qjifVyKkh9&zDhO8ervm3#ERag", token, max_age: 1_209_600) do
      {:ok, user_id} ->
        Logger.info("verified user with id #{user_id}")
        # user = SqlDb.Accounts.get_user!(user_id)
        # {:ok, assign(socket, :user_email, user.email) |> assign(:user_id, user_id)}
        case IdPrefixApp.mark_active(prefix) do
          :ok ->
            {:ok, assign(socket, :prefix, prefix) |> assign(:user_id, user_id)}
          {:error, reason} ->
            Logger.error("could not set active prefix #{prefix} for user #{user_id}: #{reason}")
            :error
        end
      {:error, _reason} ->
        :error
    end
  end

  # Socket IDs are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.Timey.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
