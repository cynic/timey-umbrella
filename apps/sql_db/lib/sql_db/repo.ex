defmodule SqlDb.Repo do
  use Ecto.Repo,
    otp_app: :sql_db,
    adapter: Ecto.Adapters.Postgres
end
