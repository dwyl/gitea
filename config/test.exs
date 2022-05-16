import Config

config :gitea,
  gitea_server_url: "gitea-server.fly.dev",
  git_temp_dir_path: System.get_env("GIT_TEMP_DIR_PATH") || "temp"
