defmodule Fastagi.Session do
  @doc """
  Initiate FastAGI session on new connection. Parse AGI
  input and setup connection socket.

  Run commands in current session.
  """
  defstruct envs: %{}, conn: nil

  @type t :: %Fastagi.Session{
          envs: Map.t(),
          conn: term()
        }

  @type response ::
          {:ok, Fastagi.Response.t()} | {:error, term()} | :hangup

  @doc """
  Initiate from new AGI session
  """
  @spec init(data :: String.t()) :: {:ok, t} | {:error, term}
  def init(data) do
    %Fastagi.Session{}
    |> parse_env(String.split(data, "\n", trim: true))
  end

  @doc """
  Close session connection
  """
  @spec close(sess :: t) :: :ok
  def close(%Fastagi.Session{conn: conn}) do
    :gen_tcp.close(conn)
  end

  @doc """
  Get AGI environment variable by key
  """
  @spec env(sess :: t, name :: String.t()) :: {:ok, String.t()} | :error
  def env(%Fastagi.Session{envs: envs}, name) do
    Map.fetch(envs, name)
  end

  @doc """
  Answers channel if not already in answer state.
  """
  @spec answer(sess :: t) :: response()
  def answer(sess), do: write_read(sess, "ANSWER")

  @doc """
  Interrupts Async AGI. Interrupts expected flow of Async AGI commands
  and returns control. to previous source (typically, the PBX dialplan)
  """
  @spec asyncagi_break(sess :: t) :: response()
  def asyncagi_break(sess), do: write_read(sess, "ASYNCAGI BREAK")

  @doc """
  Returns status of the connected channel.
  If no channel name is given (empty line) then returns the status of
  the current channel
  """
  @spec channel_status(sess :: t, chan :: String.t()) :: response()
  def channel_status(sess, chan),
    do: write_read(sess, "CHANNEL STATUS #{chan}")

  @doc """
  Sends audio file on channel and allows the listener to control the stream.
  """
  @spec control_stream_file(
          sess :: t,
          filename :: String.t(),
          escape_digits :: String.t(),
          skip_ms :: integer,
          ff_chr :: String.t(),
          rew_chr :: String.t(),
          pause_chr :: String.t(),
          offset_ms :: integer
        ) :: response
  def control_stream_file(
        sess,
        filename,
        escape_digits,
        skip_ms,
        ff_chr,
        rew_chr,
        pause_chr,
        offset_ms
      ) do
    cmd =
      "CONTROL STREAM FILE #{filename} \"#{escape_digits}\" " <>
        "#{skip_ms} \"#{ff_chr}\" \"#{rew_chr}\" \"#{pause_chr}\" " <>
        "#{offset_ms}"

    write_read(sess, cmd)
  end

  @doc """
  Deletes an entry in the Asterisk database for a given family and key
  """
  @spec database_del(sess :: t, family :: String.t(), key :: String.t()) :: response()
  def database_del(sess, family, key),
    do: write_read(sess, "DATABASE DEL #{family} #{key}")

  @doc """
  Deletes a family or specific keytree within a family in the Asterisk database
  """
  @spec database_deltree(sess :: t, family :: String.t(), keytree :: String.t()) ::
          response()
  def database_deltree(sess, family, key),
    do: write_read(sess, "DATABASE DELTREE #{family} #{key}")

  @doc """
  Retrieves an entry in the Asterisk database for a given family and key
  """
  @spec database_get(sess :: t, family :: String.t(), key :: String.t()) :: response()
  def database_get(sess, family, key),
    do: write_read(sess, "DATABASE GET #{family} #{key}")

  @doc """
  Adds or updates an entry in the Asterisk database for a given family, key, and value
  """
  @spec database_put(sess :: t, family :: String.t(), key :: String.t(), value :: String.t()) ::
          response()
  def database_put(sess, family, key, value),
    do: write_read(sess, "DATABASE PUT #{family} #{key} #{value}")

  @doc """
  Executes application with given options
  """
  @spec exec(sess :: t, application :: String.t(), options :: String.t()) :: response()
  def exec(sess, application, options),
    do: write_read(sess, "EXEC #{application} \"#{options}\"")

  @doc """
  Stream the given file, and receive DTMF data.
  Returns the digits received from the channel at the other end
  """
  @spec get_data(sess :: t, file :: String.t(), timeout :: integer, maxdigits :: integer) ::
          response()
  def get_data(sess, file, timeout, maxdigits) do
    cmd = ~s(GET DATA #{file} #{timeout} #{maxdigits})
    write_read(sess, cmd)
  end

  @doc """
  Evaluates the given expression against the channel specified by channelname,
  or the current channel if channelname is not provided
  """
  @spec get_full_variable(sess :: t, name :: String.t(), chan_name :: String.t()) ::
          response()
  def get_full_variable(sess, name, chan_name),
    do: write_read(sess, "GET FULL VARIABLE #{name} #{chan_name}")

  @doc """
  Stream file, prompt for DTMF, with timeout.
  Behaves similar to STREAM FILE but used with a timeout option.
  """
  @spec get_option(
          sess :: t,
          filename :: String.t(),
          escape_digits :: String.t(),
          timeout :: integer
        ) :: response()
  def get_option(sess, filename, escape_digits, timeout),
    do: write_read(sess, "GET OPTION #{filename} \"#{escape_digits}\" #{timeout}")

  @doc """
  Gets a channel variable
  """
  @spec get_variable(sess :: t, name :: String.t()) :: response()
  def get_variable(sess, name), do: write_read(sess, ~s(GET VARIABLE #{name}))

  @doc """
  Cause the channel to execute the specified dialplan subroutine
  """
  @spec gosub(
          sess :: t,
          context :: String.t(),
          exten :: String.t(),
          priority :: String.t(),
          args :: String.t()
        ) :: response()
  def gosub(sess, context, exten, priority, args) do
    cmd = "GOSUB #{context} #{exten} #{priority} #{args}"
    write_read(sess, cmd)
  end

  @doc """
  Hangup a channel
  """
  @spec hangup(sess :: t) :: response()
  def hangup(sess), do: write_read(sess, "HANGUP")

  @spec hangup(sess :: t, chan :: String.t()) :: response()
  def hangup(sess, chan), do: write_read(sess, "HANGUP #{chan}")

  @doc """
  Receives one character from channels supporting it
  """
  @spec receive_char(sess :: t) :: response()
  @spec receive_char(sess :: t, timeout :: integer()) :: response()
  def receive_char(sess, timeout \\ 0), do: write_read(sess, "RECEIVE CHAR #{timeout}")

  @doc """
  Receives text from channels supporting it
  """
  @spec receive_text(sess :: t) :: response()
  @spec receive_text(sess :: t, timeout :: integer()) :: response()
  def receive_text(sess, timeout \\ 0), do: write_read(sess, "RECEIVE TEXT #{timeout}")

  @doc """
  Record to a file until a given dtmf digit in the sequence is received
  """
  @spec record_file(
          sess :: t,
          filename :: String.t(),
          format :: String.t(),
          escape_digits :: String.t(),
          timeout :: integer(),
          offset :: integer(),
          beep :: boolean(),
          silence :: integer()
        ) :: response()
  def record_file(sess, fname, fmt, escdig, timeout, offset, beep, silence) do
    cmd = ["RECORD FILE", fname, fmt, escdig, timeout, offset]

    cmd = cmd ++ if beep, do: ["BEEP"], else: []

    cmd = cmd ++ if silence > 0, do: ["s=#{silence}"], else: []

    write_read(sess, Enum.join(cmd, " "))
  end

  @doc """
  Says a given character string
  """
  @spec say_alpha(sess :: t, number :: String.t(), escape_digits :: String.t()) ::
          response()
  def say_alpha(sess, number, escape_digits),
    do: write_read(sess, ~s(SAY ALPHA #{number} "#{escape_digits}"))

  @doc """
  Says a given date. date - Is number of seconds elapsed since 00:00:00 on
  January 1, 1970. Coordinated Universal Time (UTC).
  """
  @spec say_date(sess :: t, date :: integer(), escape_digits :: String.t()) ::
          response()
  def say_date(sess, date, escape_digits),
    do: write_read(sess, ~s(SAY DATE #{date} "#{escape_digits}"))

  @doc """
  Says a given time as specified by the format given
  """
  @spec say_datetime(
          sess :: t,
          time :: integer(),
          escape_digits :: String.t(),
          format :: String.t(),
          timezone :: String.t()
        ) :: response()
  def say_datetime(sess, time, escape_digits, format, timezone),
    do:
      write_read(
        sess,
        ~s(SAY DATETIME #{time} "#{escape_digits}" "#{format}" "#{timezone}")
      )

  @doc """
  Say a given digit string, returning early if any of the given DTMF digits
  are received on the channel
  """
  @spec say_digits(sess :: t, number :: String.t(), escape_digits :: String.t()) ::
          response()
  def say_digits(sess, number, escape_digits),
    do: write_read(sess, ~s(SAY DIGITS #{number} "#{escape_digits}"))

  @doc """
  Say a given number, returning early if any of the given DTMF digits
  are received on the channel
  """
  @spec say_number(
          sess :: t,
          number :: String.t(),
          escape_digits :: String.t(),
          gender :: String.t()
        ) :: response()
  def say_number(sess, number, escape_digits, gender),
    do: write_read(sess, ~s(SAY NUMBER #{number} "#{escape_digits}" "#{gender}"))

  @doc """
  Say a given character string with phonetics, returning early if any of the
  given DTMF digits are received on the channel
  """
  @spec say_phonetic(sess :: t, string :: String.t(), escape_digits :: String.t()) ::
          response()
  def say_phonetic(sess, string, escape_digits),
    do: write_read(sess, ~s(SAY PHONETIC #{string} "#{escape_digits}"))

  @doc """
  Say a given time, returning early if any of the given DTMF digits are
  received on the channel
  """
  @spec say_time(sess :: t, time :: integer(), escape_digits :: String.t()) ::
          response()
  def say_time(sess, time, escape_digits),
    do: write_read(sess, ~s(SAY TIME #{time} "#{escape_digits}"))

  @doc """
  Sends the given image on a channel. Most channels do not support
  the transmission of images
  """
  @spec send_image(sess :: t, image :: String.t()) :: response()
  def send_image(sess, image),
    do: write_read(sess, ~s(SEND IMAGE "#{image}"))

  @doc """
  Sends the given text on a channel. Most channels do not support
  the transmission of text
  """
  @spec send_text(sess :: t, text :: String.t()) :: response()
  def send_text(sess, text),
    do: write_read(sess, ~s(SEND TEXT "#{text}"))

  @doc """
  Cause the channel to automatically hangup at time seconds in the future.
  Of course it can be hungup before then as well. Setting to 0 will cause
  the autohangup feature to be disabled on this channel
  """
  @spec autohangup(sess :: t, time :: integer()) :: response()
  def autohangup(sess, time), do: write_read(sess, ~s(SET AUTOHANGUP #{time}))

  @doc """
  Changes the callerid of the current channel
  """
  @spec set_callerid(sess :: t, number :: String.t()) :: response()
  def set_callerid(sess, number), do: write_read(sess, ~s(SET CALLERID "#{number}"))

  @doc """
  Sets the context for continuation upon exiting the application
  """
  @spec set_context(sess :: t, context :: String.t()) :: response()
  def set_context(sess, context), do: write_read(sess, ~s(SET CONTEXT #{context}))

  @doc """
  Changes the extension for continuation upon exiting the application
  """
  @spec set_extension(sess :: t, exten :: String.t()) :: response()
  def set_extension(sess, exten), do: write_read(sess, ~s(SET EXTENSION #{exten}))

  @doc """
  Enables/Disables the music on hold generator. If class is not specified,
  then the default music on hold class will be used
  """
  @spec set_music(sess :: t, enable :: boolean(), class :: String.t()) :: response()
  @spec set_music(sess :: t, enable :: boolean()) :: response()
  def set_music(sess, enable, class \\ "default") do
    cmd = ["SET MUSIC"]
    cmd = cmd ++ if enable, do: ["on"], else: ["off"]
    cmd = cmd ++ [~s("#{class}")]
    write_read(sess, Enum.join(cmd, " "))
  end

  @doc """
  Changes the priority for continuation upon exiting the application.
  The priority must be a valid priority or label
  """
  @spec set_priority(sess :: t, priority :: String.t()) :: response()
  def set_priority(sess, priority), do: write_read(sess, ~s(SET PRIORITY #{priority}))

  @doc """
  Sets a variable to the current channel
  """
  @spec set_variable(sess :: t, name :: String.t(), value :: String.t()) :: response()
  def set_variable(sess, name, value),
    do: write_read(sess, ~s(SET VARIABLE #{name} "#{value}"))

  @doc """
  Send the given file, allowing playback to be interrupted by the given digits, if any
  """
  @spec stream_file(
          sess :: t,
          file :: String.t(),
          escape_digits :: String.t(),
          offset :: integer()
        ) :: response()
  def stream_file(sess, file, escape_digits, offset),
    do: write_read(sess, ~s(STREAM FILE #{file} "#{escape_digits}" #{offset}))

  @doc """
  Enable/Disable TDD transmission/reception on a channel
  """
  @spec tdd_mode(sess :: t, enable :: boolean()) :: response()
  def tdd_mode(sess, enable) do
    mode = if enable, do: "on", else: "off"
    write_read(sess, ~s(TDD MODE #{mode}))
  end

  @doc """
  Sends message to the console via verbose message system. level is the
  verbose level (1-4)
  """
  @spec verbose(sess :: t, msg :: String.t(), level :: integer()) :: response()
  @spec verbose(sess :: t, msg :: String.t()) :: response()
  def verbose(sess, msg, level \\ 1) do
    msg = String.replace(msg, "\"", "\\\"", global: true)
    msg = ~s(VERBOSE "#{msg}" #{level})
    write_read(sess, msg)
  end

  @doc """
  Waits up to timeout milliseconds for channel to receive a DTMF digit
  """
  @spec wait_for_digit(sess :: t, timeout :: integer()) :: response()
  def wait_for_digit(sess, timeout) do
    write_read(sess, ~s(WAIT FOR DIGIT #{timeout}))
  end

  defp write_read(%Fastagi.Session{conn: conn}, cmd) do
    cmd = cmd <> "\n"

    with :ok <- :gen_tcp.send(conn, cmd),
         {:ok, packet} <- :gen_tcp.recv(conn, 0, 5_000),
         do: Fastagi.Response.parse(packet)
  end

  defp parse_env(%Fastagi.Session{envs: envs}, [head | tail]) do
    case String.split(head, ":", parts: 2) do
      [k, v] ->
        envs =
          Map.put(
            envs,
            String.replace_prefix(k, "agi_", ""),
            String.trim(v)
          )

        parse_env(%Fastagi.Session{envs: envs}, tail)

      _ ->
        {:error, "Failed to parse line: '#{head}'"}
    end
  end

  defp parse_env(%Fastagi.Session{envs: envs} = sess, []) do
    if map_size(envs) > 0 do
      {:ok, sess}
    else
      {:error, "Empty envs variables list"}
    end
  end
end
