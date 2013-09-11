require_relative 'tree_tagger_config'

module TextlabNLP

  # Class for running TreeTagger with included models and tools.
  # @note Not fully implemented.
  class TreeTagger

    # @option opts [TreeTaggerConfig] config Mandatory configuration instance.
    def initialize(opts={})
      @config = opts[:config] || raise(ArgumentError)
    end

    # Tokenize input.
    #
    # @param [IO, StringIO] in_file
    # @param [IO, StringIO] out_file
    def tokenize(in_file, out_file)
      TreeTagger.tokenize(@config, in_file, out_file)
    end

    # Tokenize input with specified configuration.
    #
    # @param [TreeTaggerConfig] config
    # @param [IO, StringIO] in_file
    # @param [IO, StringIO] out_file
    def self.tokenize(config, in_file, out_file)
      cmd = config.tokenize_cmd
      TextlabNLP.run_shell_command(cmd, stdin_file: in_file, stdout_file: out_file)
    end

    # Tag and lemmatize input.
    # @see #self.annotate for complete list of options.
    def annotate(opts={})
      opts[:config] = @config unless opts.has_key?(:config)

      TreeTagger.annotate(opts)
    end

    # Tag and lemmatize input with specified configuration.
    #
    # @option opts [Symbol] format Output format (:json or :raw).
    # @option opts [IO, StringIO] file IO like object to read input from.
    # @option opts [TreeTaggerConfig] config Mandatory configuration instance.
    def self.annotate(opts={})
      format = opts[:format] || :json
      file = opts[:file] || raise(ArgumentError)
      config = opts[:config] || raise(ArgumentError)
      out_file = StringIO.new

      out_file.set_encoding(config.encoding)

      cmd = config.pipeline_cmd
      TextlabNLP.run_shell_command(cmd, stdin_file: file, stdout_file: out_file)

      if format == :raw
        out_file.string
      elsif format == :json
        out_file.rewind
        TreeTagger.tt_to_json(out_file, config.sent_tag)
      else
        raise NotImplementedError
      end
    end

    # @private
    # Converts Treetagger output to JSON format.
    #
    # @param [Object] tt_file IO like instance to read Treetagger output from.
    # @param [String] sent_tag Sentence end tag used by Treetagger model.
    # @return [Array<Array>>] The Treetagger output in JSON format as an array of sentences.
    def self.tt_to_json(tt_file, sent_tag="SENT")
      sentence = []
      text = []

      tt_file.readlines.each do |line|
        tokens = line.strip.split("\t")
        raise RuntimeError unless tokens.count == 3

        word, tag, lemma = tokens
        sentence << { word: word, annotation: [{ tag: tag, lemma: lemma}]}

        if tag == sent_tag
          text.push(sentence)
          sentence = []
        end
      end

      text.push(sentence) unless sentence.empty?

      text
    end

    # Treetagger configurations for specific languages.
    #
    # @param [Symbol] lang ISO-639-2 language code (:fra or :swe).
    # @param [Symbol] encoding Text encoding of input (:utf8 or :latin1).
    # @return [TreeTaggerConfig]
    def self.for_lang(lang, encoding=:utf8)
      TreeTagger.new(config: TreeTaggerConfig.for_lang(lang, encoding))
    end
  end
end
