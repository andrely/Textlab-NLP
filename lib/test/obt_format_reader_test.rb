# encoding: utf-8

require 'test/unit'

require_relative '../obt_format_reader'

class OBTFormatReaderTest < Test::Unit::TestCase
  def test_obt_format_reader
    file = StringIO.new("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>")
    expected = { words: [{ word: "Hallo",
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
                           annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}
    reader = TextlabNLP::OBTFormatReader.new(file)
    sents = []
    reader.each_sentence { |s| sents << s }
    assert_equal(1, sents.count)
    sent = sents[0]
    assert_equal(expected, sent)

    file.rewind
    reader = TextlabNLP::OBTFormatReader.new(file, sent_seg: :static)
    sents = []
    reader.each_sentence { |s| sents << s }
    assert_equal(1, sents.count)
    sent = sents[0]
    assert_equal(expected, sent)

    # with more than one sentence
    file = StringIO.new
    file.write("<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>\n")
    file.write("<word>Vi</word>\n\"<vi>\"\n\t\"vi\" pron fl pers hum nom 1 \n<word>drar</word>\n\"<drar>\"\n\t\"dra\" verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9 \n<word>til sjøs</word>\n\"<til sjøs>\"\n\t\"til sjøs\" prep prep+subst @adv \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt> \n")
    file.rewind
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
    reader = TextlabNLP::OBTFormatReader.new(file, sent_seg: :static)
    sents = []
    reader.each_sentence { |s| sents.push(s) }
    assert_equal(2, sents.count)
    assert_equal(expected, sents)

    file.rewind
    reader = TextlabNLP::OBTFormatReader.new(file)
    sents = []
    reader.each_sentence { |s| sents.push(s) }
    assert_equal(2, sents.count)
    assert_equal(expected, sents)
  end

  def test_obt_format_reader_xml
    file = StringIO.new("<s id=\"1\">\n<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>\n</s>\n")
    expected = { id: "1",
                 words: [{ word: "Hallo",
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
                           annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]}
    reader = TextlabNLP::OBTFormatReader.new(file, sent_seg: :xml)
    sents = []
    reader.each_sentence { |s| sents << s }
    assert_equal(1, sents.count)
    sent = sents[0]
    assert_equal(expected, sent)

    # with more than one sentence
    file = StringIO.new
    file.write("<s id=\"1\">\n<word>Hallo</word>\n\"<hallo>\"\n\t\"hallo\" interj\n\t\"hallo\" subst appell nøyt ub ent\n\t\"hallo\" subst appell nøyt ub fl\n<word>i</word>\n\"<i>\"\n\t\"i\" prep\n\t\"i\" subst appell mask ub ent\n<word>luken</word>\n\"<luken>\"\n\t\"luke\" subst appell mask be ent\n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt>\n</s>\n")
    file.write("<s id=\"2\">\n<word>Vi</word>\n\"<vi>\"\n\t\"vi\" pron fl pers hum nom 1 \n<word>drar</word>\n\"<drar>\"\n\t\"dra\" verb pres tr1 i1 tr11 pa1 a3 rl5 pa5 tr11/til a7 a9 \n<word>til sjøs</word>\n\"<til sjøs>\"\n\t\"til sjøs\" prep prep+subst @adv \n<word>.</word>\n\"<.>\"\n\t\"$.\" clb <<< <punkt> \n</s>\n")
    file.rewind
    expected = [{ id: "1",
                  words: [{ word: "Hallo",
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
                            annotation: [{ tag: "clb <punkt>", lemma: "$."}]}]},
                { id: "2",
                  words: [{ word: "Vi",
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
    reader = TextlabNLP::OBTFormatReader.new(file, sent_seg: :xml)
    sents = []
    reader.each_sentence { |s| sents.push(s) }
    assert_equal(2, sents.count)
    assert_equal(expected, sents)

  end
end
