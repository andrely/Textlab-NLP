module TextlabNLP

  # Class for running TreeTagger with included models and tools.
  # @note NOt fully implemented.
  class TreeTagger

    # @option opts [Hash] config Json config overriding defaults as a Hash instance.
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
    end

    # @private
    def tokenize_cmd(lang, encoding=:utf8)
      path = @config[:path]
      lang_config = @config[:languages][lang]

      tokenize_bin =
          case encoding
            when :latin1
              @config[:tokenize_latin1_cmd]
            when :utf8
              @config[:tokenize_utf8_cmd]
            else
              raise NotImplementedError
      end

      tokenize_path = File.join(@config[:cmd_dir], tokenize_bin)
      tokenize_path = File.join(path, tokenize_path) if path

      args = [tokenize_path]

      abbrev_path =
          case encoding
            when :latin1
              lang_config[:abbreviations_latin1_file] if lang_config
            when :utf8
              lang_config[:abbreviations_utf8_file] if lang_config
            else
              raise NotImplementedError
          end

      abbrev_path = File.join(@config[:lib_dir], abbrev_path) if abbrev_path
      args << "-a #{File.join(path, abbrev_path)}" if path and abbrev_path

      #noinspection RubyCaseWithoutElseBlockInspection
      case lang
        when :fra
          args << '-f'
        when :ita
          args << '-i'
        when :eng
          args << '-e'
      end

      args.join(' ')
    end

    # Tokenize input with specified tokenizer.
    #
    # @param [IO, StringIO] in_file
    # @param [IO, StringIO] out_file
    # @param [Symbol] lang Language of the input text (three letter iso-639-2 code, :fra specifically supported).
    # @param [Symbol] encoding Input/output encoding (:utf8, :latin1).
    def tokenize(in_file, out_file, lang, encoding=:utf8)
      cmd = tokenize_cmd(lang, encoding)
      TextlabNLP.run_shell_command(cmd, stdin_file: in_file, stdout_file: out_file)
    end
  end
end
