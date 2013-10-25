require 'test/unit'

require_relative '../multi_processing'

class MultiProcessingTest < Test::Unit::TestCase
  def test_mp_map_thread
    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_thread(inputs) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])

    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_thread(inputs, n: 2) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])

    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_thread(inputs, n: 20) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])
  end

  def test_mp_map_direct
    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_direct(inputs) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])

    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_direct(inputs, n: 2) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])

    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map_direct(inputs, n: 20) do |input|
      index, seq = input
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])
  end

  def test_mp_map
    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map(inputs) do |input, log_str|
      index, seq = input
      log_str.puts("Processing #{index}")
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])

    inputs = 10.times.collect { |i| [i+1, (1..i+1).to_a] }

    result = TextlabNLP.mp_map(inputs, mode: :thread) do |input, log_str|
      index, seq = input
      log_str.puts("Processing #{index}")
      [index, seq.inject { |acc, x| acc + x }]
    end

    result = result.sort { |a, b| a[0] <=> b[0] }

    assert_not_nil(result)
    assert_kind_of(Enumerable, result)
    assert_equal(10, result.length)
    assert_equal([1, 1], result[0])
    assert_equal([2, 3], result[1])
    assert_equal([3, 6], result[2])
    assert_equal([4, 10], result[3])
    assert_equal([5, 15], result[4])
    assert_equal([6, 21], result[5])
    assert_equal([7, 28], result[6])
    assert_equal([8, 36], result[7])
    assert_equal([9, 45], result[8])
    assert_equal([10, 55], result[9])
  end
end