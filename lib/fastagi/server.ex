defmodule Fastagi.Server do
  require Logger
  use GenServer
  @callback handle_connection(socket :: term) :: :ok | :error

  def start_link(port, module) do
    GenServer.start_link(__MODULE__, [port, module], name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def port do
    GenServer.call(__MODULE__, :get_port)
  end

  @impl true
  def init([port, module]) do
    opts = [:binary, packet: :line, active: false, reuseaddr: true]
    {:ok, sock} = :gen_tcp.listen(port, opts)
    {:ok, port} = :inet.port(sock)
    Logger.info("Start listen on port #{port}")

    pid = spawn_link(__MODULE__, :handle_accept, [sock, module])
    :ok = :gen_tcp.controlling_process(sock, pid)
    {:ok, %{sock: sock, module: module}}
  end

  @impl true
  def handle_call(:get_port, _from, %{sock: socket} = state) do
    {:ok, port} = :inet.port(socket)
    {:reply, port, state}
  end

  @impl true
  def terminate(reason, state) do
    :gen_tcp.close(state.sock)
    Logger.warn("#{__MODULE__} is closed with reason #{reason}")
  end

  def handle_accept(socket, module) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        Logger.info("Accept connection")
        spawn(fn -> create_sess(client, module) end)
        handle_accept(socket, module)

      {:error, err} ->
        Logger.warn("Acceptor interrupted: #{err}")
    end
  end

  defp create_sess(socket, module) do
    case sess_init_data(socket, "") do
      {:ok, input} ->
        case Fastagi.Session.init(input) do
          {:ok, sess} ->
            sess = %Fastagi.Session{sess | conn: socket}
            module.handle_connection(sess)

          {:error, err} ->
            Logger.warn("Failed to init Fastagi.Session: #{err}")
        end

      {:error, err} ->
        Logger.warn("Failed to read session data: #{err}")
    end
  end

  defp sess_init_data(socket, data) do
    case :gen_tcp.recv(socket, 0, 1000) do
      {:ok, line} when line == "\n" ->
        {:ok, data}

      {:ok, line} ->
        sess_init_data(socket, data <> line)

      {:error, err} ->
        Logger.warn("Session init failed: #{err}")
        {:error, err}
    end
  end

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Fastagi.Server

      def handle_connection(_sock) do
        raise "attempt to call Fastagi.Server but no handle_connection/1 provided"
      end

      defoverridable handle_connection: 1
    end
  end
end
