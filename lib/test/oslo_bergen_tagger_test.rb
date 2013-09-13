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
    expected = [{ words: [{ word: "Hallo",
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
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}]
    assert_equal(expected, out)
  end

  def test_mtag_nn
    tagger = TextlabNLP::OsloBergenTagger.new
    omit_unless(tagger.available?, "Oslo-Bergen tagger not configured correctly")
    out = tagger.annotate(file: StringIO.new("Hugsar du.\n"), mtag_only: true, format: :raw, lang: :nn)
    expected = "<word>Hugsar</word>\n\"<hugsar>\"\n\t\"hugs\" subst mask appell ub fl\n\t\"hugse\" verb pres tr2 tr5 tr18 tr12 tr19 tr21 tr22\n<word>du</word>\n\"<du>\"\n\t\"du\" pron pers 2 eint hum nom\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <punkt> <<<"
    assert_equal(expected.strip, out.strip)

    out = tagger.annotate(file: StringIO.new("Hugsar du.\n"), mtag_only: true, format: :json, lang: :nn)
    expected = [{ words: [{ word: "Hugsar",
                            form: "hugsar",
                            annotation: [{ tag: "subst mask appell ub fl", lemma: "hugs" },
                                         { tag: "verb pres tr2 tr5 tr18 tr12 tr19 tr21 tr22", lemma: "hugse" }]},
                          { word: "du",
                            form: "du",
                            annotation: [{ tag: "pron pers 2 eint hum nom", lemma: "du" }]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$." }]}]}]
    assert_equal(expected, out)
  end

  def test_mtag_cmd
    tagger = TextlabNLP::OsloBergenTagger.new(replace_config: TextlabNLP.default_config[:obtagger], platform: :osx)
    assert_equal("mtag-osx64 -wxml", tagger.mtag_cmd)
    assert_equal("mtag-osx64 -wxml", tagger.mtag_cmd(:bm))
    assert_equal("mtag-osx64 -wxml -nno", tagger.mtag_cmd(:nn))
    assert_raise(NotImplementedError) do
      tagger.mtag_cmd(:bork)
    end

    tagger = TextlabNLP::OsloBergenTagger.new(replace_config: TextlabNLP.default_config[:obtagger], platform: :linux)
    assert_equal("mtag-linux -wxml", tagger.mtag_cmd)
    assert_equal("mtag-linux -wxml", tagger.mtag_cmd(:bm))
    assert_equal("mtag-linux -wxml -nno", tagger.mtag_cmd(:nn))
    assert_raise(NotImplementedError) do
      tagger.mtag_cmd(:bork)
    end

    tagger = TextlabNLP::OsloBergenTagger.new(replace_config: TextlabNLP.default_config[:obtagger], platform: :win)
    assert_equal("mtag.exe -wxml", tagger.mtag_cmd)
    assert_equal("mtag.exe -wxml", tagger.mtag_cmd(:bm))
    assert_equal("mtag.exe -wxml -nno", tagger.mtag_cmd(:nn))
    assert_raise(NotImplementedError) do
      tagger.mtag_cmd(:bork)
    end
  end

  def test_grammar_path
    tagger = TextlabNLP::OsloBergenTagger.new(replace_config: TextlabNLP.default_config[:obtagger])
    assert_equal("bm_morf.cg", tagger.grammar_path)
    assert_equal("bm_morf-prestat.cg", tagger.grammar_path(:bm, true))
    assert_equal("nn_morf.cg", tagger.grammar_path(:nn))
    assert_raise(NotImplementedError) do
      tagger.grammar_path(:bork)
    end
  end

  def test_obt
    tagger = TextlabNLP::OsloBergenTagger.new
    omit_unless(tagger.available?, "Oslo-Bergen tagger not configured correctly")
    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), format: :raw)
    expected = "<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj \n\t\"hallo\" subst appell nøyt ub ent \n\t\"hallo\" subst appell nøyt ub fl \n<word>i</word>\n\"<i>\"\n\t\"i\" prep \n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>"
    assert_equal(expected.strip, out.strip)

    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), format: :json)
    expected = [{ words: [{ word: "Hallo",
                            form: "hallo",
                            annotation: [{ tag: "interj", lemma: "hallo"},
                                         { tag: "subst appell nøyt ub ent", lemma: "hallo"},
                                         { tag: "subst appell nøyt ub fl", lemma: "hallo"}]},
                          { word: "i",
                            form: "i",
                            annotation: [{ tag: "prep", lemma: "i"}]},
                          { word: "luken",
                            form: "luken",
                            annotation: [{ tag: "subst appell mask be ent", lemma: "luke"}]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}]
    assert_equal(expected, out)
  end

  def test_obt_nn
    tagger = TextlabNLP::OsloBergenTagger.new
    omit_unless(tagger.available?, "Oslo-Bergen tagger not configured correctly")
    out = tagger.annotate(file: StringIO.new("Hugsar du.\n"), format: :raw, lang: :nn)
    expected = "<word>Hugsar</word>\n\"<hugsar>\"\n\t\"hugse\" verb pres tr2 tr5 tr18 tr12 tr19 tr21 tr22 \n<word>du</word>\n\"<du>\"\n\t\"du\" pron pers 2 eint hum nom \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <punkt> <<<"
    assert_equal(expected.strip, out.strip)

    out = tagger.annotate(file: StringIO.new("Hugsar du.\n"), format: :json, lang: :nn)
    expected = [{ words: [{ word: "Hugsar",
                            form: "hugsar",
                            annotation: [{ tag: "verb pres tr2 tr5 tr18 tr12 tr19 tr21 tr22", lemma: "hugse" }]},
                          { word: "du",
                            form: "du",
                            annotation: [{ tag: "pron pers 2 eint hum nom", lemma: "du" }]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$." }]}]}]
    assert_equal(expected, out)
  end

  def test_disambiguate
    tagger = TextlabNLP::OsloBergenTagger.new
    omit_unless(tagger.available?, "Oslo-Bergen tagger not configured correctly")
    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), format: :raw, disambiguate: true)
    expected = "<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj \n<word>i</word>\n\"<i>\"\n\t\"i\" prep \n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>"
    assert_equal(expected.strip, out.strip)

    out = tagger.annotate(file: StringIO.new("Hallo i luken.\n"), format: :json, disambiguate: true)
    expected = [{ words: [{ word: "Hallo",
                            form: "hallo",
                            annotation: [{ tag: "interj", lemma: "hallo"}]},
                          { word: "i",
                            form: "i",
                            annotation: [{ tag: "prep", lemma: "i"}]},
                          { word: "luken",
                            form: "luken",
                            annotation: [{ tag: "subst appell mask be ent", lemma: "luke"}]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}]
    assert_equal(expected, out)

    # with more than one sentence
    expected = [{ words: [{ word: "Hallo",
                            form: "hallo",
                            annotation: [{ tag: "interj", lemma: "hallo"}]},
                          { word: "i",
                            form: "i",
                            annotation: [{ tag: "prep", lemma: "i"}]},
                          { word: "luken",
                            form: "luken",
                            annotation: [{ tag: "subst appell mask be ent", lemma: "luke"}]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]},
                { words: [{ word: "Vi",
                            form: "vi",
                            annotation: [{ tag: "pron fl pers hum nom 1", lemma: "vi"}]},
                          { word: "drar",
                            form: "drar",
                            annotation: [{ tag: "verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9", lemma: "dra" }]},
                          { word: "til sjøs",
                            form: "til sjøs",
                            annotation: [{ tag: "prep prep+subst @adv", lemma: "til sjøs" }]},
                          { word: ".",
                            form: ".",
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}]
    out = tagger.annotate(file: StringIO.new("Hallo i luken.\nVi drar til sjøs.\n"), format: :json, disambiguate: true)
    assert_equal(expected, out)
  end
end