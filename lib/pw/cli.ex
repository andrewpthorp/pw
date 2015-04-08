defmodule PW.CLI do
  @dir Path.expand(Application.get_env(:pw, :root)) <> "/"

  @moduledoc """
  Handle the command line parsing.
  """

  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  @switches [help: :boolean]
  @aliases [h: :help]

  @doc """
  `argv` can be -h or --help, which returns :help.
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    case parse do
      { [help: true], _, _ }      -> :help
      { _, [command, param], _ }  -> { command, param }
      { _, [command], _ }         -> { command, "" }
      _                           -> :help
    end
  end

  @doc """
  Display usage information.
  """
  def process(:help) do
    IO.puts "usage: pw <command> [ description | id ]"
    System.halt(0)
  end

  @doc """
  Add a new password.
  """
  def process({"add", password}) do
    IO.puts "Adding '#{password}'."
  end

  @doc """
  Print a password to STDOUT.
  """
  def process({"get", password}) do
    IO.puts "Getting '#{password}'."
    IO.puts File.read!(@dir <> password)
  end

  @doc """
  List all passwords.
  """
  def process({"list", _}) do
    {:ok, files} = File.ls(@dir)
    Enum.each files, &(IO.puts(&1))
  end

  @doc """
  Remove a password.
  """
  def process({"rm", password}) do
    File.rm!(@dir <> password)
  end

  @doc """
  Unknown command, display help.
  """
  def process(_) do
    process(:help)
  end
end
