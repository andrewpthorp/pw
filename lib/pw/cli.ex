defmodule PW.CLI do
  require Logger
  alias   Porcelain.Result

  @moduledoc """
  Handle the command line parsing.
  """

  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  @switches [help: :boolean]
  @aliases [h: :help, r: :recipient]

  # If "-h", "--help", or an unknown command is in argv, return :usage. If not,
  # return a tuple in the format {command, optional_argument}.
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    case parse do
      {[help: true], _, _}          -> :usage
      {opts, [command, arg], _}     -> {[command, arg], opts}
      {opts, [command], _}          -> {[command], opts}
      _                             -> :usage
    end
  end

  # Print usage information to STDOUT.
  def process(:usage) do
    PW.io.puts """
    Usage: pw [options] <command> [args]

    Options:
        -h, --help                Display this message
        -r, --recipient REC       Specify the gpg recipient to encrypt the password to

    Commands:
        list                      List all passwords by name
        add <password>            Add a new password, named <password>
        edit <password>           Edit <password>
        rm <password>             Delete <password>
    """
    System.halt(0)
  end

  # Add a new password to the filesystem.
  #
  # Encrypt the contents of STDIN to the gpg key for `recipient`. The ciphertext
  # will then be written to disk at `root_dir <> filename`.
  def process({["add", filename], opts}) do
    PW.io.puts "Enter contents for #{filename} (end with new line):"
    Enum.take_while(PW.io.stream(:stdio, :line), &(String.strip(&1) != ""))
    |> perform_gpg(:encrypt, Keyword.get(opts, :recipient, PW.recipient))
    |> parse_result
    |> write_to_file(filename)
  end

  # Print a password to STDOUT.
  #
  # Validate `filename` exists in `root_dir`, then decrypt it and write the
  # plaintext to STDOUT.
  def process({["get", filename], opts}) do
    validate_file_exists(filename)

    case perform_gpg(filename, :decrypt) do
      %Result{out: results, status: 0} ->
        "Contents of #{filename}:\n#{results}" |> String.strip |> PW.io.puts
      %Result{err: _err} ->
        PW.io.puts "Whoops! Something went wrong."
    end
  end

  # List all passwords.
  #
  # Print the name of every file in `root_dir` to STDOUT.
  def process({["list"], opts}) do
    case File.ls(PW.root_dir) do
      {:ok, results} -> Enum.each(results, &(PW.io.puts(&1)))
      {_, err} -> PW.io.puts("Error: #{err}")
    end
  end

  # Remove a password.
  #
  # Validate `filename` exists in `root_dir`, then delete `filename` from
  # `root_dir`.
  def process({["rm", filename], opts}) do
    validate_file_exists(filename)

    File.rm!(PW.root_dir <> filename)
    PW.io.puts "Deleted #{filename}"
  end

  # If the command that is passed in is not a valid command, print the usage
  # information to STDOUT.
  def process({args, _}) do
    PW.io.puts "Unknown command: #{Enum.at(args, 0)}"
    process(:usage)
  end

  # Encrypt `plaintext` to gpg key for `recipient`.
  defp perform_gpg(plaintext, :encrypt, recipient) do
    Porcelain.shell("echo '#{plaintext}' | gpg --no-tty -aer #{recipient}")
  end

  # Decrypt the contents of `filename` in `root_dir`.
  defp perform_gpg(filename, :decrypt) do
    Porcelain.shell("gpg --no-tty -d #{PW.root_dir <> filename}")
  end

  # Helper function to extract `out` from a `Porcelain.Result`.
  defp parse_result(%Result{out: result}), do: result

  # Takes some `ciphertext` and writes it to `filename` in `root_dir`. It will
  # overwrite `filename` in `root_dir` if it already exists.
  defp write_to_file(ciphertext, filename) do
    File.write!(PW.root_dir <> filename, ciphertext)
  end

  # Validate `filename` exists in `root_dir`, exit program with a status of 1 if
  # it does not.
  defp validate_file_exists(filename) do
    if !File.exists?(PW.root_dir <> filename) do
      PW.io.puts "Error: #{PW.root_dir <> filename} does not exist."
      System.halt(1)
    end
  end
end
