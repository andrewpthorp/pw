defmodule PW do

  @doc """
  Get the :directory env variable.
  """
  def root_dir, do: Path.expand(Application.get_env(:pw, :directory)) <> "/"

  @doc """
  Get the :recipient env variable.
  """
  def recipient, do: Application.get_env(:pw, :recipient)

  @doc """
  Get the :io env variable.
  """
  def io, do: Application.get_env(:pw, :io)
end
