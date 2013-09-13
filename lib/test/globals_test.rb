require 'test/unit'

require 'stringio'

require_relative '../globals'

class GlobalsTest < Test::Unit::TestCase
  def test_root_path
    cur_root = File.absolute_path(File.join(File.dirname(__FILE__), '../..'))

    assert_equal(cur_root, TextlabNLP.root_path)
  end

  def test_read_config_file
    assert_raise(TextlabNLP::ConfigError) do
      TextlabNLP.read_config_file(StringIO.new('[]'))
    end

    assert_equal({ ba: "foo" }, TextlabNLP.read_config_file(StringIO.new('{ "ba": "foo" }')))
  end

  def test_read_default_config
    default_config = TextlabNLP.default_config
    assert(default_config[:obtagger])
    assert(default_config[:obtagger][:mtag])
    assert(default_config[:obtagger][:mtag][:linux])
    assert(default_config[:obtagger][:mtag][:osx])
    assert_equal("mtag-linux", default_config[:obtagger][:mtag][:linux])
    assert_equal("mtag-osx64", default_config[:obtagger][:mtag][:osx])
  end

  def test_config
    config = TextlabNLP.config(StringIO.new('{"obtagger": {"mtag": {"linux": "foo"}}}'))
    assert(config[:obtagger])
    assert(config[:obtagger][:mtag])
    assert(config[:obtagger][:mtag][:linux])
    assert(config[:obtagger][:mtag][:osx])
    assert_equal("foo", config[:obtagger][:mtag][:linux])
    assert_equal("mtag-osx64", config[:obtagger][:mtag][:osx])
  end

  def test_parse_tag
    assert_equal(["s", :open, {}], TextlabNLP.parse_tag("<s>"))
    assert_equal(["s", :open, { id: "1" }], TextlabNLP.parse_tag("<s id=\"1\">"))
    assert_equal(["s", :closed, nil], TextlabNLP.parse_tag("</s>"))
    assert_equal([nil, nil, nil], TextlabNLP.parse_tag("ba"))
  end
end