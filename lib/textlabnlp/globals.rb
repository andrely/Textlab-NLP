require 'json'
require 'deep_merge'
require 'open3'
require 'io/wait'
require 'stringio'

require_relative 'encoding_converter'

##
# Global functions for managing the location and running of external components.

module TextlabNLP
  ##
  # Error type for malformed config files or values.
  class ConfigError < StandardError; end
  class RunawayProcessError < StandardError; end

  # Location of file containing config defaults
  CONFIG_DEFAULT_FN = 'lib/config_default.json'
  # Default location of file containing default config overrides.
  CONFIG_FN = 'lib/config.json'

  IO_BUF_SIZE = 4096

  # Default setting for echoing of external command output to stdout/stderr.
  @echo_external_command_output = false

  class << self
    attr_accessor :echo_external_command_output
  end

  ##
  # Returns the absolute path to the project root directory.
  #
  # @return [String]
  def TextlabNLP.root_path()
    root = File.join(File.dirname(__FILE__), "..", "..")
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
  # @todo Refactor this into separate class.
  # @todo Generalize the push/pull of IO instances for general use.
  #
  # @param cmd [String] The shell command string. Should not include pipes.
  #
  # @option opts [IO, NilClass] stdin_file IO instance to read input to the shell process from.
  # @option opts [IO, NilClass] stdout_file IO instance to write shell process output to.
  # @option opts [TrueClass, FalseClass] echo_output Echo stdout and stderr of the command to $stdout.
  # @option opts [EncodingConverter] enc_conv Converter from encoding in input/output to encoding expected by process.
  # @option opts [String] error_canary If stderr output matches the canary regex the process is assumed to have failed
  #   and is terminated (used by f.ex. OsloBergenTagger to terminate failed mtag processes).
  # @return [Process::Status] Status of the (terminated) process.
  # @raise [RunawayProcessError] if the error canary is detected on stdout.
  #noinspection RubyEmptyRescueBlockInspection
  def TextlabNLP.run_shell_command(cmd, opts={})
    stdin_file = opts[:stdin_file] || StringIO.new
    stdout_file = opts[:stdout_file] || nil
    stderr_file = opts[:stderr_file] || nil
    echo_output = opts[:echo_output] || @echo_external_command_output
    enc_conv = opts[:enc_conv] || DummyEncodingConverter.new
    canary = opts[:error_canary] || nil

    stdin, stdout, stderr, thr = Open3.popen3 cmd

    # buffers for data that can't be entirely written to the next stream
    stderr_rest = ""
    stdin_data  = ""

    stdout_handler = Proc.new do
      out_data = stdout.readpartial(IO_BUF_SIZE)

      stdout_file.write(enc_conv.to(out_data)) if stdout_file
      $stdout.write out_data if echo_output
    end

    stderr_handler = Proc.new do
      err_data = stderr.readpartial(IO_BUF_SIZE)

      if canary
        # split lines and connect together with next read if necessary
        lines = (stderr_rest + err_data).split("\n")

        if err_data[-1] == "\n"
          stderr_rest = ""
        else
          stderr_rest = lines.pop
        end

        lines.each do |line|
          if line.match(canary)
            thr.exit
            raise RunawayProcessError
          end
        end

      end

      stderr_file.write(enc_conv.to(err_data)) if stderr_file
      $stderr.write err_data if echo_output
    end


    # read and write all streams until all input has been written to stdin
    begin
      until stdin_file.eof?
        read, write = IO.select([stdout,stderr], [stdin])

        (read + write).each do |str|
          if str == stdout
            begin
              stdout_handler.call
            rescue EOFError

            end

          end

          if str == stderr
            begin
              stderr_handler.call
            rescue EOFError

            end
          end

          if str == stdin
            begin
              stdin_data = stdin_data + enc_conv.from(stdin_file.readpartial(IO_BUF_SIZE))

              # non-blocking write to avoid blocking when running tree-tagger
              # keep track of written characters to make sure everything is written
              # and catch WaitWritable to make sure stdin is ready for writing
              begin
                written = stdin.write_nonblock(stdin_data)
                stdin_data = stdin_data[written..-1]
              rescue IO::WaitWritable, Errno::EINTR
                # fall back to select
              end
            rescue EOFError

            end
          end
        end
      end

    rescue Errno::EPIPE => e
      # if we are here the cmd exited early on us
      # dump stderr
      while stderr.ready?
        stderr_handler.call
      end

      raise e
    end

    stdin.close

    # get the rest of the output
    # make sure we wait until output is produced by process
    while thr.alive?
      while stderr.ready?
        stderr_handler.call
      end

      while stdout.ready?
        stdout_handler.call
      end
    end

    stderr.close
    stdout.close

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

  # Get the full path of command line program in shell environment.
  #
  # @param [String] program Shell program name.
  # @return [String] Full path to shell program.
  def TextlabNLP.program_full_path(program)
    out = StringIO.new
    run_shell_command("which #{program}", stdout_file: out)
    full_path = out.string.strip
    raise RuntimeError unless File.exists?(full_path)

    full_path
  end

  OPEN_TAG_REGEX = Regexp.compile("^\\s*<(\\w+)(.*)?>")
  CLOSED_TAG_REGEX = Regexp.compile("^\\s*</(\\w+)>")

  # Parse XML/HTML style tag if present in string.
  #
  # @param [String] str
  # @return [Array] Returns three elements: tag as String, state as Symbol (:open, :closed) and a Hash with the
  #   tag attributes using Symbol keys (ie. :id => "the_id").
  def TextlabNLP.parse_tag(str)
    closed_m = str.match(CLOSED_TAG_REGEX)

    if closed_m
      return closed_m.captures.first, :closed, nil
    end

    open_m = str.match(OPEN_TAG_REGEX)

    if open_m
      attr_str = open_m.captures[1]
      attr= {}

      attr_str.split.each do |s|
        id, val = s.split('=')
        attr[id.to_sym] = TextlabOBTStat::remove_quotes(val.strip)
      end

      return open_m.captures[0], :open, attr
    end

    return nil, nil, nil
  end

  # Returns True if the object is "IO like", ie. it can be passed off for our limited purposes
  # as an IO instance.
  #
  # @param [Object] object
  # @return [TrueClass, FalseClass]
  def TextlabNLP.io_like?(f)
    f.kind_of?(IO) or f.kind_of?(StringIO)
  end

  # Copies the content of from to to, which can be filenames or "IO like" instances.
  #
  # @param [String, IO, StringIO] from
  # @param [String, IO, StringIO] to
  # @return [String, IO, StringIO] The instance passed as the to argument.
  def TextlabNLP.copy(from, to)
    if not io_like?(from)
      File.open(from) do |f|
        copy(f, to)
      end

      to
    elsif not io_like?(to)
      File.open(to, 'w') do |f|
        copy(from, f)
      end

      to
    else
      to.write(from.read)

      to
    end
  end
end
