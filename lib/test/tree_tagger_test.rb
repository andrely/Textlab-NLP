# encoding: utf-8

require 'test/unit'

require 'stringio'

require_relative '../tree_tagger'
require_relative '../globals'

class TreeTaggerTest < Test::Unit::TestCase

  def test_tokenize_cmd
    tagger = TextlabNLP::TreeTagger.new(config: { path: '/foo' })
    assert_equal("/foo/cmd/utf8-tokenize.perl -a /foo/lib/french-abbreviations-utf8 -f", tagger.tokenize_cmd(:fra))
  end

  def test_tokenize
    TextlabNLP.echo_external_command_output = true
    tagger = TextlabNLP::TreeTagger.new
    out = StringIO.new
    tagger.tokenize(StringIO.new("Les tribulations d'une caissière."), out, :fra)
    assert_equal("Les\ntribulations\nd'\nune\ncaissière\n.", out.string.strip)
  end
end