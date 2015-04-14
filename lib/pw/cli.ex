defmodule PW.CLI do

  @moduledoc """
  Handle the command line parsing.
  """

  require Logger
  alias Porcelain.Result

  @recipient Application.get_env(:pw, :recipient)
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
        -f, --force           Overwrite password if exists

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
  def process({"add", filename}) do
    IO.puts "Enter contents for #{filename} (end with new line):"
    Enum.take_while(IO.stream(:stdio, :line), &(String.strip(&1) != ""))
    |> perform_gpg(:encrypt)
    |> parse_result
    |> write_to_file(filename)
  end

  @doc """
  Print a password to STDOUT.
  """
  def process({"get", filename}) do
    validate_file_exists(filename)

    case perform_gpg(filename, :decrypt) do
      %Result{out: results, status: 0} ->
        "Contents of #{filename}:\n#{results}" |> String.strip |> IO.puts
      %Result{err: err} ->
        IO.puts "Error: #{err}"
    end
  end

  @doc """
  List all passwords.
  """
  def process({"list", _}) do
    case File.ls(@dir) do
      {:ok, results} -> Enum.each(results, &(IO.puts(&1)))
      {_, err} -> IO.puts("Error: #{err}")
    end
  end

  @doc """
  Remove a password.
  """
  def process({"rm", filename}) do
    validate_file_exists(filename)

    File.rm!(@dir <> filename)
    IO.puts "Deleted #{filename}"
  end

  @doc """
  Unknown command, display help.
  """
  def process({cmd, _}) do
    IO.puts "Unknown command: #{cmd}"
    process(:help)
  end

  defp perform_gpg(plaintext, :encrypt), do: Porcelain.shell("echo '#{plaintext}' | gpg --no-tty -aer #{@recipient}")
  defp perform_gpg(filename, :decrypt), do: Porcelain.shell("gpg --no-tty -d #{@dir <> filename}")
  defp parse_result(%Result{out: result}), do: result
  defp write_to_file(encrypted, filename), do: File.write!(@dir <> filename, encrypted)

  defp validate_file_exists(filename) do
    if !File.exists?(@dir <> filename) do
      IO.puts "Error: #{@dir <> filename} does not exist."
      System.halt(1)
    end
end
