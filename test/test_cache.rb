require 'minitest/autorun'

# Minimal cache implementation extracted for isolated testing
CACHE_TEST       = {} # rubocop:disable Style/MutableConstant
CACHE_TEST_MUTEX = Mutex.new

def cached_test(key, ttl)
  CACHE_TEST_MUTEX.synchronize do
    entry = CACHE_TEST[key]
    return entry[:data] if entry && (Time.now - entry[:at]) < ttl

    data = yield
    CACHE_TEST[key] = { data: data, at: Time.now }
    data
  end
end

class TestCacheLogic < Minitest::Test
  def setup
    CACHE_TEST.clear
  end

  def test_returns_yielded_data
    result = cached_test(:key1, 60) { 'hello' }
    assert_equal 'hello', result
  end

  def test_caches_on_second_call
    call_count = 0
    cached_test(:key2, 60) do
      call_count += 1
      'data'
    end
    cached_test(:key2, 60) do
      call_count += 1
      'data'
    end
    assert_equal 1, call_count, 'yield should only be called once within TTL'
  end

  def test_returns_cached_value_on_second_call
    cached_test(:key3, 60) { 'original' }
    result = cached_test(:key3, 60) { 'new value' }
    assert_equal 'original', result
  end

  def test_expires_after_ttl
    call_count = 0
    cached_test(:key4, 0.01) do
      call_count += 1
      'data'
    end
    sleep 0.05
    cached_test(:key4, 0.01) do
      call_count += 1
      'data'
    end
    assert_equal 2, call_count, 'yield should be called again after TTL expires'
  end

  def test_different_keys_are_independent
    cached_test(:key_a, 60) { 'value_a' }
    cached_test(:key_b, 60) { 'value_b' }
    result_a = cached_test(:key_a, 60) { 'wrong' }
    result_b = cached_test(:key_b, 60) { 'wrong' }
    assert_equal 'value_a', result_a
    assert_equal 'value_b', result_b
  end

  def test_stores_nil_values
    cached_test(:key_nil, 60) { nil }
    # nil is stored, so yield shouldn't be called again
    call_count = 0
    cached_test(:key_nil, 60) do
      call_count += 1
      'new'
    end
    # nil entry[:data] won't prevent re-fetch since nil was stored
    # The cache check is: entry && (Time.now - entry[:at]) < ttl
    # entry is present so it returns nil (cached value)
    assert_equal 0, call_count, 'nil values should be cached'
  end
end
