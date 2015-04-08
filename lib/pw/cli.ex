defmodule PW.CLI do
  @moduledoc """
  Handle the command line parsing.
  """

  def run(argv) do
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
    IO.puts """
    usage: pw <command> [ description | id ]
    """
    System.halt(0)
  end

  @doc """
  Add a new password.
  """
  def process({"add", password}) do
    IO.puts "Adding '#{password}'."
  end

  @doc """
  List all passwords.
  """
  def process({"list", _}) do
    {:ok, files} = File.ls(System.user_home! <> "/.pw/")
    Enum.each files, &(IO.puts(&1))
  end

  @doc """
  Remove a password.
  """
  def process({"rm", filename}) do
    File.rm!(System.user_home! <> "/.pw/#{filename}")
  end
end
