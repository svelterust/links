defmodule Links.Repo do
  use Ecto.Repo,
    otp_app: :links,
    adapter: Ecto.Adapters.SQLite3
end
