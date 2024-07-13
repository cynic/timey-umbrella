defmodule Timey.MainChannel do
  use Timey, :channel

  @impl true
  def join("tcpish:" <> user_email, _payload, socket) do
    if user_email == socket.assigns.user_email do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
end
