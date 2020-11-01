defmodule TkServer.Repo do
  use Ecto.Repo,
    otp_app: :tk_server,
    adapter: Ecto.Adapters.Postgres
end
