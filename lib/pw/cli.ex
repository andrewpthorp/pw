defmodule PW.CLI do
  require Logger
  alias   Porcelain.Result

  @moduledoc """
  Usage: pw [options] <command> [args]

  Options:
      -h, --help                Display this message
      -r, --recipient REC       Specify the gpg recipient <REC> to encrypt the password to
      -d, --directory DIR       Write passwords to / read passwords from <DIR>

  Commands:
      list                      List all passwords by name
      add <password>            Add a new password, named <password>
      get <password>            Get <password> and print to STDOUT
      rm <password>             Delete <password>
  """

  def main(argv) do
    parse_config
    argv
      |> parse_args
      |> process
      |> Enum.join("\n")
      |> PW.io.puts
  end

  @switches [help: :boolean]
  @aliases [h: :help, r: :recipient, d: :directory]

  @dic """
  Parse a file at ~/.pw to set env variables.
  """
  def parse_config do
    case File.read(Path.expand(Application.get_env(:pw, :config_file))) do
      {:ok, ""}     -> :ok
      {:ok, config}   ->
        String.strip(config)
        |> String.split("\n")
        |> Enum.map(&(String.split(&1, "=")))
        |> Enum.each(fn [k, v] -> Application.put_env(:pw, String.to_atom(k), v) end)

      {:error, _err}  -> :ok
    end
  end

  @doc """
  Use `OptionParser` to parse arguments.

  If `-h`, `--help`, or an unknown command is in argv, return :usage. If not,
  return a tuple in the format {[command, optional_arg], flags}.
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    case parse do
      {[help: true], _, _}        -> :usage
      {flags, [command, arg], _}  -> {[command, arg], flags}
      {flags, [command], _}       -> {[command], flags}
      _                           -> :usage
    end
  end

  @doc """
  List all passwords.

  Print the name of every file in `root_dir` to STDOUT.
  """
  def process({["list"], opts}) do
    case File.ls(PW.root_dir(opts)) do
      {:ok, results}      -> ["I know passwords for:"] ++ results
      {:error, :enoent}   -> error("#{PW.root_dir(opts)} does not exist.")
      {:error, :eaccess}  -> error("You do not have access to #{PW.root_dir(opts)}.")
      {_, err}            -> error(err)
    end
  end

  @doc """
  Print a password to STDOUT.

  Validate `filename` exists in `root_dir`, then decrypt it and write the
  plaintext to STDOUT.
  """
  def process({["get", filename], opts}) do
    validate_file_exists!(filename, opts)

    case perform_gpg(filename, :decrypt, opts) do
      %Result{out: results, status: 0} ->
        ["Contents of #{filename}:"] ++ String.split(String.strip(results), "\n")
      %Result{err: _err} ->
        error("GPG decryption failed.")
    end
  end

  @doc """
  Add a new password to the filesystem.

  Encrypt the contents of STDIN to the gpg key for `recipient`. The ciphertext
  will then be written to disk at `root_dir <> filename`.
  """
  def process({["add", filename], opts}) do
    validate_recipient_set!(opts)

    """
    Encrypting #{filename} to #{PW.recipient(opts)}.
    Type the contents of #{filename}, end with a blank line:
    """
    |> String.strip
    |> PW.io.puts

    Enum.take_while(PW.io.stream(:stdio, :line), &(String.strip(&1) != ""))
    |> perform_gpg(:encrypt, opts)
    |> parse_result
    |> write_to_file(filename, opts)

    ["Added #{filename}."]
  end

  @doc """
  Remove a password.

  Validate `filename` exists in `root_dir`, then delete `filename` from
  `root_dir`.
  """
  def process({["rm", filename], opts}) do
    validate_file_exists!(filename, opts)

    File.rm!(PW.root_dir(opts) <> filename)

    ["Deleted #{filename}."]
  end

  @doc """
  Print usage information to STDOUT.
  """
  def process(:usage) do
    PW.io.puts @moduledoc
    System.halt(0)
  end

  @doc """
  If the command that is passed in is not a valid command, print the usage
  information to STDOUT.
  """
  def process(args) do
    command = elem(args, 0) |> Enum.at(0)
    error("unknown command: #{command}\n")
    process(:usage)
  end

  # Encrypt `plaintext` to gpg key for `recipient`.
  defp perform_gpg(plaintext, :encrypt, opts) do
    Porcelain.shell("echo '#{plaintext}' | gpg --no-tty -aer #{PW.recipient(opts)}")
  end

  # Decrypt the contents of `filename` in `root_dir`.
  defp perform_gpg(filename, :decrypt, opts) do
    Porcelain.shell("gpg --no-tty -d #{PW.root_dir(opts) <> filename}")
  end

  # Helper function to extract `out` from a `Porcelain.Result`.
  defp parse_result(%Result{out: result}), do: result

  # Takes some `ciphertext` and writes it to `filename` in `root_dir`. It will
  # overwrite `filename` in `root_dir` if it already exists.
  defp write_to_file(ciphertext, filename, opts) do
    File.write!(PW.root_dir(opts) <> filename, ciphertext)
  end

  # Validate `filename` exists in `root_dir`, exit program with a status of 1 if
  # it does not.
  defp validate_file_exists!(filename, opts) do
    if !File.exists?(PW.root_dir(opts) <> filename) do
      error("#{PW.root_dir(opts) <> filename} does not exist.")
      System.halt(1)
    end
  end

  # Validate `recipient` is set to something. This does not check that it is a
  # valid GPG recipient.
  defp validate_recipient_set!(opts) do
    if PW.recipient(opts) == nil do
      error("recipient is not set.")
      System.halt(1)
    end
  end

  # Print an appropriate, red error `msg`.
  defp error(msg) do
    IO.ANSI.red <> IO.ANSI.underline <> "Error" <> IO.ANSI.no_underline <> ": #{msg}" <> IO.ANSI.reset |> IO.puts
  end
end
