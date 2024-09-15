defmodule Timey.MainChannel do
  use Timey, :channel

  @impl true
  def join("tcpish:" <> prefix, _payload, socket) do
    if prefix == socket.assigns.prefix do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
end
