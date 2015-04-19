defmodule PW do

  @doc """
  Get the :directory env variable.
  """
  def root_dir(opts \\ []) do
    (if Keyword.has_key?(opts, :directory),
      do: Keyword.get(opts, :directory),
      else: Application.get_env(:pw, :directory)
    |> Path.expand) <> "/"
  end

  @doc """
  Get the :recipient env variable.
  """
  def recipient(opts \\ []) do
    if Keyword.has_key?(opts, :recipient),
      do: Keyword.get(opts, :recipient),
      else: Application.get_env(:pw, :recipient)
  end

  @doc """
  Get the :io env variable.
  """
  def io, do: Application.get_env(:pw, :io)
end
