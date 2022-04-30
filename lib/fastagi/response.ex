defmodule Fastagi.Response do
  defstruct [:code, :result, :value, :endpos, :digit, :results, :data]

  def parse(input) when is_binary(input) and byte_size(input) > 0 do
    input = String.trim_trailing(input, "\n")

    case String.split(input, [" ", "-"], parts: 2, trim: true) do
      ["100", rest] -> parse_init(100, rest)
      ["200", rest] -> parse_init(200, rest)
      ["503", rest] -> parse_init(503, rest)
      ["510", rest] -> parse_init(510, rest)
      ["511", rest] -> parse_init(511, rest)
      ["520", rest] -> parse_init(520, rest)
      ["HANGUP"] -> :hangup
      _ -> {:error, "Invalid input #{input}"}
    end
  end

  def parse(input), do: {:error, "Invalid input #{input}"}

  defp parse_init(code, input) do
    parse_input(%Fastagi.Response{code: code}, String.split(input))
  end

  defp parse_input(resp, [head | tail]) do
    case String.split(head, "=") do
      ["result", val] ->
        parse_input(Map.put(resp, :result, val), tail)

      ["endpos", val] ->
        parse_input(Map.put(resp, :endpos, val), tail)

      ["digit", val] ->
        parse_input(Map.put(resp, :digit, val), tail)

      ["results", val] ->
        parse_input(Map.put(resp, :results, val), tail)

      [text] ->
        cond do
          String.starts_with?(text, "(") -> parse_value(resp, [text | tail])
          true -> {:ok, Map.put(resp, :data, Enum.join([text | tail], " "))}
        end

      _ ->
        {:error, "Invalid input '#{head}'"}
    end
  end

  defp parse_input(resp, []), do: {:ok, resp}

  defp parse_value(resp, input) do
    with idx when not is_nil(idx) <-
           input
           |> Enum.with_index()
           |> Enum.filter(fn {e, _} -> String.ends_with?(e, ")") end)
           |> Enum.map(fn {_, i} -> i end)
           |> List.last(),
         list <- Enum.slice(input, 0..idx),
         val <- Enum.join(list, " ") |> String.slice(1..-2) do
      parse_input(Map.put(resp, :value, val), Enum.slice(input, (idx + 1)..-1))
    else
      _ -> {:error, "Failed to parse value"}
    end
  end
end
