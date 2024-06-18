defmodule Timey.Repo do
  use Ecto.Repo,
    otp_app: :timey,
    adapter: Ecto.Adapters.Postgres
end
