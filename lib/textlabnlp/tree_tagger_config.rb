require_relative 'globals'
require_relative 'logger_mixin'

module TextlabNLP

  class TreeTaggerConfig

    include Logging

    attr_reader :enc_conv, :type

    # @option opts [Symbol] lang ISO-639-2 language code (:fra or :swe).
    # @option opts [String] encoding Input encoding (utf-8 or latin1).
    def initialize(opts={})
      @config = opts[:config] || nil
      @type = opts[:type]

      if @config
        @config = @config.deep_merge(TextlabNLP.config[:treetagger])
      else
        @config = TextlabNLP.config[:treetagger]
      end

      # inject these values for testing only
      #noinspection RubyResolve
      @config = opts[:replace_config] || @config

      @encoding = opts[:encoding] || "utf-8"
      @lang = opts[:lang] || nil
      @model_fn = opts[:model_fn] || nil

      unless @model_fn or @config[:languages].has_key?(@lang)
        raise ArgumentError
      end

      # See if treetagger is available in the requested encoding.
      # If not we set up an EncodingConverter which will be passed to the shell command runner.
      unless @model_fn
        if @config[:languages][@lang][:encoding].include?(@encoding.to_s)
          @enc_conv = nil
          @tool_encoding = @encoding
        else
          @tool_encoding = prefered_encoding
          @enc_conv = EncodingConverter.new(@encoding, @tool_encoding)
        end
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
    def tag_cmd
      bin = File.join(@config[:path], @config[:bin_dir], @config[:tag_bin])
      "#{bin} -token -lemma -sgml #{@model_fn}"
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
      opts[:type] = :lang_pipeline
      TreeTaggerConfig.new(opts)
    end

    def self.lang_available?(lang, opts={})
      opts[:lang] = lang
      config = TreeTaggerConfig.new(opts)
      TextlabNLP.runnable?(config.pipeline_cmd) # and TextlabNLP.runnable?(config.tokenize_cmd)
    end

    # Train a TreeTagger model from training data files and return a TreeTaggerConfig instance
    # for running the model.
    #
    # @param [Object] train Treetagger formatted training file/IO like.
    # @param [Object] open Treetagger open class file/IO like.
    # @param [Object] lexicon Treetagger lexicon file/IO like.
    # @param [Object] model_fn File to write the TreeTagger model to.
    # @option opts [String] encoding Training data/model encoding
    # @option opts [Hash] config
    # @option opts [Symbol] lang
    #
    # @return [TreeTaggerConfig]
    def self.train(train, open, lexicon, model_fn, opts={})
      encoding = opts[:encoding] || 'utf-8'
      config = opts[:config] || {}
      lang = opts[:lang] || nil

      config = config.deep_merge(TextlabNLP.config[:treetagger])

      if [train, open, lexicon].detect { |f| TextlabNLP.io_like?(f) }
        Dir.mktmpdir('textlabnlp') do |dir|
          if TextlabNLP.io_like?(train)
            train = TextlabNLP.copy(train, File.join(dir, 'train'))
          end

          if TextlabNLP.io_like?(open)
            open = TextlabNLP.copy(open, File.join(dir, 'open'))
          end

          if TextlabNLP.io_like?(lexicon)
            lexicon = TextlabNLP.copy(lexicon, File.join(dir, 'lexicon'))
          end

          self.train(train, open, lexicon, model_fn, opts)
        end
      else
        bin = File.join(config[:path], config[:bin_dir], config[:train_bin])

        if encoding == 'utf-8'
          bin += " -utf8"
        end

        cmd = "#{bin} #{lexicon} #{open} #{train} #{model_fn}"

        Logging.logger.info("Training TreeTagger model with command #{cmd}")

        TextlabNLP.run_shell_command(cmd)

        TreeTaggerConfig.new(config: config, model_fn: model_fn,
                             lang: lang, encoding: encoding, type: :param_file)
      end
    end
  end
end

