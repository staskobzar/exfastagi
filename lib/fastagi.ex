defmodule Fastagi do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task, fn -> Fastagi.Server.start_link(4575, Foo) end},
        restart: :permanent
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule Foo do
  require Logger
  use Fastagi.Server

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
