defmodule Fastagi.ServerTest do
  use ExUnit.Case

  @moduletag :capture_log
  test "start and stop server" do
    assert {:ok, pid} = Fastagi.Server.start_link(0, Fastagi.Dummy)
    assert Process.alive?(pid)
    assert Fastagi.Server.port() > 0
    assert :ok = Fastagi.Server.stop()
    assert Process.alive?(pid) == false
  end

  @moduletag :capture_log
  test "invalid session" do
    assert {:ok, pid} = Fastagi.Server.start_link(0, Fastagi.Dummy)

    {:ok, client} =
      :gen_tcp.connect(
        'localhost',
        Fastagi.Server.port(),
        [:binary, packet: :line, active: false]
      )

    :ok = :gen_tcp.send(client, "foo\n\n")
    Process.sleep(100)
    assert :ok = Fastagi.Server.stop()
    assert Process.alive?(pid) == false
  end

  @moduletag :capture_log
  test "valid session initiated" do
    input =
      "agi_network: yes\n" <>
        "agi_network_script: foo?\n" <>
        "agi_request: agi://127.0.0.1/foo?\n" <>
        "agi_channel: SIP/2222@default-00000023\n" <>
        "agi_language: en\n\n"

    assert {:ok, pid} = Fastagi.Server.start_link(0, Fastagi.Dummy)

    {:ok, client} =
      :gen_tcp.connect(
        'localhost',
        Fastagi.Server.port(),
        [:binary, packet: :line, active: false]
      )

    :ok = :gen_tcp.send(client, input)
    Process.sleep(100)
    assert :ok = Fastagi.Server.stop()
    assert Process.alive?(pid) == false
  end

  @moduletag :capture_log
  test "handle closed client connection" do
    assert {:ok, pid} = Fastagi.Server.start_link(0, Fastagi.Dummy)

    {:ok, client} =
      :gen_tcp.connect(
        'localhost',
        Fastagi.Server.port(),
        [:binary, packet: :line, active: false]
      )

    :gen_tcp.close(client)
    assert :ok = Fastagi.Server.stop()
    assert Process.alive?(pid) == false
  end
end

defmodule Fastagi.Dummy do
  use Fastagi

  def handle_connection(sess) do
    Fastagi.Session.close(sess)
  end
end
