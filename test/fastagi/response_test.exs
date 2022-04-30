defmodule Fastagi.ResponsTest do
  use ExUnit.Case

  test "parse response code" do
    assert {:ok, %Fastagi.Response{code: 100}} =
             Fastagi.Response.parse("100 result=1 Trying...\n")

    assert {:ok, %Fastagi.Response{code: 200}} = Fastagi.Response.parse("200 result=1\n")

    assert {:ok, %Fastagi.Response{code: 503}} =
             Fastagi.Response.parse("503 result=-2 Memory allocation failure\n")

    assert {:ok, %Fastagi.Response{code: 510}} =
             Fastagi.Response.parse("510 Invalid or unknown command\n")

    assert {:ok, %Fastagi.Response{code: 511}} =
             Fastagi.Response.parse(
               "511 Command Not Permitted on a dead channel or intercept routine\n"
             )

    assert {:ok, %Fastagi.Response{code: 520}} =
             Fastagi.Response.parse("520 Invalid command syntax.\n")

    assert {:ok, %Fastagi.Response{code: 520}} =
             Fastagi.Response.parse("520-Invalid command syntax. Proper usage follows:\n")

    assert {:error, _} = Fastagi.Response.parse("")
  end

  describe "should parse successfully responses with values" do
    tests = [
      ["100 result=1 Trying...\n", 100, "1", nil, nil, nil, nil, "Trying..."],
      ["100 result=0\n", 100, "0", nil, nil, nil, nil, nil],
      ["100 Trying...\n", 100, nil, nil, nil, nil, nil, "Trying..."],
      ["200 result=1\n", 200, "1", nil, nil, nil, nil, nil],
      ["200 result=1 (hangup)\n", 200, "1", "hangup", nil, nil, nil, nil],
      ["200 result=-1 endpos=11223344\n", 200, "-1", nil, "11223344", nil, nil, nil],
      ["200 result=1 (\"Alice V\" <2233>)\n", 200, "1", "\"Alice V\" <2233>", nil, nil, nil, nil],
      ["200 result=1 (Alice Johnson)\n", 200, "1", "Alice Johnson", nil, nil, nil, nil],
      ["200 result=1 (Alice (Sales))\n", 200, "1", "Alice (Sales)", nil, nil, nil, nil],
      ["200 result=1 ((Sales) Bob)\n", 200, "1", "(Sales) Bob", nil, nil, nil, nil],
      ["200 result=1 (Alice (Recp) #1)\n", 200, "1", "Alice (Recp) #1", nil, nil, nil, nil],
      ["200 result=1 (SIP/9170-12-08)\n", 200, "1", "SIP/9170-12-08", nil, nil, nil, nil],
      ["200 result=1 (digit) digit=* endpos=98760\n", 200, "1", "digit", "98760", "*", nil, nil],
      ["200 result=1 (speech) endpos=91 results=23 \n", 200, "1", "speech", "91", nil, "23", nil],
      ["200 result=1 (dtmf) endpos=3 results=# \n", 200, "1", "dtmf", "3", nil, "#", nil],
      ["200 result= (timeout)\n", 200, "", "timeout", nil, nil, nil, nil],
      ["200 result=*123 (timeout)\n", 200, "*123", "timeout", nil, nil, nil, nil],
      [
        "200 result=1 (A (B) 1) digit=0 endpos=4 results=* it's done\n",
        200,
        "1",
        "A (B) 1",
        "4",
        "0",
        "*",
        "it's done"
      ],
      ["503 result=-2 Memory failure\n", 503, "-2", nil, nil, nil, nil, "Memory failure"],
      ["510 Invalid command\n", 510, nil, nil, nil, nil, nil, "Invalid command"]
    ]

    for test_case <- tests do
      @test_case test_case
      test "for input '#{List.first(test_case)}'" do
        [input, code, result, value, endpos, digit, results, data] = @test_case
        assert {:ok, resp} = Fastagi.Response.parse(input)
        assert resp.code == code
        assert resp.result == result
        assert resp.value == value
        assert resp.endpos == endpos
        assert resp.digit == digit
        assert resp.results == results
        assert resp.data == data
      end
    end
  end

  describe "should fail to parse invalid response" do
    tests = [
      " ",
      nil,
      123,
      " foo",
      "foo bar",
      "100",
      "200 ",
      "200 result=1 (foo bar",
      "100 unknown=foo result=1"
    ]

    for test_case <- tests do
      @test_case test_case
      test "for input '#{test_case}'" do
        assert {:error, _} = Fastagi.Response.parse(@test_case)
      end
    end
  end

  test "parse error command response" do
    input = "520 Invalid command syntax. Proper usage not available.\n"
    assert {:ok, resp} = Fastagi.Response.parse(input)
    assert resp.code == 520
    assert resp.data == "Invalid command syntax. Proper usage not available."

    input =
      "520-Invalid command syntax.  Proper usage follows:\n" <>
        "Usage: database put <family> <key> <value>\n" <>
        "Adds or updates an entry in the Asterisk database for\n" <>
        "a given family, key, and value.\n" <>
        "520 End of proper usage.\n"

    assert {:ok, resp} = Fastagi.Response.parse(input)
    assert resp.code == 520
    assert String.contains?(resp.data, "Invalid command syntax. Proper usage follows")
    assert String.contains?(resp.data, "Usage: database put <family> <key> <value>")
    assert String.contains?(resp.data, "Adds or updates an entry in the Asterisk database for")
    assert String.contains?(resp.data, "a given family, key, and value.")
    assert String.contains?(resp.data, "520 End of proper usage.")
  end
end
