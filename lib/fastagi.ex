defmodule Fastagi do
  @callback handle_connection(socket :: term) :: :ok | :error

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Fastagi

      def handle_connection(_sock) do
        raise "attempt to call Fastagi.Server but no handle_connection/1 provided"
      end

      defoverridable handle_connection: 1
    end
  end
end
