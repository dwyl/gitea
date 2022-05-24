defmodule Gitea.Error do
  @message "A Gitea error occurred"
  @reason :unknown
  defexception message: @message, reason: @reason

  @doc """
  message\1 used to raise error with Gitea.Error struct:
  raise %Gitea.Error{message: "Gitea error", reason: :gitea_down
  """
  @impl true
  def message(%__MODULE__{message: message, reason: reason}) do
    "#{message}, reason: #{reason}"
  end

  @doc """
  exception\1 used with:
  raise Gitea.Error, message: "gitea error", reason: :gitea_down
  """
  @impl true
  def exception(args) do
    message = args[:message] || @message
    reason = args[:reason] || @reason
    %__MODULE__{message: message, reason: reason}
  end
end
