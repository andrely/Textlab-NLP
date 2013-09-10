module TextlabNLP
  ##
  # Reads OBT formatted files into a structured formatted. Can be iterated over.
  # Robustly handles many ad-hoc extensions to the OBT format.
  # @note Only returns annotation, not correct, tracing and "tags".
  # @todo cleanup code (adapted from TagAnnotator)
  # @todo Improve interface
  # @todo implement Enumerable
  # @todo store all parsed data and post/preamble data
  class OBTFormatReader
    attr_reader :file, :postamble

    @peeked_word_record = nil
    @peeked_orig_word_record = nil
    @peeked_preamble = nil
    @postamble = nil

    ##
    #
    # @param [IO, StringIO] readable IO like instance with text to parse.
    # @param [TrueClass, FalseClass] use_static_punctuation If true sentences are split on fixed punctuation
    #   characters, if false Multitagger sentence end annotation are used sto split sentences.
    def initialize(readable, use_static_punctuation = false)
      @file = readable

      @word_regex = Regexp.compile('\"<(.*)>\"')
      @tag_lemma_regex = Regexp.compile('^;?\s+\"(.*)\"(.*)')
      @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
      @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
      @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

      @correct_marker = '<Correct!>'
      @capitalized_marker = '<*>'
      @end_of_sentence_marker = '<<<'

      @use_static_punctuation = use_static_punctuation
    end

    ##
    # Iterator returning the next sentence from the parsed text.
    def each_sentence
      while sentence = get_next_sentence(@file)
        yield sentence
      end
    end

    ##
    # @private
    def get_next_sentence(f)
      sentence = []

      while TRUE
        begin
          end_of_sent = false
          word = get_next_word(f)

          break if word.nil?

          sentence << word

          end_of_sent = true if word[:form].match(@punctuation_regex) and @use_static_punctuation
          end_of_sent = true if word[:end_of_sentence_p] and not @use_static_punctuation
          word.delete(:end_of_sentence_p) if word.has_key?(:end_of_sentence_p)

          break if end_of_sent
        end
      end

      return nil if sentence.empty?

      sentence
    end

    ##
    # @private
    def get_next_word(f)
      word = {}
      begin
        string, orig_string, _ = get_word_header(f)
        word[:word] = orig_string
        word[:form] = string
      rescue EOFError
        return nil
      end

      get_word_tags(f, word)

      raise RuntimeError if word[:annotation].empty?

      word
    end

    ##
    # @private
    def get_word_tags(f, word)
      word[:annotation] = []

      while TRUE
        begin
          line = next_nonempty_line(f)
        rescue EOFError
          break
        end

        if is_tag_line(line)
          tag = {}
          lemma, string, _, _, u = get_tag(line)
          tag[:lemma] = lemma
          tag[:tag] = string

          word[:end_of_sentence_p] = u

          word[:annotation] << tag
        else
          peek line
          break
        end
      end

      raise RuntimeError if word[:annotation].empty?

      word[:annotation]
    end

    ##
    # @private
    def get_word_header(f)
      if @peeked_word_record
        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      elsif @peeked_orig_word_record
        @peeked_word_record = get_word(next_nonempty_line(f))
        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      else
        while line = next_nonempty_line(f)
          peek line

          break if @peeked_word_record
        end

        header = [@peeked_word_record, @peeked_orig_word_record, @peeked_preamble]
      end

      unpeek

      header
    end

    ##
    # @private
    def next_nonempty_line(f)
      line = f.readline

      if line.strip.empty?
        return next_nonempty_line(f)
      end

      line
    end

    ##
    # @private
    def peek(line)
      if is_word_line(line)
        @peeked_word_record = get_word(line)
      elsif is_orig_word_line(line)
        @peeked_orig_word_record = get_orig_word(line)
      else
        if @peeked_preamble
          @peeked_preamble << line.strip
        else
          @peeked_preamble = [line.strip]
        end
      end
    end

    ##
    # @private
    def unpeek()
      @peeked_word_record = nil
      @peeked_orig_word_record = nil
      @peeked_preamble = nil
    end

    def is_word_line(line)
      line.match(@word_regex)
    end

    ##
    # @private
    def get_word(line)
      if (m = line.match(@word_regex)) then
        return m[1]
      end

      nil
    end

    ##
    # @private
    def is_tag_line(line)
      line.match(@tag_regex)
    end

    ##
    # @private
    def get_tag(line)
      if (m = line.match(@tag_lemma_regex))
        lemma = m[1]
        rest = m[2].split

        if rest.include? @correct_marker
          correct = TRUE
          rest.delete(@correct_marker)
        else
          correct = FALSE
        end

        if rest.include? @capitalized_marker
          capitalized = TRUE
          rest.delete(@capitalized_marker)
        else
          capitalized = FALSE
        end

        if rest.include? @end_of_sentence_marker
          end_of_sentence = TRUE
          rest.delete(@end_of_sentence_marker)
        else
          end_of_sentence = FALSE
        end

        tag = rest.join(" ")

        return [lemma, tag, correct, capitalized, end_of_sentence]
      end

      nil
    end

    ##
    # @private
    # Checks if the passed line contains an original word string.
    # @param [String] line An OB output line
    # @return [NilClass, TrueClass] True if the line matches the original word line format, nil if not
    def is_orig_word_line(line)
      line.match(@orig_word_regex)
    end

    ##
    # @private
    # Extracts the original word string if thtis line matches the original word line format, ie.
    # the word string in an XML word tag.
    # @param [String] line An OB output line
    # @return [String, NilClass] The original word string if the line matches, nil otherwise
    def get_orig_word(line)
      if m = line.match(@orig_word_regex)
        return m[1]
      end

      nil
    end
  end
end