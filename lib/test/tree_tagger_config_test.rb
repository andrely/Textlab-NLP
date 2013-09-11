require 'test/unit'

require_relative '../tree_tagger_config'

class TreeTaggerConfigTest < Test::Unit::TestCase
  def test_tokenize_cmd
    tagger = TextlabNLP::TreeTaggerConfig.new(config: { path: '/foo' }, lang: :fra)
    assert_equal("/foo/cmd/utf8-tokenize.perl -a /foo/lib/french-abbreviations-utf8 -f", tagger.tokenize_cmd)
  end
end