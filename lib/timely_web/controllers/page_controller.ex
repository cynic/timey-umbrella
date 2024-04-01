defmodule TimelyWeb.PageController do
  use TimelyWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def favicon(conn, _params) do
    # return a 301 redirect to /images/logo.svg
    redirect(conn, to: "/images/logo.svg")
  end
end
