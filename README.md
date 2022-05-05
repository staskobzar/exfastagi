# Fastagi
[![Elixir CI](https://github.com/staskobzar/exfastagi/actions/workflows/elixir.yml/badge.svg)](https://github.com/staskobzar/exfastagi/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/staskobzar/exfastagi/badge.svg?branch=master)](https://coveralls.io/github/staskobzar/exfastagi?branch=master)
[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/staskobzar/exfastagi/blob/master/LICENSE)


Elixir FastAGI library to build FastAGI servers and process Asterisk calls.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fastagi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fastagi, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/fastagi>.

## Usage
Module to Fasagi processes each AGI connection with "handle_connection" callback withing a module that uses Fastagi. Module example:

```elixir
defmodule MyAGI do
  require Logger
  use Fastagi

  def handle_connection(sess) do
    IO.puts("========================================")
    IO.inspect(sess)

    with {:ok, _} <- Fastagi.Session.answer(sess),
         {:ok, _} <- Fastagi.Session.verbose(sess, "Hello there from exFastagi"),
         {:ok, resp} <- Fastagi.Session.get_variable(sess, "VARFOO"),
         :ok <- Logger.info("VARFOO = #{resp.value}"),
         {:ok, _} = Fastagi.Session.hangup(sess) do
      IO.puts("=================================================")
      IO.puts("| session is done")
      IO.puts("=================================================")
    else
      :hangup -> Logger.warn("Session channel was hangup by Asterisk")
      {:error, err} -> Logger.error("Session error: #{err}")
    end

    Fastagi.Session.close(sess)
  end
end
```

Starting ```Fastagi.Server``` can be done directly via "start_link" function that receives port and module name as arguments. Can also be used in application. For example:
```elixir
defmodule MyMAGI.App do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task, fn -> Fastagi.Server.start_link(4575, MyAGI) end},
        restart: :permanent
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```
