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

  # Default setting for echoing of external command output to stdout/stderr.
  ECHO_EXTERNAL_COMMAND_OUTPUT = false

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
  # @todo This needs more cleaning up.
  #
  # @param cmd [String] The shell command string. Should not include pipes.
  #
  # @option opts [IO, NilClass] stdin_file IO instance to read input to the shell process from.
  # @option opts [IO, NilClass] stdout_file IO instance to write shell process output to.
  # @option opts [TrueClass, FalseClass] echo_output Echo stdout and stderr of the command to $stdout.
  # @return [Process::Status] Status of the (terminated) process.
  def TextlabNLP.run_shell_command(cmd, opts={})
    stdin_file = opts[:stdin_file] || StringIO.new
    stdout_file = opts[:stdout_file] || nil
    echo_output = opts[:echo_output] || ECHO_EXTERNAL_COMMAND_OUTPUT

    # @return [Process::Status] Shell command exit status.
    err = ""

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
          line = stdout.readline
          stdout_file.write(line) if stdout_file
          $stdout.puts line if echo_output
        end

        while stderr.ready?
          line = stderr.readline
          err += line
          $stderr.puts line if echo_output
        end
      end

      rescue Errno::EPIPE => e
        # if we are here the cmd exited early on us
        # dump stderr
        err += stderr.read
        $stderr.puts(err) if echo_output

        raise e
      end

      stdin.close

      # get the rest of the output
      stdout_file.write(stdout.read)

      stdout.close

      err += stderr.read
      $stderr.puts(err) if echo_output
      stderr.close

      # wait and get get Process::Status
      s = thr.value

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
      run_shell_command(cmd, stdin_file: StringIO.new(''), stdout_file: out)

      return out.string
    rescue Errno::ENOENT
      return false
    end
  end
end
