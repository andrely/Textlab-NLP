require 'json'
require 'deep_merge'
require 'open3'
require 'io/wait'

##
# Global functions for managing the location and running of external components.

module TextlabNLP
  ##
  # Error type for malformed config files or values.
  class ConfigError < StandardError; end

  # Location of file containing config defaults
  CONFIG_DEFAULT_FN = 'lib/config_default.json'
  # Default location of file containing default config overrides.
  CONFIG_FN = 'lib/config.json'

  EXTERNAL_COMMAND_SILENT = false

  ##
  # Returns the absolute path to the project root directory.
  #
  # @return [String]
  def TextlabNLP.root_path()
    root = File.join(File.dirname(__FILE__), "..")
    root = File.absolute_path(root)

    return root
  end

  ##
  # Reads JSON based config file into a Hash instance.
  #
  # @param [IO] file JSON formatted config file with a single JSON object
  # @return [Hash] Hash based on the JSON config.
  # @raise [ConfigError] if unable to parse the config file.
  def TextlabNLP.read_config_file(file)
    config = JSON.parse(file.read(), {:symbolize_names => true})

    # file should contain a single object parsed into a Hash
    raise(ConfigError, "Failed to parse config file") if not config.kind_of?(Hash)

    config
  end

  ##
  # Reads and returns a Hash instance with the default config.
  #
  # @return [Hash]
  def TextlabNLP.default_config()
    File.open(File.join(root_path, CONFIG_DEFAULT_FN), 'r') { |f| read_config_file(f) }
  end

  ##
  # Read config from specified file or default config location and merge with default config
  # values.
  #
  # @param [IO, String] file Path to file or IO object with single JSON object with config values.
  # @return [Hash] Hash instance with config values.
  def TextlabNLP.config(file=nil)
    if file.nil?
      file = File.join(root_path, CONFIG_FN)

      # if the default overrides does not exist just return the defaults
      return default_config unless File.exists?(file)
    end

    if file.kind_of?(String)
      config = File.open(file, 'r') { |f| read_config_file(f) }
    else
      config = read_config_file(file)
    end

    # merge overrides with defaults
    config.deep_merge(default_config)
  end

  ##
  # Runs an external shell command.
  #
  # @note Stderr output is written to STDERR. Stdout output is written to STDOUT if no stdout_file
  #   argument is given.
  # @todo This needs some serious cleaning up and proper handling of output to stdout/stderr.
  #
  # @param cmd [String] The shell command string. Should not include pipes.
  # @param stdin_file [IO, NilClass] IO instance to read input to the shell process from.
  # @param stdout_file [IO, NilClass] IO instance to write shell process output to.
  # @return [Process::Status] Shell command exit status.
  def TextlabNLP.run_shell_command(cmd, stdin_file=nil, stdout_file=nil)
    oe = ""
    err = ""

    if stdin_file
      stdin, stdout, stderr, thr = Open3.popen3 cmd


      # read and write stdin/stdout/stderr to avoid deadlocking on processes that blocks on writing.
      # e.g. HunPos
      begin
        until stdin_file.eof?

          # wait until stdout is emptied until we try to write or hunpos-tag will block
          until stdout.ready?
            stdin.puts(stdin_file.readline)

            # break completely out if there is no more inout
            break if stdin_file.eof?
          end

          break if stdin_file.eof?

          while stdout.ready?
            if stdout_file
              stdout_file.write(stdout.readline)
            else
              oe += stdout.readline
            end
          end

          while stderr.ready?
            err += stderr.readline
          end
        end

      rescue Errno::EPIPE => e
        # if we are here the cmd exited early on us
        # dump stdout and stderr
        puts err + stderr.read
        puts oe + stdout.read

        raise e
      end

      stdin.close

      # get the rest of the output
      if stdout_file
        stdout_file.write(stdout.read)
      else
        oe += stdout.read
      end

      stdout.close

      err += stderr.read
      stderr.close

      # wait and get get Process::Status
      s = thr.value
    else
      out, err, s = Open3.capture3(cmd)

      if stdout_file
        stdout_file.write(out)
      end
    end

    # echo errors on STDERR
    STDERR.puts(err) if not EXTERNAL_COMMAND_SILENT

    # echo command output
    if stdout_file.nil?
      puts(oe) if not EXTERNAL_COMMAND_SILENT
    else
      #noinspection RubyScope
      puts(out) if not EXTERNAL_COMMAND_SILENT
    end

    return s
  end

  ##
  # Runs the command string and returns the output if successful. Otherwise returns false.
  #
  # @param cmd [String] Shell command string
  # @return [String, FalseClass]
  def TextlabNLP.runnable?(cmd)
    begin
      out = StringIO.new
      # some commands always waits for input
      run_shell_command(cmd, StringIO.new(''), out)

      return out.string
    rescue Errno::ENOENT
      return false
    end
  end
end
