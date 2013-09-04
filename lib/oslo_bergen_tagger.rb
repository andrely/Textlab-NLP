require 'rbconfig'
require 'stringio'

require_relative 'globals'
require_relative 'logger_mixin'
require_relative 'obt_format_reader'

module TextlabNLP
  ##
  # Class for running the Oslo-Bergen part of speech tagger command line pipeline.
  # @note Not fully implemented
  # @todo mtag nynorsk support
  # @todo non disambiguated taggging of bokmal
  # @todo non disambiguated taggging of nynorsk
  # @todo fully disambiguated tagging of nynorsk
  # @todo support of all platforms
  # @todo support vertical output
  # @todo support cwb output
  class OsloBergenTagger

    include Logging

    ##
    # @option opts [Hash] config Fully populated json config as a Hash instance.
    def initialize(opts={})
      @config = opts[:config] || TextlabNLP.config[:obtagger]

      # inject this value for testing only
      @platform = opts[:platform] || nil
    end

    ##
    # Annotates the given text with the Oslo-Bergen tagger pipeline.
    #
    # @option opts [IO, StringIO] file Readable instance with input too be annotated.
    # @return [String]
    def annotate(opts={})
      mtag_only = opts[:mtag_only] || nil
      disambiguate = opts[:disambiguate] || nil
      format = opts[:format] || :json
      file = opts[:file] || nil

      # IO instance is only input for now
      raise NotImplementedError if file.nil?

      if mtag_only
        out = annotate_mtag(file)
      else
        raise NotImplementedError
      end

      # if raw output is requested we just return it
      return out if format == :raw

      # convert to other formats through json
      reader = TextlabNLP::OBTFormatReader.new(StringIO.new(out), use_static_puntuation=true)
      out = []
      reader.each_sentence { |s| out << s }

      if format == :json
        out
      elsif format == :vrt
        raise NotImplementedError unless disambiguate
        # json_to_vrt(out)
      elsif format == :cwb
        raise NotImplementedError unless disambiguate
        # json_to_cwb(out)
      else
        raise NotImplementedError
      end
    end

    ##
    # @private
    def annotate_mtag(file)
      cmd = mtag_cmd
      out = StringIO.new
      TextlabNLP.run_shell_command(cmd, file, out)

      out.string
    end

    ##
    # Checks that external commands are configured and working correctly
    # @return [TrueClass, FalseClass]
    def available?
      # force return value to true/false
      #noinspection RubySimplifyBooleanInspection
      !(TextlabNLP.runnable?(mtag_cmd) == false)
    end

    ##
    # @private
    def mtag_cmd(lang=:bm)
      if lang == :bm
        "#{File.join(@config[:path], @config[:mtag][platform])} -wxml"
      elsif lang == :nn
        "#{File.join(@config[:path], @config[:mtag][platform])} -wxml -nno"
      else
        raise NotImplementedError
      end
    end

    ##
    # @private
    def grammar_path(lang=:bm, disambiguate=false)
      raise NotImplementedError
    end

    ##
    # @private
    def platform
      if @platform.nil?
        host_os = RbConfig::CONFIG['host_os']

        @platform =
            case host_os
              when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                :windows
              when /darwin|mac os/
                :osx
              when /linux/
                :linux
              when /solaris|bsd/
                :unix
              else
                raise(ConfigError, "unknown os: #{host_os.inspect}")
            end
      end

      @platform
    end
  end
end
