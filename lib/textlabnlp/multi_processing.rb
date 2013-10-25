require 'logger'
require 'io/wait'

module TextlabNLP
  # Batch friendly multiprocessing.
  # TextlabNLP.mp_map() runs passed block on a process pool with builtin log connection.

  # Error class for errors occurring when scheduling and running mp jobs.
  class MPError < StandardError; end

  # default mode is forking directly
  MP_DEFAULT_MODE = :direct
  # default is to use 3/4 of processors (rounding down)
  MP_DEFAULT_PROC_USAGE = 0.75

  # @return [Integer] Number of processors in system.
  # @raise [RuntimeError] If called on non-supported system. 
  #noinspection RubyResolve
  def TextlabNLP.processor_count
    case RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`.to_i
      when /darwin/
        ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      when /linux/
        `cat /proc/cpuinfo | grep processor | wc -l`.to_i
      when /freebsd/
        `sysctl -n hw.ncpu`.to_i
      when /mswin|mingw/
        require 'win32ole'
        wmi = WIN32OLE.connect("winmgmts://")
        cpu = wmi.ExecQuery("select NumberOfCores from Win32_Processor") # TODO count hyper-threaded in this
        cpu.to_enum.first.NumberOfCores
      else
        raise RuntimeError
    end
  end


  # @return [Integer] Default number of processors to use (MP_DEFAULT_PROC_USAGE of
  #   processors in system rounding down).
  def TextlabNLP.mp_default_n
    (TextlabNLP.processor_count * MP_DEFAULT_PROC_USAGE).floor
  end

  # Runs the block for each input in the inputs Array in a a separate process and returns the results.
  #
  # @param [Array] inputs Inputs that will be passed to the block.
  # @yield [input, log_str] Input intstance from Array passed as argument and IO stream for logging.
  # @option opts [Symbol] mode Processing mode :direct (default) or :thread.
  # @option opts [Integer] n Number of jobs to run simultaneously.
  # @option opts [Integer] log_level Log severity level as defined in the Logger namespace (default is Logger::INFO).
  # @return [Array] Return values from block. Not necessarily in order.
  # @raise [MPError] If an error occurs during running or scheduling of jobs.
  # @raise [ArgumentError] If illegal arguments are passed.
  def TextlabNLP.mp_map(inputs, opts={}, &block)
    mode = opts[:mode] || MP_DEFAULT_MODE

    if mode == :thread
      TextlabNLP.mp_map_thread(inputs, opts, &block)
    elsif mode == :direct
      TextlabNLP.mp_map_direct(inputs, opts, &block)
    else
      raise ArgumentError
    end
  end

  # @private
  # Runs each process in a separate thread. Possibly slower than mp_map_direct which forks directly.
  def TextlabNLP.mp_map_thread(inputs, opts={})
    # make sure n is the size of input or lower
    n = opts[:n] || TextlabNLP.mp_default_n
    log_level = opts[:log_level] || Logger::INFO

    n = inputs.count if inputs.count < n

    logger = Logger.new(STDERR)

    unless block_given?
      raise ArgumentError
    end

    mutex = Mutex.new

    threads = []
    results = []

    log_read, log_write = IO.pipe

    # Start n-threads which grabs more input as they finish each job
    n.times do
      threads << Thread.new do
        while true
          read, write = IO.pipe

          input = nil

          mutex.synchronize do
            input = inputs.shift
          end

          break if input.nil?

          pid = Process.fork do
            read.close
            log_read.close
            result = yield(input, log_write)
            # write result to parent process
            Marshal.dump(result, write)
            log_write.close
            write.close
            exit!(0)
          end

          write.close

          # get the result and wait for child
          result = read.read
          Process.wait(pid)
          raise TextlabNLP::MPError if result.empty?

          # decode and store the result
          mutex.synchronize do
            #noinspection RubyResolve
            results.push(Marshal.load(result))
          end

          read.close
        end
      end
    end

    # run threads and get logs if any
    log_rest = ""

    while threads.detect { |thr| thr.alive? }
      threads.each do |thr|
        # let threads run for a second at a time (tune this for performance?)
        thr.join(1.0)
      end

      # get logs non-blocking but make sure we don't lose any data from incomplete entries
      while log_read.ready?
        log_rest += log_read.readpartial(1024)

        log_msgs = log_rest.split("\n")

        if log_rest[-1] == "\n"
          log_rest = ""
        else
          log_rest = log_msgs.pop
        end

        log_msgs.each { |msg| logger.log(log_level, msg) }
      end

    end

    log_read.close
    log_write.close

    results
  end

  # @private
  # Forks all jobs directly, does not need to schedule threads.
  def TextlabNLP.mp_map_direct(inputs, opts={})
    # make sure n is the size of input or lower
    n = opts[:n] || TextlabNLP.mp_default_n
    log_level = opts[:log_level] || Logger::INFO

    n = inputs.count if inputs.count < n

    logger = Logger.new(STDERR)

    unless block_given?
      raise ArgumentError
    end

    result = []
    pids = []

    mutex = Mutex.new

    read, write = IO.pipe
    log_read, log_write = IO.pipe

    # "closure" for spawning jobs
    do_fork = Proc.new do |input|
      pid = Process.fork do
        read.close
        result = yield(input, log_write)

        # write result to shared pipe
        # @todo check that this is necessary and works
        mutex.synchronize do
          Marshal.dump(result, write)
        end
      end

      pid
    end

    # fork n jobs and store running pids
    n.times do
      input = inputs.shift

      pids << do_fork.call(input)
    end

    # wait for existing processes and start new ones while keeping an updated running pid list
    until pids.empty?
      begin
        pid, _ = Process.wait2
        # child is finished: remove pid, get result and start new job.
        pids.delete(pid)

        while read.ready?
          #noinspection RubyResolve
          result << Marshal.load(read)
        end

        input = inputs.shift
        next if input.nil?

        pids << do_fork.call(input)

        # get and pass on logs non-blocking while not missing any "hanging data"
        while log_read.ready?
          log_rest += log_read.readpartial(1024)

          log_msgs = log_rest.split("\n")

          if log_rest[-1] == "\n"
            log_rest = ""
          else
            log_rest = log_msgs.pop
          end

          log_msgs.each { |msg| logger.log(log_level, msg) }
        end
      rescue SystemCallError
        # no processes to wait for
      end
    end

    write.close
    log_write.close

    # get any pending results
    while read.ready?
      #noinspection RubyResolve
      result << Marshal.load(read)
    end

    read.close
    log_read.close

    result
  end
end