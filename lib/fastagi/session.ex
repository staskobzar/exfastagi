defmodule Fastagi.Session do
  defstruct envs: %{}, conn: nil

  @type t() :: %Fastagi.Session{}

  @callback start_session(sess :: Fastagi.Session.t()) :: any

  def init(data) do
    %Fastagi.Session{}
    |> parse_env(String.split(data, "\n", trim: true))
  end

  def close(sess) do
    :gen_tcp.close(sess.conn)
  end

  def env(sess, name) do
    Map.fetch(sess.envs, name)
  end

  def answer(sess), do: write_read(sess, "ANSWER")

  def get_data(sess, file, timeout, maxdigit) do
    cmd = ~s(GET DATA #{file} #{timeout} #{maxdigit})
    write_read(sess, cmd)
  end

  def get_variable(sess, name), do: write_read(sess, ~s(GET VARIABLE #{name}))

  def hangup(sess), do: write_read(sess, "HANGUP")

  def verbose(sess, msg, level \\ 1) do
    msg = ~s(VERBOSE "#{msg}" #{level})
    write_read(sess, msg)
  end

  defp write_read(sess, cmd) do
    cmd = cmd <> "\n"
    IO.inspect(cmd)

    with :ok <- :gen_tcp.send(sess.conn, cmd),
         {:ok, packet} <- :gen_tcp.recv(sess.conn, 0, 5_000),
         do: Fastagi.Response.parse(packet)
  end

  defp parse_env(sess, [head | tail]) do
    case String.split(head, ":", parts: 2) do
      [k, v] ->
        envs =
          Map.put(
            sess.envs,
            String.replace_prefix(k, "agi_", ""),
            String.trim(v)
          )

        parse_env(%Fastagi.Session{envs: envs}, tail)

      _ ->
        {:error, "Failed to parse line: '#{head}'"}
    end
  end

  defp parse_env(sess, []) do
    if map_size(sess.envs) > 0 do
      {:ok, sess}
    else
      {:error, "Empty envs variables list"}
    end
  end
end
