defmodule Fastagi.SessionTest do
  use ExUnit.Case

  setup do
    input =
      "agi_network: yes\n" <>
        "agi_network_script: foo?\n" <>
        "agi_request: agi://127.0.0.1/foo?\n" <>
        "agi_channel: SIP/2222@default-00000023\n" <>
        "agi_language: en\n" <>
        "agi_type: SIP\n" <>
        "agi_uniqueid: 1397044468.0\n" <>
        "agi_version: 0.1\n" <>
        "agi_callerid: 5001\n" <>
        "agi_calleridname: Alice\n" <>
        "agi_callingpres: 67\n" <>
        "agi_callingani2: 0\n" <>
        "agi_callington: 0\n" <>
        "agi_callingtns: 0\n" <>
        "agi_dnid: 123456\n" <>
        "agi_rdnis: unknown\n" <>
        "agi_context: default\n" <>
        "agi_extension: 2222\n" <>
        "agi_priority: 1\n" <>
        "agi_enhanced: 0.0\n" <>
        "agi_accountcode: 0\n" <>
        "agi_threadid: 140536028174080\n" <>
        "agi_arg_1: argument1\n" <>
        "agi_arg_2: argument2\n\n"

    %{input: input}
  end

  setup do
    {:ok, sock} =
      :gen_tcp.listen(
        0,
        [:binary, packet: :line, active: false, reuseaddr: true]
      )

    spawn(fn ->
      case :gen_tcp.accept(sock) do
        {:ok, client} ->
          {:ok, data} = :gen_tcp.recv(client, 0, 1000)
          :ok = :gen_tcp.send(client, "200 result=1\n")
          :ok = :gen_tcp.send(client, data)
          :gen_tcp.close(client)

        _ ->
          nil
      end
    end)

    on_exit(fn ->
      :gen_tcp.close(sock)
    end)

    {:ok, port} = :inet.port(sock)
    %{port: port}
  end

  @moduletag :capture_log
  test "init and parse agi input evironment variables", %{input: input} do
    assert {:ok, _} = Fastagi.Session.init(input)
    assert {:error, _} = Fastagi.Session.init("")
    assert {:error, _} = Fastagi.Session.init("foo bar")
  end

  @moduletag :capture_log
  test "get stored environment variable value", %{input: input} do
    assert {:ok, sess} = Fastagi.Session.init(input)
    assert {:ok, "yes"} = Fastagi.Session.env(sess, "network")
    assert {:ok, "5001"} = Fastagi.Session.env(sess, "callerid")
    assert {:ok, "argument2"} = Fastagi.Session.env(sess, "arg_2")
    assert :error = Fastagi.Session.env(sess, "foo")
  end

  @moduletag :capture_log
  test "command answer", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.answer(sess)
    assert {:ok, "ANSWER\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command async agi break", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.asyncagi_break(sess)
    assert {:ok, "ASYNCAGI BREAK\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command channel status", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.channel_status(sess, "SIP/444-000f1")
    assert {:ok, "CHANNEL STATUS SIP/444-000f1\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command control stream file", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.control_stream_file(sess, "prompt", "01", 600, "#", "*", "", 2000)

    assert {:ok, "CONTROL STREAM FILE prompt \"01\" 600 \"#\" \"*\" \"\" 2000\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command database del", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.database_del(sess, "chan/sip", "5004")
    assert {:ok, "DATABASE DEL chan/sip 5004\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command database deltree", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.database_deltree(sess, "chan", "sip")
    assert {:ok, "DATABASE DELTREE chan sip\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command database get", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.database_get(sess, "chans", "sip")
    assert {:ok, "DATABASE GET chans sip\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command database put", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} = Fastagi.Session.database_put(sess, "chan", "sip", "5004")

    assert {:ok, "DATABASE PUT chan sip 5004\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command exec", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.exec(sess, "GoTo", "default,s,1")
    assert {:ok, "EXEC GoTo \"default,s,1\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command get data", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.get_data(sess, "welcome", 1000, 5)
    assert {:ok, "GET DATA welcome 1000 5\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command get full variable", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.get_full_variable(sess, "LANGUAGE", "SIP/300-00012f")

    assert {:ok, "GET FULL VARIABLE LANGUAGE SIP/300-00012f\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command get option", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.get_option(sess, "welcome", "01", 5000)
    assert {:ok, "GET OPTION welcome \"01\" 5000\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command get variable", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.get_variable(sess, "LANGUAGE")
    assert {:ok, "GET VARIABLE LANGUAGE\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command gosub with args", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} = Fastagi.Session.gosub(sess, "inbound", "100", "1", "foo,1")

    assert {:ok, "GOSUB inbound 100 1 foo,1\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command hangup", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.hangup(sess)
    assert {:ok, "HANGUP\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command hangup channel", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.hangup(sess, "SIP/100-00001f-1")
    assert {:ok, "HANGUP SIP/100-00001f-1\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command receive char", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.receive_char(sess)
    assert {:ok, "RECEIVE CHAR 0\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command receive char timeout", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.receive_char(sess, 1000)
    assert {:ok, "RECEIVE CHAR 1000\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command receive text", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.receive_text(sess)
    assert {:ok, "RECEIVE TEXT 0\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command receive text timeout", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.receive_text(sess, 1000)
    assert {:ok, "RECEIVE TEXT 1000\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command record file", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.record_file(sess, "newrec", "wav", "029", 1000, 0, false, 0)

    assert {:ok, "RECORD FILE newrec wav 029 1000 0\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command record file with beep", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.record_file(sess, "newrec", "wav", "029", 1000, 0, true, 0)

    assert {:ok, "RECORD FILE newrec wav 029 1000 0 BEEP\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command record file with silence", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.record_file(sess, "newrec", "wav", "029", 1000, 0, false, 100)

    assert {:ok, "RECORD FILE newrec wav 029 1000 0 s=100\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command record file with beep and silence", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.record_file(sess, "newrec", "wav", "029", 1000, -1, true, 200)

    assert {:ok, "RECORD FILE newrec wav 029 1000 -1 BEEP s=200\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say alpha", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_alpha(sess, "123", "#")
    assert {:ok, "SAY ALPHA 123 \"#\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say date", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_date(sess, 1_563_844_045, "#0")
    assert {:ok, "SAY DATE 1563844045 \"#0\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say datetime", %{port: port} do
    sess = mock_sess(port)

    assert {:ok, %{code: 200}} =
             Fastagi.Session.say_datetime(sess, "1563844045", "#", "dB", "UTC")

    assert {:ok, "SAY DATETIME 1563844045 \"#\" \"dB\" \"UTC\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say digits", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_digits(sess, "4045", "")
    assert {:ok, "SAY DIGITS 4045 \"\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say number", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_number(sess, "1045", "#", "")
    assert {:ok, "SAY NUMBER 1045 \"#\" \"\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say phonetic", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_phonetic(sess, "hello", "#")
    assert {:ok, "SAY PHONETIC hello \"#\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command say time", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.say_time(sess, "1563844045", "#")
    assert {:ok, "SAY TIME 1563844045 \"#\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command send image", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.send_image(sess, "logo.png")
    assert {:ok, "SEND IMAGE \"logo.png\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command send text", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.send_text(sess, "Hello there!")
    assert {:ok, "SEND TEXT \"Hello there!\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command autohangup", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.autohangup(sess, 5)
    assert {:ok, "SET AUTOHANGUP 5\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set callerid", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_callerid(sess, "5142842020")
    assert {:ok, "SET CALLERID \"5142842020\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set context", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_context(sess, "inbound")
    assert {:ok, "SET CONTEXT inbound\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set extension", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_extension(sess, "1002")
    assert {:ok, "SET EXTENSION 1002\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set music default", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_music(sess, true)
    assert {:ok, "SET MUSIC on \"default\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set music class", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_music(sess, false, "jazz")
    assert {:ok, "SET MUSIC off \"jazz\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set priority", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_priority(sess, "1")
    assert {:ok, "SET PRIORITY 1\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command set variable", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.set_variable(sess, "ACCOUNT", "1001")
    assert {:ok, "SET VARIABLE ACCOUNT \"1001\"\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command stream file", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.stream_file(sess, "welcome", "#*", 100)
    assert {:ok, "STREAM FILE welcome \"#*\" 100\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command tdd mode", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.tdd_mode(sess, true)
    assert {:ok, "TDD MODE on\n"} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command verbose", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.verbose(sess, "Hello world")
    assert {:ok, ~s(VERBOSE "Hello world" 1\n)} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command verbose escaped", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.verbose(sess, ~s(Hi there "USER"))
    assert {:ok, ~s(VERBOSE "Hi there \\"USER\\"" 1\n)} = get_cmd(sess)
  end

  @moduletag :capture_log
  test "command wait for digit", %{port: port} do
    sess = mock_sess(port)
    assert {:ok, %{code: 200}} = Fastagi.Session.wait_for_digit(sess, 1400)
    assert {:ok, "WAIT FOR DIGIT 1400\n"} = get_cmd(sess)
  end

  defp mock_sess(port) do
    opts = [:binary, packet: :line, active: false]
    {:ok, sock} = :gen_tcp.connect('localhost', port, opts)
    %Fastagi.Session{conn: sock}
  end

  defp get_cmd(%{conn: sock}) do
    :gen_tcp.recv(sock, 0)
  end
end
