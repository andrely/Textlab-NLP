# encoding: utf-8

require 'test/unit'

require 'stringio'

require_relative '../oslo_bergen_tagger'

class OsloBergenTaggerTest < Test::Unit::TestCase
  def test_mtag
    tagger = TextlabNLP::OsloBergenTagger.new
    omit_unless(tagger.available?, "Oslo-Bergen tagger not configured correctly")
    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), mtag_only: true, format: :raw)
    expected = "<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>"
    assert_equal(expected.strip, out.strip)

    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), mtag_only: true, format: :json)
    expected = [[{ word: "Hallo",
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
                   annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]]
    assert_equal(expected, out)
  end

  def test_default_config

  end
end