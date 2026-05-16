module RubyTips
  TIPS = [
    # --- Strings ---
    { title: 'Reverse a string',
      code:  '"hello".reverse  # => "olleh"',
      note:  'works on arrays too: [1,2,3].reverse' },

    { title: 'String multiplication',
      code:  '"ha" * 3  # => "hahaha"',
      note:  'also: [0] * 5  # => [0, 0, 0, 0, 0]' },

    { title: 'Check substring',
      code:  '"hello world".include?("world")  # => true',
      note:  'also: "hello" === "hello world" — nope, use include?' },

    { title: 'Strip whitespace',
      code:  '"  hello  ".strip   # => "hello"\n"  hello  ".lstrip  # => "hello  "',
      note:  'chomp removes trailing newline: "line\\n".chomp  # => "line"' },

    { title: 'String interpolation',
      code:  'name = "world"; "Hello #{name.upcase}!"',
      note:  'any expression works inside #{} — calls .to_s automatically' },

    { title: 'Multiline string with heredoc',
      code:  "text = <<~HEREDOC\n  indented\n  content\nHEREDOC",
      note:  '<<~ strips leading whitespace; <<- preserves indentation' },

    { title: 'Split and join',
      code:  '"a,b,c".split(",")  # => ["a","b","c"]\n["a","b"].join("-")  # => "a-b"',
      note:  'split with no args splits on whitespace and removes empty strings' },

    { title: 'gsub with block',
      code:  '"hello".gsub(/[aeiou]/) { |v| v.upcase }  # => "hEllO"',
      note:  'block receives the match — can apply any transformation' },

    { title: 'String#chars and bytes',
      code:  '"hello".chars  # => ["h","e","l","l","o"]\n"hi".bytes     # => [104, 105]',
      note:  'chars is Unicode-aware; bytes gives raw UTF-8 byte values' },

    { title: 'Center, ljust, rjust',
      code:  '"hi".center(10, "-")  # => "----hi----"\n"hi".ljust(8)          # => "hi      "',
      note:  'great for terminal table formatting without gems' },

    { title: 'String#scan',
      code:  '"one 1 two 2".scan(/\\d+/)  # => ["1", "2"]',
      note:  'returns array of all matches — can also use capture groups' },

    { title: 'String#squeeze',
      code:  '"aaabbbccc".squeeze    # => "abc"\n"foo   bar".squeeze(" ")  # => "foo bar"',
      note:  'collapses consecutive identical characters' },

    # --- Arrays ---
    { title: 'Flatten nested arrays',
      code:  '[[1,[2]],3].flatten    # => [1,2,3]\n[[1,[2]],3].flatten(1) # => [1,[2],3]',
      note:  'optional depth argument limits flattening levels' },

    { title: 'Array#zip',
      code:  '[1,2].zip([3,4])  # => [[1,3],[2,4]]',
      note:  'transpose multiple arrays — great for parallel iteration' },

    { title: 'Compact removes nils',
      code:  '[1, nil, 2, nil, 3].compact  # => [1, 2, 3]',
      note:  'compact! modifies in place; does not remove false' },

    { title: 'Set operations on arrays',
      code:  '[1,2,3] & [2,3,4]  # => [2,3]  (intersection)\n[1,2] | [2,3]       # => [1,2,3] (union)',
      note:  'also: [1,2,3] - [2] # => [1,3] (difference)' },

    { title: 'Array#product',
      code:  '[1,2].product([3,4])  # => [[1,3],[1,4],[2,3],[2,4]]',
      note:  'cartesian product — useful for generating combinations' },

    { title: 'Rotate an array',
      code:  '[1,2,3,4].rotate     # => [2,3,4,1]\n[1,2,3,4].rotate(-1)  # => [4,1,2,3]',
      note:  'negative value rotates in the opposite direction' },

    { title: 'Sample and shuffle',
      code:  '[1,2,3,4].sample     # => random element\n[1,2,3,4].shuffle    # => randomized array',
      note:  'sample(n) returns n unique random elements' },

    { title: 'each_slice and each_cons',
      code:  '(1..6).each_slice(2).to_a   # => [[1,2],[3,4],[5,6]]\n(1..4).each_cons(2).to_a    # => [[1,2],[2,3],[3,4]]',
      note:  'slice chunks non-overlapping; cons slides a window' },

    { title: 'Array#combination and permutation',
      code:  '[1,2,3].combination(2).to_a   # => [[1,2],[1,3],[2,3]]\n[1,2,3].permutation(2).to_a  # => [[1,2],[1,3],[2,1],...]',
      note:  'built-in combinatorics without any gem' },

    { title: 'Flatten with flat_map',
      code:  '[[1,2],[3,4]].flat_map { |a| a.map { |x| x * 2 } }  # => [2,4,6,8]',
      note:  'equivalent to .map{}.flatten(1) but in a single pass' },

    # --- Hashes ---
    { title: 'Hash default value',
      code:  'h = Hash.new(0)\nh[:x] += 1  # => 1  (no KeyError)',
      note:  'use Hash.new { |h,k| h[k] = [] } for mutable defaults' },

    { title: 'Merge with block',
      code:  '{a:1}.merge({a:2}) { |key, old, new_val| old + new_val }  # => {a:3}',
      note:  'block resolves conflicts — great for summing counters' },

    { title: 'dig for nested access',
      code:  'h.dig(:user, :address, :city)  # nil-safe deep access',
      note:  'works on arrays too: arr.dig(0, 1) — no more rescue chains' },

    { title: 'transform_values and transform_keys',
      code:  '{a: 1, b: 2}.transform_values { |v| v * 10 }  # => {a:10, b:20}',
      note:  'transform_keys works the same on keys — both return new hash' },

    { title: 'filter_map on hash',
      code:  '{a:1, b:nil, c:3}.filter_map { |k,v| "#{k}=#{v}" if v }',
      note:  'select + map in one pass — available since Ruby 2.7' },

    { title: 'Hash#slice',
      code:  '{a:1, b:2, c:3}.slice(:a, :c)  # => {a:1, c:3}',
      note:  'opposite: hash.except(:b) # => {a:1, c:3} (Ruby 3.0+)' },

    { title: 'Count with tally',
      code:  '["a","b","a","c"].tally  # => {"a"=>2, "b"=>1, "c"=>1}',
      note:  'Ruby 2.7+ — replaces manual Hash.new(0) counting loops' },

    # --- Enumerable ---
    { title: 'Symbol to proc shorthand',
      code:  '[1,-2,3].map(&:abs)  # => [1, 2, 3]',
      note:  'works with any method: ["a","b"].map(&:upcase)' },

    { title: 'Lazy enumerator',
      code:  '(1..Float::INFINITY).lazy.select(&:even?).first(3)  # => [2,4,6]',
      note:  'without .lazy this would run forever — evaluates on demand' },

    { title: 'Enumerable#group_by',
      code:  '(1..6).group_by(&:even?)  # => {false=>[1,3,5], true=>[2,4,6]}',
      note:  'returns a hash keyed by the block result' },

    { title: 'Enumerable#min_by and max_by',
      code:  'people.min_by { |p| p.age }  # or min_by(&:age)',
      note:  'also: minmax_by, sort_by — all use Schwartzian transform internally' },

    { title: 'each_with_object',
      code:  '[1,2,3].each_with_object([]) { |x, acc| acc << x * 2 }',
      note:  'accumulator is passed as second block arg — unlike inject/reduce' },

    { title: 'Enumerable#chunk',
      code:  '[1,1,2,2,3].chunk { |x| x }.map { |k,v| [k, v.size] }',
      note:  'groups consecutive elements with same block value' },

    { title: 'reduce / inject',
      code:  '[1,2,3,4].reduce(:+)    # => 10\n[1,2,3].inject(10, :+) # => 16',
      note:  'symbol shorthand for simple operations; block for custom logic' },

    { title: 'Enumerable#zip with block',
      code:  '[1,2,3].zip([4,5,6]) { |a,b| puts "#{a}+#{b}=#{a+b}" }',
      note:  'with a block zip returns nil and just iterates — no intermediate array' },

    { title: 'filter_map',
      code:  '(1..10).filter_map { |x| x * 2 if x.odd? }  # => [2,6,10,14,18]',
      note:  'Ruby 2.7+ — combines select and map in one efficient pass' },

    # --- Blocks, Procs, Lambdas ---
    { title: 'Proc vs Lambda',
      code:  'lam = lambda { |x| x * 2 }  # or: ->(x) { x * 2 }',
      note:  'lambda checks arity and return exits lambda; proc returns from caller' },

    { title: 'Curry a method',
      code:  'add = ->(a, b) { a + b }\nadd5 = add.curry.(5)  # => a proc waiting for b',
      note:  'currying creates partial application — great for functional pipelines' },

    { title: 'tap for mid-chain debug',
      code:  '[1,2,3].tap { |a| p a }.map { |x| x * 2 }',
      note:  'tap yields self and returns self — zero impact on the chain' },

    { title: 'then / yield_self',
      code:  '"hello".then { |s| s.upcase }.then { |s| "#{s}!" }  # => "HELLO!"',
      note:  'unlike tap, then returns block result — great for pipelines' },

    { title: 'Method objects as procs',
      code:  'arr.map(&method(:puts))\n[1,-1,2].select(&method(:positive?))  # if defined',
      note:  'method(:name) returns a callable Method object' },

    # --- Classes & Modules ---
    { title: 'Struct shorthand',
      code:  'Point = Struct.new(:x, :y)\nPoint.new(1, 2).x  # => 1',
      note:  'add keyword_init: true for Point.new(x: 1, y: 2) syntax' },

    { title: 'Comparable mixin',
      code:  'include Comparable\ndef <=>(other); score <=> other.score; end',
      note:  'gets <, >, <=, >=, between?, clamp and sort support for free' },

    { title: 'Enumerable mixin',
      code:  'include Enumerable\ndef each; @data.each { |x| yield x }; end',
      note:  'implementing each gives you map, select, sort, min, max and 50+ more' },

    { title: 'attr_accessor vs attr_reader',
      code:  'attr_reader :name    # getter only\nattr_accessor :name  # getter + setter',
      note:  'attr_writer creates setter only — prefer reader for immutable data' },

    { title: 'Protected methods',
      code:  'protected\ndef secret; @value; end  # callable by same class instances',
      note:  'unlike private, protected allows calls from other instances of same class' },

    { title: 'Method missing',
      code:  'def method_missing(name, *args)\n  name.to_s.start_with?("find_") ? find(name) : super\nend',
      note:  'always also define respond_to_missing? for proper duck typing' },

    { title: 'Freeze constants',
      code:  'CONFIG = { host: "localhost", port: 4567 }.freeze',
      note:  'frozen objects raise RuntimeError on mutation — also freeze nested: deep_freeze' },

    # --- Modern Ruby ---
    { title: 'Safe navigation operator',
      code:  'user&.address&.city  # nil if any step is nil',
      note:  'avoids NoMethodError chains — introduced in Ruby 2.3' },

    { title: 'Pattern matching',
      code:  'case response\nin { status: 200, body: String => b } then puts b\nin { status: 404 } then puts "not found"\nend',
      note:  'Ruby 3.0+ — rightward assignment: data => { name: } also works' },

    { title: 'Endless method (Ruby 3.0+)',
      code:  'def double(x) = x * 2\ndef greet(name) = "Hello, #{name}!"',
      note:  'single-expression methods without end — concise for simple helpers' },

    { title: 'Numbered block params (Ruby 2.7+)',
      code:  '[1,2,3].map { _1 * 2 }     # => [2,4,6]\nhash.map { "#{_1}: #{_2}" }',
      note:  '_1, _2 etc replace named params — concise for simple blocks' },

    { title: 'Hash shorthand (Ruby 3.1+)',
      code:  'x = 1; y = 2\n{x:, y:}  # => {x: 1, y: 2}  (no repetition!)',
      note:  'like JS shorthand property names — great for building hashes from locals' },

    { title: 'Rightward assignment (Ruby 3.0+)',
      code:  'expensive_calculation() => result\nputs result',
      note:  'assigns right-to-left — useful at the end of method chains' },

    # --- Misc & Idioms ---
    { title: 'Multiple assignment with splat',
      code:  'a, b, *rest = [1, 2, 3, 4, 5]\n# a=1, b=2, rest=[3,4,5]',
      note:  'splat can appear anywhere: first, *mid, last = array' },

    { title: 'Memoization idiom',
      code:  'def result\n  @result ||= expensive_operation\nend',
      note:  '||= assigns only if @result is nil or false — simple one-liner cache' },

    { title: 'Array.new with block',
      code:  'Array.new(3) { |i| i * 2 }  # => [0, 2, 4]',
      note:  'without block: Array.new(3, "x") — all elements share same object!' },

    { title: 'Conditional assignment',
      code:  'x ||= "default"  # assigns only if x is nil/false\nx &&= x.upcase   # assigns only if x is truthy',
      note:  '&&= is great for transforming a value that may not exist yet' },

    { title: 'Object#freeze',
      code:  'str = "hello".freeze\nstr << " world"  # => FrozenError!',
      note:  'frozen? returns true — dup creates an unfrozen copy' },

    { title: 'pp for pretty printing',
      code:  'pp({ name: "Alice", scores: [1,2,3] })',
      note:  'unlike p, formats nested structures readably with class names' },

    { title: 'Kernel#Array() coercion',
      code:  'Array(nil)    # => []\nArray([1,2])  # => [1,2]\nArray(1)      # => [1]',
      note:  'safer than .to_a — handles nil gracefully without monkey-patching' },

    { title: 'Range#step',
      code:  '(0..1).step(0.25).to_a  # => [0.0, 0.25, 0.5, 0.75, 1.0]',
      note:  'works with floats and dates — also: 1.step(10, 2) { |n| ... }' },

    { title: 'Endless range',
      code:  'case age\nwhen 0..17  then "minor"\nwhen 18..   then "adult"\nend',
      note:  'beginless ranges too: (..5) === 3 # => true' },

    { title: 'ObjectSpace for debugging',
      code:  'ObjectSpace.each_object(String).count',
      note:  'shows how many live String objects exist — useful for memory profiling' },

    { title: 'Benchmark your code',
      code:  'require "benchmark"\nBenchmark.bm { |x| x.report("test:") { 10_000.times { "x" * 100 } } }',
      note:  'built into stdlib — no gem needed for quick performance checks' },

    { title: 'Comparable#clamp',
      code:  '5.clamp(1, 10)   # => 5\n15.clamp(1, 10)  # => 10\n(-1).clamp(0..)  # => 0  (endless range)',
      note:  'works on any Comparable — dates, strings, custom objects' },

    { title: 'Enumerator::Lazy#take_while',
      code:  '(1..).lazy.map { |n| n**2 }.take_while { |n| n < 100 }.to_a',
      note:  'stops at first element that fails — infinite sequences made safe' },

    { title: 'String#start_with? / end_with?',
      code:  '"hello".start_with?("he", "wo")  # => true (checks multiple)',
      note:  'accepts multiple arguments — returns true if any match' },

    { title: 'Kernel#loop with StopIteration',
      code:  'e = [1,2,3].each\nloop { puts e.next }  # stops automatically',
      note:  'loop rescues StopIteration — the idiomatic way to drain an enumerator' },
  ].freeze

  # Rotacja dzienna — inny tip każdego dnia
  def self.today
    TIPS[Date.today.yday % TIPS.size]
  end
end
