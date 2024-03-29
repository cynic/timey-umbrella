defmodule Timely.Repo do
  use Ecto.Repo,
    otp_app: :timely,
    adapter: Ecto.Adapters.Postgres
end
