require 'semver'

module XSemVer
  APPROXIMATE_OPERATORS = [
    '~',
    '~>',
  ]

  COMPARISON_OPERATORS = [
    '>',
    '>=',
    '<',
    '<=',
    '=',
  ] + APPROXIMATE_OPERATORS

  WILDCARD_CHARS = [
    'x',
    '*',
  ]

  PREFERRED_WILDCARD = WILDCARD_CHARS[0]

  # http://stackoverflow.com/questions/535721/ruby-max-integer
  FIXNUM_MAX = (2 ** (0.size * 8 - 2) - 1)

  BIGGEST_SEMVER = ::XSemVer::SemVer.new FIXNUM_MAX, FIXNUM_MAX, FIXNUM_MAX
  SMALLEST_SEMVER = ::XSemVer::SemVer.new 0, 0, 0

  class SemVerRange < SemVer
    attr_accessor :comparison_operator

    def initialize(major, minor, patch, comparison_operator = nil)
      ensure_valid_parts major, minor, patch
      ensure_valid_comparison_operator comparison_operator

      @major = major
      @minor = minor
      @patch = patch
      @comparison_operator = comparison_operator
    end

    def ensure_valid_parts(major, minor, patch)
      is_digit_or_wildcard? major or raise InvalidSemVerRangeError.new "Invalid major: #{major}"
      is_digit_or_wildcard? minor or raise InvalidSemVerRangeError.new "Invalid minor: #{minor}"
      is_digit_or_wildcard? patch or raise InvalidSemVerRangeError.new "Invalid patch: #{patch}"
    end

    def ensure_valid_comparison_operator(operator)
      return true if operator.nil?
      COMPARISON_OPERATORS.include? @comparison_operator or raise InvalidSemVerRangeError.new "Invalid comparison operator"
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

    def has_wildcard
      [major, minor, patch].any? {|p| is_wildcard_char? p }
    end

    def accepts_any_version?
      [major, minor, patch].all? {|p| is_wildcard_char? p }
    end

    def non_wildcard_parts
      [major, minor, patch].reject {|p| is_wildcard_char? p }
    end

    def has_comparison_operator
      !!@comparison_operator
    end

    def increment
      # Doesn't make sense to increment '*'
      return dup if accepts_any_version?

      # Figure out the part to increment
      part_to_increment = [:major, :minor, :patch][non_wildcard_parts.length - 1]
      new_parts = increment_specific_part_helper part_to_increment, [major, minor, patch]

      # Carry over wildcards (since SemVer's increment method
      # may have zeroed them out)
      new_parts = new_parts.zip([major, minor, patch]).map do |new_part, old_part|
        if is_wildcard_char? old_part
          old_part
        else
          new_part
        end
      end

      # Build a new range, ignoring any of the special or metadata parts
      SemVerRange.new(*new_parts[0...3], comparison_operator)
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
        # Otherwise just parse and create a regular SemVer
        ::XSemVer::SemVer.parse version_string, format, allow_missing
      end
    end

    private

    def has_approximate_comparison_operator?
      APPROXIMATE_OPERATORS.include? @comparison_operator
    end

    def lower_bound
      if ['<', '<='].include? comparison_operator
        SMALLEST_SEMVER.dup

      # `> 1.2.3`'s lower bound is `1.2.4`
      # `> 1.2.x`'s lower bound is `1.3.0`
      elsif comparison_operator == '>'
        new_range = increment
        new_range.convert_to_range_with_wildcards_as_zeros

      # `>= 1.2.3`'s lower bound is `1.2.3`
      # `~> 1.2.3`'s lower bound is `1.2.3`
      #  `= 1.2.3`'s lower bound is `1.2.3`
      #    `1.2.x`'s lower bound is `1.2.0`
      else
        convert_to_range_with_wildcards_as_zeros
      end
    end

    def upper_bound
      if ['>', '>='].include? comparison_operator
        BIGGEST_SEMVER.dup

      # `~> 1.2.3`'s upper bound is `1.3.0`
      #  `< 1.2.x`'s upper bound is `1.3.0`
      #  `< 1.2.3`'s upper bound is `1.2.4`
      elsif has_approximate_comparison_operator? or comparison_operator == '<'
        new_range = increment
        new_range.convert_to_range_with_wildcards_as_zeros

      # `<= 1.2.3`'s upper bound is `1.2.3`
      #  `= 1.2.3`'s upper bound is `1.2.3`
      #    `1.2.x`'s upper bound is `1.2.0`
      else
        convert_to_range_with_wildcards_as_zeros
      end
    end

    def convert_to_range_with_wildcards_as_zeros
      parts_padded_with_zero = non_wildcard_parts.fill(0, non_wildcard_parts...3)
      ::XSemVer::SemVer.new(*parts_padded_with_zero)
    end

    def self.is_range_format str
      starts_with_operator str or has_wildcard_format str
    end

    def self.starts_with_operator str
      not operator_regex.match(str).nil?
    end

    def self.is_wildcard_char? str
      WILDCARD_CHARS.include? str
    end

    def self.has_wildcard_format str
      match = major_minor_patch_with_wildcards_regex.match(str)

      # Check that any of the matches (major, minor, or patch bits)
      # is a wildcard
      if match
        match.captures.any? do |capture|
          is_wildcard_char? capture
        end
      end

      nil
    end

    def self.major_minor_patch_with_wildcards_regex
      return @major_minor_patch_with_wildcards_regex unless major_minor_patch_with_wildcards_regex.nil?

      any_wildcard = WILDCARD_CHARS.map { |w| Regex.escape(w) }.join('|')
      digit_or_wildcard = "\d+|#{any_wildcard}"
      three_digits_or_wildcards = ([digit_or_wildcard] * 3).join('.')

      @major_minor_patch_with_wildcards_regex = Regex.new three_digits_or_wildcards
    end

    def self.operator_regex
      return @operator_regex unless operator_regex.nil?

      union_of_operators = COMPARISON_OPERATORS.map {|o| Regex.escape(o) }.join('|')
      @operator_regex = /^\s*(?<operator>#{union_of_operators})\s*(?<rest>.+)/
    end

    # Wouldn't need to copy all of parse if it was broken up into
    # a few separate functions in semver
    #
    # What was changed:
    #  - Accept 'x' or '*' for major, minor, or patch
    #  - Looks for an operator at the beginning of the string
    #  - Don't allow prerelease or metadata string in ranges
    #  - If a minor or patch is missing (and allow_missing is true), then set
    #    them to a wildcard instead of 0
    def self.parse_range(version_string, format = nil, allow_missing = true)
      format ||= TAG_FORMAT
      comparison_operator = nil

      operator_match = operator_regex.match version_string
      if operator_match
        comparison_operator, rest = operator_match.named_captures
        version_string = rest
      end

      regex_str = Regexp.escape format

      # Convert all the format characters to named capture groups
      regex_str = regex_str.
        gsub('%M', '(?<major>\d+|[x\*])').
        gsub('%m', '(?<minor>\d+|[x\*])').
        gsub('%p', '(?<patch>\d+|[x\*])').
        gsub('%s', '(?:-(?<special>[A-Za-z][0-9A-Za-z\.]+))?').
        gsub('%d', '(?:\x2B(?<metadata>[0-9A-Za-z][0-9A-Za-z\.]*))?')

      print "\n", "regex_str:  #{regex_str.inspect}", "\n\n"

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

        # Otherwise, allow them to default to a wildcard (1.2 -> 1.2.x)
        major ||= PREFERRED_WILDCARD
        minor ||= PREFERRED_WILDCARD
        patch ||= PREFERRED_WILDCARD

        SemVerRange.new major, minor, patch, comparison_operator
      end

    end
  end

  class InvalidSemVerRangeError < RuntimeError
  end
end
