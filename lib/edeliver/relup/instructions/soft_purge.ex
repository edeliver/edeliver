defmodule Edeliver.Relup.Instructions.SoftPurge do
  @moduledoc """
    Upgrade instruction which replaces `:brutal_purge` with `:soft_purge`

    for `:load_module`, `:load`, `:update` and `:remove` relup instructions.

    If `:brutal_purge` is used, processes running old code are killed.
    If `:soft_purge` is used the release handler will refuse to start
    the upgrade.
  """
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %{}) do
    %{instructions|
      up_instructions:   replace_brutal_purge_with_soft_purge(instructions.up_instructions, []),
      down_instructions: replace_brutal_purge_with_soft_purge(instructions.down_instructions, [])
    }
  end

  defp replace_brutal_purge_with_soft_purge([{:load, {module, :brutal_purge, post_purge}}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:load, {module, :soft_purge, post_purge}}|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([{:update, module, change, :brutal_purge, post_purge, dep_mods}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:update, module, change, :soft_purge, post_purge, dep_mods}|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([{:update, module, timeout, change, :brutal_purge, post_purge, dep_mods}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:update, module, timeout, change, :soft_purge, post_purge, dep_mods}|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([{:update, module, mod_type, timeout, change, :brutal_purge, post_purge, dep_mods}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:update, module, mod_type, timeout, change, :soft_purge, post_purge, dep_mods}|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([{:load_module, module, :brutal_purge, post_purge, dep_mods}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:load_module, module, :brutal_purge, post_purge, dep_mods}|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([{:remove, {module, :brutal_purge, post_purge}}|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [{:remove, {module, :brutal_purge, post_purge}}|modified_instructions])

  defp replace_brutal_purge_with_soft_purge([first|rest], modified_instructions), do: \
    replace_brutal_purge_with_soft_purge(rest, [first|modified_instructions])
  defp replace_brutal_purge_with_soft_purge([], modified_instructions), do: Enum.reverse(modified_instructions)

end