<div align="center">

<img alt="Gitea" src="https://user-images.githubusercontent.com/194400/168781665-a52d2c00-8b69-44ae-a10a-7bd1c3932020.svg" width="240"/>

**`Elixir`** interface with a **`Gitea`** instance.

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/dwyl/gitea/Elixir%20CI?label=build&style=flat-square)](https://github.com/dwyl/gitea/actions/workflows/ci.yml)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/gitea/main.svg?style=flat-square)](http://codecov.io/github/dwyl/gitea?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/gitea?color=brightgreen&style=flat-square)](https://hex.pm/packages/gitea)
[![docs](https://img.shields.io/badge/docs-maintained-brightgreen?style=flat-square)](https://hexdocs.pm/gitea/api-reference.html)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/gitea/issues)
[![HitCount](http://hits.dwyl.com/dwyl/gitea.svg)](http://hits.dwyl.com/dwyl/gitea)

<!-- uncomment when service is working ...
[![Libraries.io dependency status](https://img.shields.io/librariesio/release/hex/gitea?logoColor=brightgreen&style=flat-square)](https://libraries.io/hex/gitea)
[![Inline docs](http://inch-ci.org/github/dwyl/auth.svg?branch=master&style=flat-square)](http://inch-ci.org/github/dwyl/auth)
-->

</div>

# _Why?_ 💡

We needed an _easy_ way to interact
with a **`Gitea`** (GitHub Backup) **Server**
from our **`Elixir/Phoenix`** App.

> **Note**: We were _briefly_ tempted
> to write this code _inside_ the Phoenix App
> that uses it, <br />
> however we quickly realized
> that having it **_separate_** was better
> for **_testability/maintainability_**. <br />
> Having a _separate_ module enforces a
> [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)
> with a strong "API contract". <br />
> This way we know this package is well-tested both end-to-end and with
> [Test Doubles](https://martinfowler.com/bliki/TestDouble.html),
> documented and maintained. <br />
> It can be used and _extended independently_
> of any `Elixir/Phoenix` app
> and is treated
> as a logically separate/independent entity
> with a clear interface.

# _What_? 📦

A library for interacting with **`gitea`** (`git`)
from `Elixir` apps. <br />

Hopefully this diagram explains
how we use the package in our stack:

<div align="center">

![Phoenix-Gitea-Infra-dagram](https://user-images.githubusercontent.com/194400/168793143-3cf67409-6330-425e-a0b9-fff4c64e3e7f.png)

</div>

For the complete list of functions,
please see the docs:
[hexdocs.pm/**gitea**](https://hexdocs.pm/gitea)
📚

# Who? 👤

This library is used by our (`Phoenix`) GitHub Backup App. <br />
If you find it helpful for your project,
please ⭐ on GitHub:
[github.com/dwyl/**gitea**](https://github.com/dwyl/gitea)

## _How_? 💻

There are a couple of steps to get this working in your project.
It should only take **`2 mins`** if you already have your
**`Gitea` Server** _deployed_ (_or access to an existing instance_).

> If you want to read a **step-by-step complete beginner's guide**
> to getting **`gitea`** working in a **`Phoenix`** App,
> please see:
> [github.com/dwyl/**gitea-demo**](https://github.com/dwyl/gitea-demo)

<br />

## Install ⬇️

Install the package from [hex.pm](https://hex.pm/docs/publish),
by adding `gitea` to the list of dependencies in your `mix.exs` file:

```elixir
def deps do
  [
    {:gitea, "~> 1.1.1"},
  ]
end
```

Once you've saved the `mix.exs` file,
run:

```sh
mix deps.get
```

<br />

## Config ⚙️

If you are writing tests for a function that relies on `gitea` (and you should!)
then you can add the following line to your `config/test.exs` file:

```sh
config :gitea, mock: true
```

<br />

## _Setup_ 🔧

For `gitea` to work
in your `Elixir/Phoenix` App,
you will need to have
a few environment variables defined.

There are **2 _required_**
and **1 _optional_** variables.
Make sure you read through the next section
to determine if you _need_ the _optional_ ones.

### _Required_ Environment Variables

> See: [`.env_sample`](https://github.com/dwyl/gitea/blob/main/.env_sample)

There are **2 _required_** environment variables:

1. `GITEA_URL` - the domain where your Gitea Server is deployed,
   without the protocol, e.g: `gitea-server.fly.dev`

2. `GITEA_ACCESS_TOKEN` - the REST API Access Token <br />
   See: https://github.com/dwyl/gitea-server#7-create-access-token-api-key

### _Optional_ Environment Variables

#### `GIT_TEMP_DIR_PATH`

If you want to specify a directory where
you want to clone `git` repos to, <br />
create a `GIT_TEMP_DIR_PATH` environment variable.
e.g:

```sh
export GIT_TEMP_DIR_PATH=tmp
```

> **Note**: the directory **must _already_ exist**.<br />
> If it doesn't already exist, create it. <br />
> e.g:
> `mkdir tmp` followed by `cp -r test-repo tmp`

<br />

## Usage

If you just want to _read_
the contents of a file hosted on
a `Gitea` Server,
write code similar to this:

```elixir
org_name = "myorg"
repo_name = "public-repo"
file_name = "README.md"
{:ok, %HTTPoison.Response{ body: response_body}} =
  Gitea.remote_read_raw(org_name, repo_name,file_name)
# use the response_body (plaintext data)
```

This is exactly the use-case presented in our demo app:
[dwyl/**gitea-demo**#4-create-function](https://github.com/dwyl/gitea-demo#4-create-function-to-interact-with-gitea-repo)

<br />

Here's a more real-world scenario
in 7 easy steps:

### 1. _Create_ a New Repo on the Gitea Server

```elixir
# Define the params for the remote repository:
org_name = "myorg"
repo_name = "repo-name"
private = false # boolean
# Create the repo!
Gitea.remote_repo_create(org_name, repo_name, private)
```

### 2. _Clone_ the Repo

```elixir
git_repo_url = Gitea.Helpers.remote_url_ssh(org_name, repo_name)
Gitea.clone(git_repo_url)
```

> Provided you have setup the environment variables,
> and your `Elixir/Phoenix` App has write access to the filesystem,
> this should work without any issues.
> We haven't seen any in practice.
> But if you get stuck at this step,
> [open an issue](https://github.com/dwyl/gitea/issues)

### 3. _Read_ the Contents of _Local_ (Cloned) File

Once you've cloned the `Git` Repo from the `Gitea` Server
to the local filesystem of the `Elixir/Phoenix` App,
you can read any file inside it.

```elixir
org_name = "myorg"
repo_name = "public-repo"
file_name = "README.md"
{:ok, text} = Gitea.local_file_read(org_name, repo_name, file_name)
```

### 4. _Write_ to a File

```elixir
file_name = "README.md"
text = "Your README.md text"
Gitea.local_file_write_text(org_name, repo_name, file_name, text)
```

This will create a new file if it doesn't already exist.

### 5. _Commit_ Changes

```elixir
{:ok, msg} = Gitea.commit(org_name, repo_name,
  %{message: "your commit message", full_name: "Al Ex", email: "alex@dwyl.co"})
```

### 6. _Push_ to `Gitea` Remote

```elixir
# Push to Gitea Server this one is easy.
Gitea.push(org_name, repo_name)
```

### 7. _Confirm_ the File was Update on the Remote repo

```elixir
# Confirm the README.md was updated on the remote repo:
{:ok, %HTTPoison.Response{ body: response_body}} =
    Gitea.remote_read_raw(org_name, repo_name, file_name)
"Your README.md text"
```

<br />

## Full Function Reference / Docs? 📖

Rather than duplicate all the docs here,
please read the complete function reference,
on hexdocs: https://hexdocs.pm/gitea/Gitea.html

Gitea also provides the API documentation with the `/api/swagger` endpoint.
In our case it is located at: https://gitea-server.fly.dev/api/swagger

<br />

## Tests!

By default, the tests run with "mocks",
this means that: <br />

1. Functional tests run faster (0.2 seconds)
2. Tests that require filesystem access will run on GitHub CI.
3. We know that functions are appropriately
   ["Test Doubled"]
   so that a downstream `Elixir/Phoenix` app
   can run in `mock: true` and tests will be mocked (and thus _fast_!)

To alter this setting to run the tests _without_ mocks,
simply change the boolean from:

```elixir
config :gitea, mock: true
```

To:

```elixir
config :gitea, mock: false
```

You should still see the same output as all the functions should be tested.

### Test Coverage

When you run the command:

```sh
mix c
```

(an alias for `mix coveralls.html`) <br />
You will see output similar to the following:

```sh
Finished in 0.1 seconds (0.1s async, 0.00s sync)
3 doctests, 27 tests, 0 failures

Randomized with seed 715101
----------------
COV    FILE                                        LINES RELEVANT   MISSED
100.0% lib/git_mock.ex                                55        7        0
100.0% lib/gitea.ex                                   212       41        0
100.0% lib/helpers.ex                                131       17        0
100.0% lib/http.ex                                   119       18        0
100.0% lib/httpoison_mock.ex                         124       20        0
[TOTAL] 100.0%
----------------
```

If you want to run the tests _without_ mocks (i.e. "end-to-end"),
update the line in `config/test.exs`:

```sh
config :gitea, mock: false
```

When you run end-to-end tests with coverage tracking:

```sh
mix c
```

You should see the same output:

```sh
Finished in 5.5 seconds (5.5s async, 0.00s sync)
3 doctests, 27 tests, 0 failures

Randomized with seed 388372
----------------
COV    FILE                                        LINES RELEVANT   MISSED
100.0% lib/git_mock.ex                                55        7        0
100.0% lib/gitea.ex                                   212       41        0
100.0% lib/helpers.ex                                131       17        0
100.0% lib/http.ex                                   119       18        0
100.0% lib/httpoison_mock.ex                         124       20        0
[TOTAL] 100.0%
----------------
```

The only difference is the **_time_** it takes to run the test suite. <br />
The outcome (all tests passing and **100% coverage**) should be **_identical_**.

If you add a feature to the package,
please ensure that the tests pass
in both `mock: true` and `mock: false`
so that we know it works in the _real_ world
as well as in the simulated one.

<br />

## Roadmap

We are aiming to do a 1:1 feature map between GitHub and `Gitea`
so that we can backup our entire organisation, all repos, issues, labels & PRs.

We aren't there yet
and we might not be for some time.
The order in which we will be working
on fleshing out the features is:

1. **Git Diff** - using the `Git` module to determine the changes made to a specific file
   between two Git commits/hashes. This will allow us to visualize the changes made
   and can therefore _derive_ the contents of a Pull Request
   without having the PR feature exposed via the Gitea API.
   See: https://github.com/dwyl/gogs/issues/27
2. **Issues**: https://github.com/gogs/docs-api/tree/master/Issues

- **Comments** - this is the core content of issues.
  We need to parse all the data and map it to the fields in `Gitea`.
- **Labels** - the primary metadata we use to categorize our issues,
  see: https://github.com/dwyl/labels
- **Milestones** - used to _group_ issues into batches, e.g. a "sprint" or "feature".

3. **Repo Stats**: Stars, watchers, forks etc.
4. **_Your_ Feature Request** Here!
   Seriously, if you spot a gap in the list of available functions,
   something you want/need to use `Gitea` in any a more advanced/custom way,
   please open an issue so we can discuss!

<br />

## I'm _Stuck!_ 🤷

As always, if anything is unclear
or you are stuck getting this working,
please open an issue!
[github.com/dwyl/gitea/issues](https://github.com/dwyl/gitea/issues)
we're here to help!

<br />

<br />

<hr />

# ⚠️ Disclaimer! ⚠️

This package is provided "**as is**".
We make **_no guarantee/warranty_** that it _works_. <br />
We _cannot_ be held responsible
for any undesirable effects of it's usage.
e.g: if you use the [`Gitea.delete/1`](https://hexdocs.pm/gitea/Gitea.html#delete/1)
it will _permanently/irrecoverably_ **`delete`** the repo.
Use it with caution!

With the disclaimer out of the way,
and your expectations clearly set,
here are the facts:
We are using this package in "production".
We rely on it daily and consider it
["mission critical"](https://en.wikipedia.org/wiki/Mission_critical).
It works for _us_ an and
we have made every effort to document,
test & _maintain_ it.
If you want to use it, go for it!
But please note that we cannot "_support_" your usage
beyond answering questions on GitHub.
And unless you have a commercial agreement with
[dwyl Ltd.]

If you spot anything that can be improved,
please open an
[issue](https://github.com/dwyl/gitea/issues),
we're very happy to discuss!

[![feedback welcome](https://img.shields.io/badge/feedback-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/gitea/issues)
