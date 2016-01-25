defmodule Edeliver.Relup.Instructions.CheckRanchConnections do
  @moduledoc """
    This upgrade instruction checks whether the running ranch connections can be found.
    This instruction will cause the upgrade to be canceled if the ranch connections
    cannot be found and because it is insterted before the "point of no return"
    it will run twice, once when checking the relup and once when executing the relup.
  """
  use Edeliver.Relup.RunnableInstruction
  alias Edeliver.Relup.Instructions.CheckRanchAcceptors

  @doc """
    Inserts the instruction before the point of no return.
    This causes the release handler to abort the upgrade
    already when running `:release_handler.check_install_release/1`
    if this instruction fails.
  """
  def insert_where, do: &insert_before_point_of_no_return/2

  @doc """
    Returns name of the application. This name is taken as argument
    for the `run/1` function and is required to access the acceptor processes
    through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %Config{name: name}) do
    name |> String.to_atom
  end

  @doc """
    This module requires the `Edeliver.Relup.Instructions.CheckRanchAcceptors` module
    which must be loaded before this instruction for upgrades and unload after this
    instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  end


  @doc """
    Gets the pid of the supervisor which supervises the ranch connections.
    If it cannot be found as child of the given ranch listener supervisor it
    throws and logs an error.
  """
  @spec ranch_connections_sup(ranch_listener_sup::pid) :: pid
  def ranch_connections_sup(ranch_listener_sup) do
    matching_children = Supervisor.which_children(ranch_listener_sup) |> Enum.filter(fn(child) ->
      case child do
        {:ranch_conns_sup, _pid, _type, [:ranch_conns_sup]} -> true
        _ -> false
      end
    end)
    assume [{_, ranch_acceptors_sup_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Ranch acceptors supervisor not found."
    ranch_acceptors_sup_pid
  end

  @doc """
    Gets the process ids of the ranch socket connections if there are any.
  """
  @spec ranch_connections(ranch_acceptors_sup::pid) :: [:supervisor.child_id]
  def ranch_connections(ranch_acceptors_sup) do
    acceptor_pids = Supervisor.which_children(ranch_acceptors_sup) |> List.foldr([], fn child, acc ->
      case child do
         {_child_id = :cowboy_protocol, pid, :worker, [:cowboy_protocol]} -> [pid|acc]
        _ -> acc
      end
    end)
    acceptor_pids
  end

  @doc """
    Checks whether the ranch connections can be found. If not the upgrade
    will be canceled. This function runs twice because it is executed before
    the "point of no return", once when checking the relup and once when executing the relup.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Checking whether ranch socket connections can be found..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to detect ranch socket connections. Ranch listener supervisor not found."
    ranch_connections_sup = ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to detect ranch socket connections. Ranch connections supervisor not found."
    assume true = is_list(connections = ranch_connections(ranch_connections_sup)), "Failed to detect ranch socket connections. No connection processes found."
    info "Found #{inspect Enum.count(connections)} ranch connections."
  end


end
