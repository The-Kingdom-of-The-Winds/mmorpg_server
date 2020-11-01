import Config

config :tk_server, ecto_repos: [TkServer.Repo]

config :tk_server, TkServer.Repo,
  database: "tkserver",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5432"
