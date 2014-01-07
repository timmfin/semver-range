semver-range
============

A library to deal with semantic version ranges like `v1.2.x` or `~1.2` (same as `~> 1.2`). It builds upon and adds range functionality to [haf/semver](https://github.com/haf/semver).

Note, the range syntax is a mix of the rules from [node-semver](https://github.com/isaacs/node-semver) and [ruby gems](http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html).

Some examples:

```ruby
require 'semver-range'

lt_range = SemVerRange.parse "< v1.2.3"
lt_range.matches? "v1.2.0"

gte_range = SemVerRange.parse ">= v10.0.7"
gte_range.matches? "v11.0.0"

approx_range = SemVerRange.parse "~> v2.1.0"
approx_range.matches? "v2.1.37"

approx_range2 = SemVerRange.parse "~> v2.1", "v%M.%m"
approx_range2.matches? "v2.5.6"

wildcard_range = SemVerRange.parse "v3.4.x"
wildcard_range.matches? "v3.4.1"

wildcard_range2 = SemVerRange.parse "v4.x.x"
wildcard_range2.matches? SemVer.new(4, 4, 4)


r = SemVerRange.new 1, 2, 3, "~"
r.upper_bound
=> v1.3.0
x.lower_bound
=> v1.2.3
x.is_range?
=> true


# Newer SemVer extensions

semver = SemVer.new 1, 2, 3
semver.increment
=> v1.2.4
semver.is_range?
=> false
semver.to_a
=> [1,2,3]

```
