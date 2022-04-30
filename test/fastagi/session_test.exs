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

  test "init and parse agi input evironment variables", %{input: input} do
    assert {:ok, _} = Fastagi.Session.init(input)
    assert {:error, _} = Fastagi.Session.init("")
    assert {:error, _} = Fastagi.Session.init("foo bar")
  end

  test "get stored environment variable value", %{input: input} do
    assert {:ok, sess} = Fastagi.Session.init(input)
    assert {:ok, "yes"} = Fastagi.Session.env(sess, "network")
    assert {:ok, "5001"} = Fastagi.Session.env(sess, "callerid")
    assert {:ok, "argument2"} = Fastagi.Session.env(sess, "arg_2")
    assert :error = Fastagi.Session.env(sess, "foo")
  end
end
