# gitea
Elixir interface with Gitea server (REST API + Git)

## Install Gitea Elixir dependency

## Define configurations

In your application define the following configuration:

```elixir
config :gitea, git_temp_dir_path: "/",
               gitea_server_url: "gitea-server.fly.dev",
```

# Git userflow

- create remote repository
- clone repository
- create a new local branch
- read file on local repository
- update and write file on local repository
- commit change on local repository
- push to remote repository

Other:
- delete a remote repo
- read file from remote repository
- convert markdown to html via Gitea
