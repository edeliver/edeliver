defmodule Edeliver.Relup.Instructions.CheckRanchAcceptors do
  @moduledoc """
    This upgrade instruction checks whether the ranch acceptors can be found.

    This instruction will cause the upgrade to be canceled if the ranch acceptors
    cannot be found and because it is insterted before the "point of no return"
    it will run twice, once when checking the relup and once when executing the relup.
  """
  use Edeliver.Relup.RunnableInstruction

  @doc """
    Inserts the instruction before the point of no return.

    This causes the release handler to abort the upgrade
    already when running `:release_handler.check_install_release/1`
    if this instruction fails.
  """
  def insert_where, do: &insert_before_point_of_no_return/2

  @doc """
    Returns the name of the application.

    This name is taken as argument for the `run/1` function and is required to
    access the acceptor processes through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    name
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name) do
    name |> String.to_atom
  end

  @doc """
    Returns the pid of the phoenix endpoint supervisor

    or throws and logs an error if it cannot be found. It supervises the
    `Phoenix.Endpoint.Server` which supervises the connections and acceptors,
    `Phoenix.Config` and the phoenix pubsub supervisor, e.g. `Phoenix.PubSub.PG2`.
  """
  @spec endpoint(otp_application_name::atom) :: pid
  def endpoint(otp_application_name) when is_atom(otp_application_name) do
    application_master_pid = :application_controller.get_master(otp_application_name)
    assume true = is_pid(application_master_pid), "Failed to detect ranch socket acceptors. Application master not found."
    assume {application_supervisor_pid, _} = :application_master.get_child(application_master_pid), "Failed to detect ranch socket acceptors. Application supervisor not found."
    matching_children = Supervisor.which_children(application_supervisor_pid) |> Enum.filter(fn(child) ->
      case child do
        {mod, _pid, _type, [mod]} ->
          exports = mod.module_info(:exports)
              Enum.member?(exports, {:url, 0})
          and Enum.member?(exports, {:static_url, 0})
          and Enum.member?(exports, {:path, 1})
          and Enum.member?(exports, {:static_path, 1})
        _ -> false
      end
    end)
    assume [{_, endpoint_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Phoenix endpoint not found."
    endpoint_pid
  end

  @doc """
    Gets the pid of the ranch listener supervisor

    (`:ranch_listener_sup`) which supervises the ranch acceptors supervisor
    (`:ranch_acceptors_sup`) and the connections supervisor (`:ranch_conns_sup`).
    It throws and logs an error if they cannot be found in the supervison
    tree of the application.
  """
  @spec ranch_listener_sup(otp_application_name::atom) :: pid
  def ranch_listener_sup(otp_application_name) when is_atom(otp_application_name) do
    endpoint_pid = endpoint(otp_application_name)
    assume true = is_pid(endpoint_pid), "Failed to detect ranch socket acceptors. Phoenix endpoint not found."
    matching_children = Supervisor.which_children(endpoint_pid) |> Enum.filter(fn(child) ->
      case child do
        {Phoenix.Endpoint.Server, _pid, _type, [Phoenix.Endpoint.Server]} -> true
        _ -> false
      end
    end)
    assume [{_, endpoint_server_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Phoenix endpoint server not found."
    matching_children = Supervisor.which_children(endpoint_server_pid) |> Enum.filter(fn(child) ->
      case child do
        {{:ranch_listener_sup, _}, _pid, _type, [:ranch_listener_sup]} -> true
        _ -> false
      end
    end)
    assume [{_, ranch_listener_sup_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Ranch listener supervisor not found."
    ranch_listener_sup_pid
  end

  @doc """
    Gets the pid of the supervisor which supervises the ranch socket acceptors.

    If it cannot be found as child of the given ranch listener supervisor it
    throws and logs an error.
  """
  @spec ranch_acceptors_sup(ranch_listener_sup::pid) :: pid
  def ranch_acceptors_sup(ranch_listener_sup) do
    matching_children = Supervisor.which_children(ranch_listener_sup) |> Enum.filter(fn(child) ->
      case child do
        {:ranch_acceptors_sup, _pid, _type, [:ranch_acceptors_sup]} -> true
        _ -> false
      end
    end)
    assume [{_, ranch_acceptors_sup_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Ranch acceptors supervisor not found."
    ranch_acceptors_sup_pid
  end

  @doc """
    Gets the supervisor child ids of the ranch socket accecptors

    (`ranch_acceptor`) from the ranch acceptor supervisor or throws
    and logs an error if the acceptors cannot be found.
  """
  @spec ranch_acceptors(ranch_acceptors_sup::pid) :: [:supervisor.child_id]
  def ranch_acceptors(ranch_acceptors_sup) do
    acceptor_pids = Supervisor.which_children(ranch_acceptors_sup) |> List.foldr([], fn child, acc ->
      case child do
         {child_id = {:acceptor, ^ranch_acceptors_sup, _}, _pid, _type, []} -> [child_id|acc]
        _ -> acc
      end
    end)
    assume [_|_] = acceptor_pids, "Failed to detect ranch socket acceptors. No running acceptors found at acceptor supervisor."
    acceptor_pids
  end

  @doc """
    Checks whether the ranch acceptors can be found.

    If not the upgrade will be canceled. This function runs twice because
    it is executed before the "point of no return", once when checking
    the relup and once when executing the relup.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Checking whether ranch socket acceptors can be found..."
    ranch_listener_sup = ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to detect ranch socket acceptors. Ranch listener supervisor not found."
    ranch_acceptors_sup = ranch_acceptors_sup(ranch_listener_sup)
    assume true = is_pid(ranch_acceptors_sup), "Failed to detect ranch socket acceptors. Ranch acceptors supervisor not found."
    assume true = is_list(acceptors = ranch_acceptors(ranch_acceptors_sup)), "Failed to detect ranch socket acceptors. No acceptor processes found."
    info "Found #{inspect Enum.count(acceptors)} ranch acceptors."
  end


end
