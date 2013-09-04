# encoding: utf-8

require 'test/unit'

require_relative '../obt_format_reader'

class OBTFormatReaderTest < Test::Unit::TestCase
  def test_obt_format_reader
    file = StringIO.new("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>")
    expected = [{ word: "Hallo",
                  form: "hallo",
                  annotation: [{ tag: "interj", lemma: "hallo"},
                               { tag: "subst appell nøyt ub ent", lemma: "hallo"},
                               { tag: "subst appell nøyt ub fl", lemma: "hallo"}]},
                { word: "i",
                  form: "i",
                  annotation: [{ tag: "prep", lemma: "i"},
                               { tag: "subst appell mask ub ent", lemma: "i"}]},
                { word: "luken",
                  form: "luken",
                  annotation: [{ tag: "subst appell mask be ent", lemma: "luke"}]},
                { word: ".",
                  form: ".",
                  annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]
    reader = TextlabNLP::OBTFormatReader.new(file)
    sents = []
    reader.each_sentence { |s| sents << s }
    assert_equal(1, sents.count)
    sent = sents[0]
    assert_equal(expected, sent)

    file.rewind
    reader = TextlabNLP::OBTFormatReader.new(file, use_static_punctuation=true)
    sents = []
    reader.each_sentence { |s| sents << s }
    assert_equal(1, sents.count)
    sent = sents[0]
    assert_equal(expected, sent)
  end
end
