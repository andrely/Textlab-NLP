module TextlabNLP

  class TreeTaggerConfig
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

      @encoding = opts[:encoding] || :utf8
      @lang = opts[:lang] || nil
    end

    # @private
    def tokenize_cmd
      path = @config[:path]
      lang_config = @config[:languages][@lang]

      tokenize_bin =
          case @encoding
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
          case @encoding
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

    def pipeline_cmd
      path = @config[:path]
      lang_config = @config[:languages][@lang]

      raise NotImplementedError unless lang_config

      cmd =
          case @encoding
            when :utf8
              lang_config[:pipeline_utf8_cmd]
            when :latin1
              lang_config[:pipeline_latin1_cmd]
            else
              raise NotImplementedError
          end

      cmd = File.join(@config[:cmd_dir], cmd)
      cmd = File.join(path, cmd) if path

      cmd
    end

    def sent_tag
      lang_config = @config[:languages][@lang]

      if lang_config and lang_config.has_key?(:sent_tag)
        lang_config[:sent_tag]
      else
        'SENT'
      end
    end

    def encoding
      case @encoding
        when :utf8
          Encoding.find("utf-8")
        when :latin1
          Encoding.find("ascii-8bit")
        else
          raise RuntimeError
      end
    end

    def self.for_lang(lang, encoding=:utf8)
      TreeTaggerConfig.new(lang: lang, encoding: encoding)
    end
  end
end

