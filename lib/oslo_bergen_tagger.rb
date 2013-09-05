require 'rbconfig'
require 'stringio'

require_relative 'globals'
require_relative 'logger_mixin'
require_relative 'obt_format_reader'

module TextlabNLP
  ##
  # Class for running the Oslo-Bergen part of speech tagger command line pipeline.
  # @note Not fully implemented
  # @todo non disambiguated taggging of nynorsk
  # @todo fully disambiguated tagging of nynorsk
  # @todo support of all platforms
  # @todo support vertical output
  # @todo support cwb output
  # @todo support different path to grammars than binaries
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
    # @option opts [Symbol] format Symbol specifying format (:raw, :json).
    # @option opts [Symbol] lang Parse Bokmal (:bm) or Nynorsk (:nn).
    # @return [String, Array]
    def annotate(opts={})
      mtag_only = opts[:mtag_only] || nil
      disambiguate = opts[:disambiguate] || nil
      format = opts[:format] || :json
      file = opts[:file] || nil
      lang = opts[:lang] || :bm

      # IO instance is only input for now
      raise NotImplementedError if file.nil?

      if mtag_only
        out = annotate_mtag(file, lang)
      elsif disambiguate
        raise NotImplementedError
      else
        out = annotate_obt(file, lang)
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
    def annotate_mtag(file, lang)
      cmd = mtag_cmd(lang)
      out = StringIO.new
      TextlabNLP.run_shell_command(cmd, file, out)

      out.string
    end

    ##
    # @private
    def annotate_obt(file, lang)
      cmd = "#{mtag_cmd(lang)} | #{vislcg3_cmd} -C latin1 --codepage-input utf-8 -g #{grammar_path(lang, false)} --codepage-output utf-8 --no-pass-origin -e"
      out = StringIO.new
      TextlabNLP.run_shell_command(cmd, file, out)

      out.string
    end

    ##
    # Checks that external commands are configured and working correctly
    # @return [TrueClass, FalseClass]
    # @todo check output where possible
    def available?
      # force return value to true/false
      #noinspection RubySimplifyBooleanInspection
      !(TextlabNLP.runnable?(mtag_cmd) == false) and !(TextlabNLP.runnable?(vislcg3_cmd) == false)
    end

    ##
    # @private
    def mtag_cmd(lang=:bm)
      path = @config[:path]

      if path
        mtag_path = File.join(path, @config[:mtag][platform])
      else
        mtag_path = @config[:mtag][platform]
      end

      if lang == :bm
        "#{mtag_path} -wxml"
      elsif lang == :nn
        "#{mtag_path} -wxml -nno"
      else
        raise NotImplementedError
      end
    end

    ##
    # @private
    def grammar_path(lang=:bm, disambiguate=false)
      raise NotImplementedError unless [:bm, :nn].member?(lang)

      path = @config[:path]

      lang = :bm_prestat if lang == :bm and disambiguate

      if path
        File.join(path, @config[:grammar][lang])
      else
        @config[:grammar][lang]
      end
    end

    ##
    # @private
    def vislcg3_cmd
      path = @config[:path]

      if path
        File.join(path, @config[:vislcg3][platform])
      else
        @config[:vislcg3][platform]
      end
    end

    ##
    # @private
    def platform
      if @platform.nil?
        host_os = RbConfig::CONFIG['host_os']

        @platform =
            case host_os
              when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                :win
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
