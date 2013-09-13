require_relative 'globals'

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

    # XML tag containing sentences in TEI documents.
    SENT_SEG_TAG = 's'
    OPEN_SENT_TAG_REGEX = Regexp.compile("^\\s*<#{SENT_SEG_TAG}(.*)?>")
    CLOSED_SENT_TAG_REGEX = Regexp.compile("^\\s*</#{SENT_SEG_TAG}>")

    ##
    #
    # @param [IO, StringIO] readable IO like instance with text to parse.
    # @param [TrueClass, FalseClass] use_static_punctuation If true sentences are split on fixed punctuation
    #   characters, if false Multitagger sentence end annotation are used sto split sentences.
    def initialize(readable, opts={})
      @file = readable
      @sent_seg = opts[:sent_seg] || :static

      @word_regex = Regexp.compile('\"<(.*)>\"')
      @tag_lemma_regex = Regexp.compile('^;?\s+\"(.*)\"(.*)')
      @tag_regex = Regexp.compile('^;?\s+\"(.*)\"\s+([^\!]*?)\s*(<\*>\s*)?(<\*\w+>)?(<Correct\!>)?\s*(SELECT\:\d+\s*)*$')
      @punctuation_regex = Regexp.compile('^\$?[\.\:\|\?\!]$') # .:|!?
      @orig_word_regex = Regexp.compile('^<word>(.*)</word>$')

      @correct_marker = '<Correct!>'
      @capitalized_marker = '<*>'
      @end_of_sentence_marker = '<<<'

      # keeping track of already read data
      @next_word = nil

      @peeked_word_record = nil
      @peeked_orig_word_record = nil
      @peeked_preamble = []
      @postamble = nil
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
      sentence = { words: []}

      while TRUE
        begin
          end_of_sent = false
          word = get_next_word(f)

          break if word.nil?

          # @todo Sentence segmentation is hacky. Redo in an inconsistent manner

          # if looking for xml tags we need to check for end tag before adding words, if so
          # we store the word and end the sentence. At the start of next sentence we'll
          # pick up the start tag and attributes
          if @sent_seg == :xml
            word[:xml_in_preamble].each_with_index do |marker, i|
              if marker.kind_of?(Hash)
                # @todo handle empty sentence segmentation tags
                raise RuntimeError if sentence[:words].count > 0 or end_of_sent == true

                sentence = marker.merge(sentence)
              elsif marker == :closed
                # @todo support empty sentences, right now we can't pass through here twice
                raise RuntimeError if end_of_sent
                end_of_sent = true
                # nuke this entry or we'll think it's sentence end when we look at the word again
                word[:xml_in_preamble].delete_at(i)
                break
              end
            end

            if end_of_sent
              # stash word for start of next sentence
              @next_word = word

              break
            end
          end

          word.delete(:xml_in_preamble)

          sentence[:words] << word

          # for other sentence segmentation we'll look at the punctuation or tag marker in the word
          end_of_sent = true if word[:form].match(@punctuation_regex) and @sent_seg == :static
          end_of_sent = true if word[:end_of_sentence_p] and @sent_seg == :mtag
          word.delete(:end_of_sentence_p) if word.has_key?(:end_of_sentence_p)

          break if end_of_sent
        end
      end

      return nil if sentence[:words].empty?

      sentence
    end

    ##
    # @private
    def get_next_word(f)
      # xml sentence segmentation handling may have stored the next word for us here
      if @next_word
        next_word = @next_word
        @next_word = nil
        return next_word
      end

      word = {}
      begin
        string, orig_string, preamble = get_word_header(f)
        word[:word] = orig_string
        word[:form] = string
        word[:xml_in_preamble] = []
      rescue EOFError
        return nil
      end

      get_word_tags(f, word)

      raise RuntimeError if word[:annotation].empty?

      # Check for XML sentence tags in the preamble so it can be passed up to get_next_sentence
      preamble.each do |line|
        if OBTFormatReader.is_open_sent_tag_line(line)
          word[:xml_in_preamble].push(OBTFormatReader.attributes(line))
        elsif OBTFormatReader.is_close_sent_tag_line(line)
          word[:xml_in_preamble].push(:closed)
        end
      end

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
        @peeked_preamble << line.strip
      end
    end

    ##
    # @private
    def unpeek()
      @peeked_word_record = nil
      @peeked_orig_word_record = nil
      @peeked_preamble = []
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

    # @param [String] line
    # @return [TrueClass, FalseClass]
    def self.is_open_sent_tag_line(line)
      not line.match(OPEN_SENT_TAG_REGEX).nil?
    end

    # @param [String] line
    # @return [TrueClass, FalseClass] true if line contains closing sentence segmention tag.
    def self.is_close_sent_tag_line(line)
      not line.match(CLOSED_SENT_TAG_REGEX).nil?
    end

    # @param [String] tag_line String containing tag.
    # @return [NilClass, Hash] Hash containing the attributes if a tag is present in the string, nil otherwise.
    def self.attributes(tag_line)
      tag, state, attr = TextlabNLP.parse_tag(tag_line)

      attr if tag == SENT_SEG_TAG and state == :open
    end
  end
end