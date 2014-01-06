require 'rubygems'
require 'bundler/setup'
require 'semver'

module XSemVer
  APPROXIMATE_OPERATORS = [
    '~>',
    '~',
  ]

  COMPARISON_OPERATORS = [
    '>=',
    '>',
    '<=',
    '<',
    '=',
  ] + APPROXIMATE_OPERATORS

  WILDCARD_CHARS = [
    'x',
    '*',
  ]

  PREFERRED_WILDCARD = WILDCARD_CHARS[0]

  # http://stackoverflow.com/questions/535721/ruby-max-integer
  FIXNUM_MAX = (2 ** (0.size * 8 - 2) - 1)

  BIGGEST_SEMVER = SemVer.new FIXNUM_MAX, FIXNUM_MAX, FIXNUM_MAX
  SMALLEST_SEMVER = SemVer.new 0, 0, 0
  IMPOSSIBLY_SMALLEST_SEMVER = SemVer.new -1, -1, -1

  class SemVerRange < SemVer
    attr_accessor :comparison_operator

    def initialize(major = 0, minor = 0, patch = 0, comparison_operator = nil)
      ensure_valid_parts major, minor, patch
      ensure_valid_comparison_operator comparison_operator

      @major = major
      @minor = minor
      @patch = patch
      @comparison_operator = comparison_operator
    end

    def is_range?
      true
    end

    def matches?(version_string_or_semver)
      return true if accepts_any_version?

      if version_string_or_semver.is_a? ::XSemVer::SemVer
        other_semver = version_string_or_semver
      else
        other_semver = ::XSemVer::SemVer.parse version_string_or_semver
      end

      lower_bound <= other_semver and other_semver < upper_bound
    end

    def has_wildcard?
      [major, minor, patch].any? {|p| is_wildcard_char? p }
    end

    def accepts_any_version?
      [major, minor, patch].all? {|p| is_wildcard_char? p }
    end

    def non_wildcard_parts
      [major, minor, patch].reject {|p| is_wildcard_char? p }
    end

    def has_comparison_operator?
      !!@comparison_operator
    end

    def increment!(part = nil)
      # Doesn't make sense to increment '*'
      return self if accepts_any_version?

      # Figure out the part to increment
      part = last_non_wildcard_part_symbol if part.nil?

      new_parts = increment_specific_part_helper part, [major, minor, patch]

      # Carry over wildcards (since SemVer's increment method
      # may have zeroed them out)
      new_parts = new_parts.zip([major, minor, patch]).map do |new_part, old_part|
        if is_wildcard_char? old_part
          old_part
        else
          new_part
        end
      end

      # Modify the internal state
      @major, @minor, @patch = new_parts
      self
    end

    # Prepends the comparison operator to the normal format
    # (if it exists on this range)
    def format(fmt)
      prefix = ''
      prefix = "#{@comparison_operator} " if has_comparison_operator?

      "#{prefix}#{super fmt}"
    end

    def self.parse(version_string, format = nil, allow_missing = true)
      if is_range_format? version_string
        # Parse as a range if it looks like one
        parse_range version_string, format, allow_missing
      else
        puts "fallthrough to base parse"
        # Otherwise just parse and create a regular SemVer
        ::XSemVer::SemVer.parse version_string, format, allow_missing
      end
    end

    def lower_bound
      if comparison_operator == '<' and to_a[0...3] == [0, 0, 0]
        IMPOSSIBLY_SMALLEST_SEMVER.dup

      elsif ['<', '<='].include? comparison_operator
        SMALLEST_SEMVER.dup

      # `> 1.2.3`'s lower bound is `1.2.4`
      # `> 1.2.x`'s lower bound is `1.3.0`
      elsif comparison_operator == '>'
        new_range = increment
        new_range.build_as_semver_with_wildcards_as_zeros

      # `>= 1.2.3`'s lower bound is `1.2.3`
      # `~> 1.2.3`'s lower bound is `1.2.3`
      #  `= 1.2.3`'s lower bound is `1.2.3`
      #    `1.2.x`'s lower bound is `1.2.0`
      else
        build_as_semver_with_wildcards_as_zeros
      end
    end

    def lower_bound_inclusive
      lower_bound
    end

    def upper_bound
      if ['>', '>='].include? comparison_operator
        BIGGEST_SEMVER.dup

      # `~> 1.2` or `~> 1.2.x`'s upper bound is `2.0.0`
      # `~> 1.2.3`'s upper bound is `1.3.0`
      elsif has_approximate_comparison_operator?

        # New temp range with one more wildcard than it previously had (1.2.x -> 1.x.x)
        new_range = dup
        new_range.send "#{last_non_wildcard_part_symbol}=", PREFERRED_WILDCARD

        # Increment that temp range to get the upper bound
        new_range.increment!
        new_range.build_as_semver_with_wildcards_as_zeros

      # `<= 1.2.3`'s upper bound is `1.2.4`
      #  `< 1.2.x`'s upper bound is `1.3.0`
      #    `1.2.x`'s upper bound is `1.3.0`
      elsif has_wildcard? or comparison_operator == '<='
        new_range = increment
        new_range.build_as_semver_with_wildcards_as_zeros

      #  `< 1.2.3`'s upper bound is `1.2.3`
      #  `= 1.2.3`'s upper bound is `1.2.3`
      else
        build_as_semver_with_wildcards_as_zeros
      end
    end

    # Mostly just needed to simplify the implementation
    # of <=>
    def upper_bound_inclusive
      result = upper_bound

      # Some special cases:
      #   - return a semver "off-the-charts" if the upper bound is 0.0.0
      #   - deal with ranges that are not really ranges (like =v1.2.3)
      #   - The "biggest semver" is its own upper bound
      return IMPOSSIBLY_SMALLEST_SEMVER if result.to_a[0...3] == [0, 0, 0]
      return result if upper_bound == lower_bound
      return result if result == XSemVer::BIGGEST_SEMVER

      # Figure out the part to decrement, taking care that we can't decrement
      # a part that is already at 0
      index_to_decrement = 2
      while result.to_a[index_to_decrement] == 0 do
        index_to_decrement -= 1
      end

      part_to_decrement = [:major, :minor, :patch][index_to_decrement]

      # Dynamically decrement the specified part
      value = result.send(part_to_decrement) - 1
      result.send "#{part_to_decrement}=", value

      # All the parts following the decremented one will be set to infinity
      parts_to_set_to_infinity = [:major, :minor, :patch][index_to_decrement + 1...3]

      parts_to_set_to_infinity.each do |part|
        result.send "#{part}=", FIXNUM_MAX
      end

      result
    end

    # Compare to other semvers or ranges by its upper and lower bounds
    #
    # Example ordering:
    #   -  `> v1.1.0`
    #   - `>= v1.1.0`
    #   -  `> v1.0.1`
    #   -  `> v1.0.0`
    #   ...
    #   - `~> v1.1`
    #   -    `v1.x.x`
    #   - `~> v1.1.0`
    #
    #   -    `v1.1.0`
    #   - `<= v1.1.0`
    #   - `~> v1.0.1`
    #   - `~> v1.0.0`
    #   -    `v1.0.x`
    #   -  `< v1.1.0`
    #
    #   -    `v1.0.0`
    #   - `<= v1.0.0`
    #   - `~> v0.1`
    #   -  `< v1.0.0`
    #   -    `v0.9.9`
    #   - `~> v0.1.2`
    #   - `~> v0.1.1`
    #
    #   - `~> v0.0.0`
    #      - `v0.0.1`
    #   - `<= v0.0.0` (make invalid?)
    #   -  `< v0.0.0` (make invalid?)
    def <=>(other)
      if other.is_a? SemVerRange
        # print "\n", "upper compare #{upper_bound.inspect} <=> #{other.upper_bound.inspect} => #{upper_bound <=> other.upper_bound}", "\n\n"
        # print "\n", "lower compare #{lower_bound.inspect} <=> #{other.lower_bound.inspect} => #{lower_bound <=> other.lower_bound}", "\n\n"
        cmp = upper_bound_inclusive <=> other.upper_bound_inclusive
        cmp = lower_bound <=> other.lower_bound if cmp == 0

        # Always sort wildcards behind comparison operators (when otherwise idential)
        # cmp = -1 if cmp == 0 and has_wildcard? and not other.has_wildcard?

        # Always sort `<` behind `~>` (when otherwise idential)
        cmp = -1 if cmp == 0 and comparison_operator == '<' and other.has_approximate_comparison_operator?
        cmp

      elsif other.is_a? SemVer
        cmp = upper_bound_inclusive <=> other
        cmp = lower_bound <=> other if cmp == 0

        # Always sort ranges behind regular semvers when identical
        cmp = -1 if cmp == 0
        cmp

      else
        self <=> SemVerRange.parse(other)
      end
    end

    # Override == to ensure wildcard behavior as described in <=>
    def == other
      (self <=> other) == 0
    end


    # Class methods

    def self.is_range_format? str
      starts_with_operator? str or has_wildcard_format? str
    end

    def self.starts_with_operator? str
      match = operator_regex.match(str)
      match && match[:operator]
    end

    def self.is_wildcard_char? str
      WILDCARD_CHARS.include? str
    end

    def self.has_wildcard_format? str
      match = major_minor_patch_with_wildcards_regex.match(str)

      # Check that any of the matches (major, minor, or patch bits)
      # is a wildcard
      if match
        return match.captures.any? do |capture|
          is_wildcard_char? capture
        end
      end

      nil
    end

    def self.major_minor_patch_with_wildcards_regex
      return @major_minor_patch_with_wildcards_regex unless @major_minor_patch_with_wildcards_regex.nil?

      any_wildcard = WILDCARD_CHARS.map { |w| Regexp.escape(w) }.join('|')
      digit_or_wildcard = "(\\d+|#{any_wildcard})"
      three_digits_or_wildcards = ([digit_or_wildcard] * 3).join('.')

      @major_minor_patch_with_wildcards_regex = Regexp.new ".*#{three_digits_or_wildcards}.*"
    end

    def self.operator_regex
      return @operator_regex unless @operator_regex.nil?

      union_of_operators = COMPARISON_OPERATORS.map {|o| Regexp.escape(o) }.join('|')
      @operator_regex = /^\s*(?<operator>#{union_of_operators})\s*(?<rest>.+)/
    end

    # Wouldn't need to copy all of parse if it was broken up into
    # a few separate functions in semver
    #
    # What was changed:
    #  - Accept 'x' or '*' for major, minor, or patch
    #  - Looks for an operator at the beginning of the string
    #  - Don't allow prerelease or metadata string in ranges
    #  - If it has an approximate comparison operator and the minor or
    #    patch is missing (and allow_missing is true) then set the missing
    #    parts to a wildcard
    #
    #  Also, I realized that allow_missing doesn't work with the default format.
    #  To fix that, we'd need to add some fanciness to make the dots between version
    #  parts be optional or something similar.
    def self.parse_range(version_string, format = nil, allow_missing = true)
      format ||= TAG_FORMAT
      comparison_operator = nil

      operator_match = operator_regex.match version_string
      if operator_match
        comparison_operator = operator_match[:operator]
        version_string = operator_match[:rest]
      end

      regex_str = Regexp.escape format

      # Convert all the format characters to named capture groups
      regex_str = regex_str.
        gsub('%M', '(?<major>\d+|[x\*])').
        gsub('%m', '(?<minor>\d+|[x\*])').
        gsub('%p', '(?<patch>\d+|[x\*])').
        gsub('%s', '(?:-(?<special>[A-Za-z][0-9A-Za-z\.]+))?').
        gsub('%d', '(?:\x2B(?<metadata>[0-9A-Za-z][0-9A-Za-z\.]*))?')

      # puts "version_string: #{version_string}"
      # print "regex_str:  #{regex_str.inspect}"

      regex = Regexp.new(regex_str)
      match = regex.match version_string

      if match
        major = minor = patch = nil
        special = metadata = nil

        # Extract out the version parts
        major = match[:major].to_i if match.names.include? 'major'
        minor = match[:minor].to_i if match.names.include? 'minor'
        patch = match[:patch].to_i if match.names.include? 'patch'
        special = match[:special] if match.names.include? 'special'
        metadata = match[:metadata] if match.names.include? 'metadata'

        # Ranges can't have prerelease or metadata strings
        if special or metadata
          raise InvalidSemVerRangeError.new "A SemVerRange cannot have prerelease or metadata strings"
        end

        # Failed parse if major, minor, or patch wasn't found
        # and allow_missing is false
        return nil if !allow_missing and [major, minor, patch].any? {|x| x.nil? }

        # Otherwise, allow them to default to zero (`1.2` -> 1.2.0) or
        # wildcard (`~> 1.2` -> 1.2.x)
        default_part = 0
        default_part = PREFERRED_WILDCARD if APPROXIMATE_OPERATORS.include? comparison_operator

        major ||= default_part
        minor ||= default_part
        patch ||= default_part

        SemVerRange.new major, minor, patch, comparison_operator
      end

    end

    protected

    def ensure_valid_parts(major, minor, patch)
      is_digit_or_wildcard? major or raise InvalidSemVerRangeError.new "Invalid major: #{major}"
      is_digit_or_wildcard? minor or raise InvalidSemVerRangeError.new "Invalid minor: #{minor}"
      is_digit_or_wildcard? patch or raise InvalidSemVerRangeError.new "Invalid patch: #{patch}"
    end

    def is_digit_or_wildcard?(part)
      part.is_a? Integer or is_wildcard_char? part
    end

    def ensure_valid_comparison_operator(operator)
      return true if operator.nil?
      COMPARISON_OPERATORS.include? operator or raise InvalidSemVerRangeError.new "Invalid comparison operator"
    end

    def has_approximate_comparison_operator?
      APPROXIMATE_OPERATORS.include? @comparison_operator
    end

    def build_as_semver_with_wildcards_as_zeros
      parts_padded_with_zero = non_wildcard_parts.fill(0, non_wildcard_parts.length...3)
      ::XSemVer::SemVer.new(*parts_padded_with_zero)
    end

    def has_non_preferred_wildcard?
      [major, minor, patch].any? {|p| is_non_preferred_wildcard_char? p }
    end

    def last_non_wildcard_part_symbol
      [:major, :minor, :patch][non_wildcard_parts.length - 1]
    end


    # Aliases of class functions

    def is_wildcard_char? str
      self.class.is_wildcard_char? str
    end

  end

  class InvalidSemVerRangeError < RuntimeError
  end
end
