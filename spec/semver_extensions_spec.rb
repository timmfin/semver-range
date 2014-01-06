require 'spec_helper'
require 'semver-extensions'

# Test the extensions to SemVer
describe XSemVer::SemVer do

  it "should convert all its parts to an array" do
    semvers = [
      SemVer.new(1),
      SemVer.new(1, 2),
      SemVer.new(1, 2, 3),
      SemVer.new(1, 2, 3, 'alpha'),
      SemVer.new(1, 2, 3, 'alpha', 'somebuildmetadata'),
    ]

    arrays = [
      [1, 0, 0],
      [1, 2, 0],
      [1, 2, 3],
      [1, 2, 3, 'alpha'],
      [1, 2, 3, 'alpha', 'somebuildmetadata'],
    ]

    semvers.zip(arrays).each do |semver, array_to_match|
      semver.to_a.should eq(array_to_match)
    end
  end

  it "should not be a range" do
    SemVer.new(1).is_range?.should eq(false)
  end

  it "should match itself" do
    SemVer.new(1,2,3).matches?(SemVer.new(1,2,3)).should be_true
  end

  it "should not match anything else" do
    SemVer.new(1,2,3).matches?(SemVer.new(1,2,4)).should be_false
    SemVer.new(1,2,3).matches?(SemVer.new(1,3,3)).should be_false
    SemVer.new(1,2,3).matches?(SemVer.new(2,2,3)).should be_false
  end

  it "should increment the patch by default" do
    SemVer.new(1).increment.should eq(SemVer.new(1,0,1))
    SemVer.new(1, 2).increment.should eq(SemVer.new(1,2,1))
    SemVer.new(1, 2, 42).increment.should eq(SemVer.new(1,2,43))
    SemVer.new(1, 2, 3, 'beta').increment.should eq(SemVer.new(1,2,4))
    SemVer.new(1, 2, 3, 'beta', 'somedata').increment.should eq(SemVer.new(1,2,4))
  end

  it "should not mutate the current instance" do
    old_semver = SemVer.new(1,2,3)
    new_semver = old_semver.increment

    new_semver.hash.should_not eq(old_semver.hash)
    old_semver.should eq(SemVer.new(1,2,3))
  end

  it "should mutate the current instance when used with a bang" do
    old_semver = SemVer.new(1,2,3)
    new_semver = old_semver.increment!

    new_semver.hash.should eq(old_semver.hash)
    old_semver.should eq(SemVer.new(1,2,4))
  end

  it "should increment the patch part" do
    SemVer.new(1,2,3).increment(:patch).should eq(SemVer.new(1,2,4))
  end

  it "should increment the minor part" do
    SemVer.new(1,2,3).increment(:minor).should eq(SemVer.new(1,3,0))
  end

  it "should increment the major part" do
    SemVer.new(1,2,3).increment(:major).should eq(SemVer.new(2,0,0))
  end

  it "should fail when the prerelease is incremented" do
    expect { SemVer.new(1, 2, 3, 'alpha').increment :prerelease }.to raise_error
  end

  it "should blow away metadata when incremented" do
    new_semver = SemVer.new(1, 2, 3, '', 'foobar').increment
    new_semver.metadata.should eq('')
  end

end
