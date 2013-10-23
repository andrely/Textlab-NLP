require 'test/unit'

require 'stringio'

require_relative '../globals'

class GlobalsTest < Test::Unit::TestCase
  def test_root_path
    cur_root = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

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

  def test_io_like?
    assert_true(TextlabNLP.io_like?(IO.new(2)))
    assert_true(TextlabNLP.io_like?(StringIO.new()))
    assert_true(TextlabNLP.io_like?(File.new(2)))
    assert_false(TextlabNLP.io_like?(''))
  end

  def test_copy
    from = StringIO.new('ba')
    to = StringIO.new
    result = TextlabNLP.copy(from, to)
    assert_equal('ba', result.string)
    assert_equal('ba', to.string)
  end

  def test_run_shell_cmd
    # pretend we're in a unixy place
    status = TextlabNLP.run_shell_command('ls')
    assert_equal 0, status.exitstatus

    in_str = "ba\nfoo\nbork\nknark\n"
    in_file = StringIO.new(in_str)
    out_file = StringIO.new
    status = TextlabNLP.run_shell_command('cat', stdin_file: in_file, stdout_file: out_file)
    assert_equal 0, status.exitstatus
    assert_equal in_file.string, out_file.string

    out_file = StringIO.new
    status = TextlabNLP.run_shell_command('echo foo', stdout_file: out_file)
    assert_equal(0, status.exitstatus)
    assert_equal(out_file.string, "foo\n")
  end

end