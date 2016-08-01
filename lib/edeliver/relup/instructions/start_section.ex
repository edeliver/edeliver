defmodule Edeliver.Relup.Instructions.StartSection do
  @moduledoc """
    This upgrade instruction starts a new section

    and logs that info on the node which runs the upgrade and
    in the upgrade script started by the
    `$APP/bin/$APP upgarde $RELEASE` command. Usage:

    ```
    Edeliver.Relup.Instructions.StartSection.modify_relup(config, _section = :check)
    ```

    Available sections are:

    * `:check`    -> Checks whether upgrade is possible. Before "point of no return"
    * `:suspend`  -> Suspends processes before the upgrade. Right after the "point of no return"
    * `:upgrade`  -> Runs the upgrade by (un-)loading new(/old) code and updating processes and applications
    * `:resume`   -> Resumes processes after the upgrade that were suspended in the `:suspend` section.
    * `:finished` -> The upgrade finished successfully

    It uses the `Edeliver.Relup.Instructions.Info` instruction to
    display the section information.
  """
  use Edeliver.Relup.Instruction
  alias Edeliver.Relup.Instructions.Info

  @type section :: :check | :suspend | :upgrade | :resume | :finished


  @spec modify_relup(instructions::Instructions.t, config::Edeliver.Relup.Config.t, section_or_message::section|String.t) :: Instructions.t
  def modify_relup(instructions = %Instructions{}, config = %{}, section \\ :default) do
    case section do
      :check    -> Info.modify_relup(instructions, config,
                                     _up_message   = "==> Checking whether upgrade to version #{instructions.up_version} is possible...",
                                     _down_message = "==> Checking whether downgrade to version #{instructions.down_version} is possible...",
                                     _insert_where = &insert_after_load_object_code/2)
      :suspend  -> Info.modify_relup(instructions, config,
                                     _up_message   = "==> Preparing upgrade to version #{instructions.up_version}...",
                                     _down_message = "==> Preparing downgrade to version #{instructions.down_version}...",
                                     _insert_where = &insert_after_point_of_no_return/2)
      :upgrade  -> Info.modify_relup(instructions, config,
                                     _up_message   = "==> Upgrading release to version #{instructions.up_version}...",
                                     _down_message = "==> Downgrading release to version #{instructions.down_version}...",
                                     _insert_where = &append_after_point_of_no_return/2)
      :resume   -> Info.modify_relup(instructions, config,
                                     _up_message   = "---> Upgrade to version #{instructions.up_version} succeeded.",
                                     _down_message = "---> Downgrade to version #{instructions.down_version} succeeded.",
                                     _insert_where = &append/2) |>
                   Info.modify_relup(config,
                                     _up_message   = "==> Resuming node after upgrade to version #{instructions.up_version}...",
                                     _down_message = "==> Resuming node after downgrade to version #{instructions.down_version}...",
                                     _insert_where = &append/2)
      :finished -> Info.modify_relup(instructions, config,
                                     _up_message   = "==> Finished upgrade to version #{instructions.up_version}...",
                                     _down_message = "==> Finished downgrade to version #{instructions.down_version}...",
                                     _insert_where = &append/2)
      unknown -> throw "Unknown section #{inspect unknown} for #{inspect __MODULE__} instruction."
    end
  end
end
