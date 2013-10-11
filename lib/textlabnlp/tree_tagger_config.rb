require_relative 'globals'

module TextlabNLP

  class TreeTaggerConfig

    attr_reader :enc_conv

    # @option opts [Symbol] lang ISO-639-2 language code (:fra or :swe).
    # @option opts [String] encoding Input encoding (utf-8 or latin1).
    def initialize(opts={})
      @config = opts[:config] || nil

      if @config
        @config = @config.deep_merge(TextlabNLP.config[:treetagger])
      else
        @config = TextlabNLP.config[:treetagger]
      end

      # inject these values for testing only
      #noinspection RubyResolve
      @config = opts[:replace_config] || @config

      @encoding = opts[:encoding] || "utf-8"
      @lang = opts[:lang] || raise(ArgumentError)

      # See if treetagger is available in the requested encoding.
      # If not we set up an EncodingConverter which will be passed to the shell command runner.
      if @config[:languages][@lang][:encoding].include?(@encoding.to_s)
        @enc_conv = nil
        @tool_encoding = @encoding
      else
        @tool_encoding = prefered_encoding
        @enc_conv = EncodingConverter.new(@encoding, @tool_encoding)
      end
    end

    # @private
    # @return [Symbol]
    def prefered_encoding
      encodings = @config[:languages][@lang][:encoding]

      if encodings.include?("utf-8")
        # if possible use UTF-8
        "utf-8"
      else
        # otherwise use the first encoding for this language in the default config
        encodings.first
      end
    end

    # @private
    def tokenize_cmd
      path = @config[:path]
      lang_config = @config[:languages][@lang]

      tokenize_bin =
          case @encoding
            when "latin1"
              @config[:tokenize_latin1_cmd]
            when "utf-8"
              @config[:tokenize_utf8_cmd]
            else
              raise NotImplementedError
          end

      tokenize_path = File.join(@config[:cmd_dir], tokenize_bin)
      tokenize_path = File.join(path, tokenize_path) if path

      args = [tokenize_path]

      abbrev_path =
          case @encoding
            when "latin1"
              lang_config[:abbreviations_latin1_file] if lang_config
            when "utf-8"
              lang_config[:abbreviations_utf8_file] if lang_config
            else
              raise NotImplementedError
          end

      abbrev_path = File.join(@config[:lib_dir], abbrev_path) if abbrev_path
      args << "-a #{File.join(path, abbrev_path)}" if path and abbrev_path

      #noinspection RubyCaseWithoutElseBlockInspection
      case @lang
        when :fra
          args << '-f'
        when :ita
          args << '-i'
        when :eng
          args << '-e'
      end

      args.join(' ')
    end

    # @private
    def pipeline_cmd
      path = @config[:path]
      lang_config = @config[:languages][@lang]

      raise NotImplementedError unless lang_config

      cmd =
          case @tool_encoding
            when "utf-8"
              lang_config[:pipeline_utf8_cmd]
            when "latin1"
              lang_config[:pipeline_latin1_cmd]
            else
              raise NotImplementedError
          end

      if cmd
        cmd = File.join(@config[:cmd_dir], cmd)
        cmd = File.join(path, cmd) if path
      end

      cmd
    end

    # @private
    def sent_tag
      lang_config = @config[:languages][@lang]

      if lang_config and lang_config.has_key?(:sent_tag)
        lang_config[:sent_tag]
      else
        'SENT'
      end
    end

    # @private
    def encoding
      case @encoding
        when "utf-8"
          Encoding.find("utf-8")
        when "latin1"
          Encoding.find("ascii-8bit")
        else
          raise RuntimeError
      end
    end

    # Treetagger configuration for specified language.
    # @see #initialize for full list of options.
    #
    # @param [Object] lang ISO-639-2 language code (:fra or :swe).
    # @return [TreeTaggerConfig]
    def self.for_lang(lang, opts={})
      opts[:lang] = lang
      TreeTaggerConfig.new(opts)
    end

    def self.lang_available?(lang, opts={})
      opts[:lang] = lang
      config = TreeTaggerConfig.new(opts)
      TextlabNLP.runnable?(config.pipeline_cmd) # and TextlabNLP.runnable?(config.tokenize_cmd)
    end
  end
end

