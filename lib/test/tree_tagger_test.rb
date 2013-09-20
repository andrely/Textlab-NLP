# encoding: utf-8

require 'test/unit'

require 'stringio'
require 'iconv'

require_relative '../tree_tagger'
require_relative '../globals'

class TreeTaggerTest < Test::Unit::TestCase
  def test_tokenize
    omit_unless(TextlabNLP::TreeTaggerConfig.lang_available?(:fra))
    tagger = TextlabNLP::TreeTagger.for_lang(:fra)
    out = StringIO.new
    tagger.tokenize(StringIO.new("Les tribulations d'une caissière."), out)
    assert_equal("Les\ntribulations\nd'\nune\ncaissière\n.", out.string.strip)
  end

  def test_annotate_fra
    omit_unless(TextlabNLP::TreeTaggerConfig.lang_available?(:fra))
    tagger = TextlabNLP::TreeTagger.for_lang(:fra)
    out = tagger.annotate(file: StringIO.new("Les tribulations d'une caissière."), format: :raw)
    assert_equal("Les\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t.",
                 out.strip)
    out = tagger.annotate(file: StringIO.new("Les tribulations d'une caissière."))
    assert_equal([{ words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                            { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                            { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                            { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                            { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                            { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]}],
                 out)
    tagger = TextlabNLP::TreeTagger.for_lang(:fra, encoding: :latin1)
    out = tagger.annotate(file: StringIO.new(Iconv.conv('latin1', 'utf-8', "Les tribulations d'une caissière.")),
                          format: :raw)
    assert_equal(Iconv.conv('latin1', 'utf-8', "Les\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t."),
                 out.strip)
  end

  def test_annotate_fra_xml
    omit_unless(TextlabNLP::TreeTaggerConfig.lang_available?(:fra))
    tagger = TextlabNLP::TreeTagger.for_lang(:fra)
    out = tagger.annotate(file: StringIO.new("<s id=\"1\">\nLes tribulations d'une caissière.</s>\n<s id=\"2\">\nLes tribulations d'une caissière.</s>\n"),
                          sent_seg: :xml)
    assert_equal([{ id: "1",
                    words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                            { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                            { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                            { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                            { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                            { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]},
                  { id: "2",
                    words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                            { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                            { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                            { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                            { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                            { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]}],
                 out)
  end

  def test_annotate_swe
    omit_unless(TextlabNLP::TreeTaggerConfig.lang_available?(:swe))
    tagger = TextlabNLP::TreeTagger.for_lang(:swe)
    out = tagger.annotate(file: StringIO.new("Problem med möss. Problem med möss."))
    assert_equal([{ words: [{ word: "Problem", annotation: [{ tag: "NCNPN@IS", lemma: "problem"}] },
                            { word: "med", annotation: [{ tag: "SPS", lemma: "med" }]},
                            { word: "möss", annotation: [{ tag: "NCUPN@IS", lemma: "mus"}]},
                            { word: ".", annotation: [{ tag: "FE", lemma: "." }]}]},
                  { words: [{ word: "Problem", annotation: [{ tag: "NCNPN@IS", lemma: "problem"}] },
                            { word: "med", annotation: [{ tag: "SPS", lemma: "med" }]},
                            { word: "möss", annotation: [{ tag: "NCUPN@IS", lemma: "mus"}]},
                            { word: ".", annotation: [{ tag: "FE", lemma: "." }]}]}],
                 out)

    tagger = TextlabNLP::TreeTagger.for_lang(:swe, encoding: :latin1)
    out = tagger.annotate(file: StringIO.new(Iconv.conv('latin1', 'utf8', "Problem med möss.")),
                          format: :raw)
    assert_equal(Iconv.conv('latin1', 'utf-8', "Problem\tNCNPN@IS\tproblem\nmed\tSPS\tmed\nmöss\tNCUPN@IS\tmus\n.\tFE\t."), out.strip)
  end

  def test_annotate_eng
    omit_unless(TextlabNLP::TreeTaggerConfig.lang_available?(:eng))
    tagger = TextlabNLP::TreeTagger.for_lang(:eng)
    out = tagger.annotate(file: StringIO.new("How are you? I'm fine."))
    assert_equal([{ words: [{ word: 'How', annotation: [{ tag: 'WRB', lemma: 'How' }]},
                            { word: 'are', annotation: [{ tag: 'VBP', lemma: 'be' }]},
                            { word: 'you', annotation: [{ tag: 'PP', lemma: 'you' }]},
                            { word: '?', annotation: [{ tag: 'SENT', lemma: '?' }]}]},
                  { words: [{ word: 'I', annotation: [{ tag: 'PP', lemma: 'I' }]},
                            { word: "'m", annotation: [{ tag: 'VBP', lemma: 'be' }]},
                            { word: 'fine', annotation: [{ tag: 'JJ', lemma: 'fine' }]},
                            { word: '.', annotation: [{ tag: 'SENT', lemma: '.' }]}]}],
                 out)

    tagger = TextlabNLP::TreeTagger.for_lang(:eng, encoding: :latin1)
    out = tagger.annotate(file: StringIO.new(Iconv.conv('latin1', 'utf8', "How are you? I'm fine.")),
                          format: :raw)
    assert_equal(Iconv.conv('latin1', 'utf8',
                            "How\tWRB\tHow\nare\tVBP\tbe\nyou\tPP\tyou\n?\tSENT\t?\nI\tPP\tI\n'm\tVBP\tbe\nfine\tJJ\tfine\n.\tSENT\t."),
                 out.strip)
  end

  def test_tt_to_json
    tt_file = StringIO.new
    tt_file.write("Les\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t.\n")
    tt_file.write("Les\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t.\n")
    tt_file.rewind
    json = TextlabNLP::TreeTagger.tt_to_json(tt_file)
    assert(json)
    assert_equal(2, json.count)
    assert_equal({ words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                           { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                           { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                           { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                           { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                           { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]},
                 json[0])
    assert_equal({ words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                           { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                           { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                           { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                           { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                           { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]},
                 json[1])
  end

  def test_tt_to_json_xml
    tt_file = StringIO.new
    tt_file.write("<s id=\"1\">\nLes\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t.\n</s>\n")
    tt_file.write("<s id=\"2\">\nLes\tDET:ART\tle\ntribulations\tNOM\ttribulation\nd'\tPRP\tde\nune\tDET:ART\tun\ncaissière\tNOM\tcaissier\n.\tSENT\t.\n</s>\n")
    tt_file.rewind
    json = TextlabNLP::TreeTagger.tt_to_json(tt_file, 'SENT', :xml)
    assert(json)
    assert_equal(2, json.count)
    assert_equal({ id: "1",
                   words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                           { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                           { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                           { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                           { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                           { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]},
                 json[0])
    assert_equal({ id: "2",
                   words: [{ word: "Les", annotation: [{ tag: "DET:ART", lemma: "le"}]},
                           { word: "tribulations", annotation: [{ tag: "NOM", lemma: "tribulation" }]},
                           { word: "d'", annotation: [{ tag: "PRP", lemma: "de" }]},
                           { word: "une", annotation: [{ tag: "DET:ART", lemma: "un" }]},
                           { word: "caissière", annotation: [{ tag: "NOM", lemma: "caissier" }]},
                           { word: ".", annotation: [{ tag: "SENT", lemma: "."}]}]},
                 json[1])
  end
end