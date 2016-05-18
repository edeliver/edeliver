defmodule Edeliver.StartupProgress do
  @moduledoc """
    Monitors application start progress.

    This module can be added as additional error report handler
    using `:error_logger.add_report_handler/1` and
    handles progress reports from started applications and
    prints that information on the hidden node that called
    `Edeliver.monitor_startup_progress/2` as rpc call to
    wait until the release started after the asynchronous
    `bin/$APP start` command was executed.
  """


  @typedoc "State / Options passed to this report handler"
  @type t :: term

  @spec init(t) :: {:ok, t}
  @doc false
  def init(state), do: {:ok, state}

  @doc """
    Handles progress reports from started applications and
    prints that info on the hidden node that called
    `Edeliver.monitor_startup_progress/2` as rpc call to
    wait until the release started after the asynchronous
    `bin/$APP start` command was executed
  """
  # report from different node
  @spec handle_event({type::atom, pid, term}, t) :: {:ok, t}
  def handle_event({_type, gl, _message}, state) when node(gl) != node() do
    {:ok, state}
  end
  # progress report
  def handle_event({:info_report, _pid, {_, :progress, keywords}}, state) do
    case Keyword.get(keywords, :started_at) do
      nil -> :ignore
      _node ->
        case Keyword.get(keywords, :application) do
          nil -> :ignore
          application -> format_in_rpc_script 'Started application \'~w\'.~n', [application]
        end
    end
    {:ok, state}
  end
  # no pregress report
  def handle_event(_event, state), do: {:ok, state}

  @doc false
  @spec handle_info(term, t) :: {:ok, t}
  def handle_info(_, state), do: {:ok, state}

  @doc false
  @spec handle_call(term, t) :: {:error, :bad_query}
  def handle_call(_query, _state), do: {:error, :bad_query}

  @doc false
  @spec terminate(atom, t) :: :ok
  def terminate(_reason, _state), do: :ok


  defp format_in_rpc_script(format, arguments) do
    :erlang.nodes(:hidden) |> Enum.filter(fn node ->
      Regex.match?(~r/_maint_\d+/, Atom.to_string(node))
    end) |> Enum.each(fn node ->
      :rpc.cast(node, :io, :format, [:user, format, arguments])
    end)
  end

end