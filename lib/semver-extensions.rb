require 'rubygems'
require 'bundler/setup'

# A few extensions to the base SemVer class
module XSemVer
  class SemVer

    def is_range?
      false
    end

    def to_a
      # Only return the special/prerelease and metadata strings if they exist
      [major, minor, patch, special, metadata].reject do |part|
        part.nil? or part == ''
      end
    end

    def matches?(version_string_or_semver)
      if version_string_or_semver.is_a? SemVer
        other_semver = version_string_or_semver
      else
        other_semver = SemVer.parse version_string_or_semver
      end

      self == other_semver
    end

    def increment!(part_to_increment=nil)
      # Figure out the part to increment if not passed
      part_to_increment ||= :patch

      @major, @minor, @patch, @special, @metadata = increment_specific_part_helper part_to_increment, to_a
      self
    end

    def increment(part_to_increment=nil)
      dup.increment! part_to_increment
    end

    private

    def increment_specific_part_helper part_to_increment, parts
      new_major, new_minor, new_patch = parts
      new_special = new_metadata = ''

      if part_to_increment == :major
        new_major += 1
        new_minor = 0
        new_patch = 0
      elsif part_to_increment == :minor
        new_minor += 1
        new_patch = 0
      elsif part_to_increment == :patch
        new_patch += 1
      elsif part_to_increment == :prerelease or part_to_increment == :special
        #TODO, implement how node-semver does it? (https://github.com/isaacs/node-semver/blob/master/semver.js#L366)
        raise "Incrementing prerelease strings unimplemented"
      else
        raise "Invalid part to increment: #{part_to_increment.inspect}"
      end

      [new_major, new_minor, new_patch, new_special, new_metadata]
    end
  end
end
