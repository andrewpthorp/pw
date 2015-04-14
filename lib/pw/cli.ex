defmodule PW.CLI do

  @moduledoc """
  Handle the command line parsing.
  """

  require Logger
  alias Porcelain.Result

  @dir Path.expand(Application.get_env(:pw, :root)) <> "/"
  @switches [help: :boolean]
  @aliases [h: :help]

  def main(argv) do
    argv
      |> parse_args
      |> process
  end

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
    Usage: pw [options] <command> [args]

    Options:
        -h, --help            Display this message

    Commands:
        list                  List all passwords by name
        add <password>        Add a new password, named <password>
        edit <password>       Edit <password>
        rm <password>         Delete <password>
    """
    System.halt(0)
  end

  @doc """
  Add a new password.
  """
  def process({"add", password}) do
    IO.puts "TODO: Add new password: #{password}"
  end

  @doc """
  Print a password to STDOUT.
  """
  def process({"get", password}) do
    %Result{err: err, out: results, status: status} = Porcelain.shell("gpg --no-tty -d #{@dir <> password}")

    if status == 0 do
      output = "Contents of #{password}:\n"
      output <> results |> String.strip |> IO.puts
    else
      IO.puts "Something went wrong: #{err}"
    end
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
    IO.puts "Deleted #{password}"
  end

  @doc """
  Unknown command, display help.
  """
  def process({cmd, _}) do
    IO.puts "Unknown command: #{cmd}"
    process(:help)
  end
end
