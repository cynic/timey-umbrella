defmodule Timey.Mailer do
  use Swoosh.Mailer, otp_app: :timey, adapter: Swoosh.Adapters.Local
end
