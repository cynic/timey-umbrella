defmodule Timey.PageController do
  require Logger
  use Timey, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    token = Phoenix.Token.sign(conn, "ZDtplvkLkLh8@NPwtH^qjifVyKkh9&zDhO8ervm3#ERag", conn.assigns.current_user.id)
    render(conn, :home, layout: false, user_token: token, email: conn.assigns.current_user.email)
  end

  def favicon(conn, _params) do
    # return a 301 redirect to /images/logo.svg
    redirect(conn, to: "/images/logo.svg")
  end
end
