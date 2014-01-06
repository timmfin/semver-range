require 'spec_helper'
require 'semver-range'

x = 'x'
i = infinity = XSemVer::FIXNUM_MAX
SemVerRange = XSemVer::SemVerRange

TAG_FORMAT_WITHOUT_V = "%M.%m.%p%s%d"


describe XSemVer::SemVerRange do

  it "should be a range" do
    SemVerRange.new(1, 2, 3, '<').is_range?.should be_true
  end

  it "should fill in missing initialize values with zeros" do
    SemVerRange.new(1, 2).patch.should eq(0)

    SemVerRange.new(1).minor.should eq(0)
    SemVerRange.new(1).patch.should eq(0)

    SemVerRange.new.major.should eq(0)
    SemVerRange.new.minor.should eq(0)
    SemVerRange.new.patch.should eq(0)
  end

  it "should accept any version when is '*'" do
    SemVerRange.new('*', '*', '*').accepts_any_version?.should be_true
    SemVerRange.new(x, x, x).accepts_any_version?.should be_true
  end

  it "should not accept any version when is anything else" do
    SemVerRange.new(1, 2, 3).accepts_any_version?.should be_false
    SemVerRange.new(1, 2, x).accepts_any_version?.should be_false
    SemVerRange.new(1, x, x).accepts_any_version?.should be_false
  end

  it "should say it has a wildcard when it actually has any wildcards" do
    SemVerRange.new(1, 2, 3).has_wildcard?.should be_false
    SemVerRange.new(1, 2, x).has_wildcard?.should be_true
    SemVerRange.new(1, '*', '*').has_wildcard?.should be_true
    SemVerRange.new(x, x, x).has_wildcard?.should be_true
  end

  it "should have non wildcard parts" do
    SemVerRange.new(1, 2, 3).non_wildcard_parts.should eq([1, 2, 3])
    SemVerRange.new(1, 2, x).non_wildcard_parts.should eq([1, 2])
    SemVerRange.new(1, '*', '*').non_wildcard_parts.should eq([1])
    SemVerRange.new(x, x, x).non_wildcard_parts.should eq([])
  end

  it "should have let you know when it has an operator" do
    SemVerRange.new(1, 2, 3).has_comparison_operator?.should be_false
    SemVerRange.new(1, 2, 3, '<').has_comparison_operator?.should be_true
  end

  it "should output the comparison operator at the front of the formatted string" do
    SemVerRange.new(1, 2, 3).to_s.should eq("v1.2.3")
    SemVerRange.new(1, 2, 3, '<').to_s.should eq("< v1.2.3")
  end

  it "should treat either wildcard char as the same" do
    SemVerRange.new(1, 2, x).should eq(SemVerRange.new(1, 2, '*'))
    SemVerRange.new(1, '*', '*').should eq(SemVerRange.new(1, x, x))
  end

  it "should have an upper bound" do
    ranges = [
      SemVerRange.new(1, 1, 0, '>'),
      SemVerRange.new(1, 1, 0, '>='),
      SemVerRange.new(1, 0, 1, '>'),
      SemVerRange.new(1, 0, 0, '>'),

      SemVerRange.new(1, 1,  x, '~>'),
      SemVerRange.new(1, x, x),
      SemVerRange.new(1, 1, 0, '~>'),

      SemVerRange.new(1, 1, 0),
      SemVerRange.new(1, 1, 0, '<='),
      SemVerRange.new(1, 0, 1, '~>'),
      SemVerRange.new(1, 0, 0, '~>'),
      SemVerRange.new(1, 0, x),
      SemVerRange.new(1, 1, 0, '<'),

      SemVerRange.new(1, 0, 0),
      SemVerRange.new(1, 0, 0, '<='),
      SemVerRange.new(0, 1, 2, '~>'),
      SemVerRange.new(0, 1, 1, '~>'),
      SemVerRange.new(1, 0, 0, '<'),
      SemVerRange.new(0, 9, 9),

      SemVerRange.new(0, 0, 0, '~>'),
      SemVerRange.new(0, 0, 1),
      SemVerRange.new(0, 0, 0, '<='),
      SemVerRange.new(0, 0, 0, '<'),
    ]

    upper_bounds = [
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,

      SemVer.new(2, 0, 0),
      SemVer.new(2, 0, 0),
      SemVer.new(1, 2, 0),

      SemVer.new(1, 1, 1),
      SemVer.new(1, 1, 1),
      SemVer.new(1, 1, 0),
      SemVer.new(1, 1, 0),
      SemVer.new(1, 1, 0),
      SemVer.new(1, 1, 0),

      SemVer.new(1, 0, 1),
      SemVer.new(1, 0, 1),
      SemVer.new(0, 2, 0),
      SemVer.new(0, 2, 0),
      SemVer.new(1, 0, 0),
      SemVer.new(0, 9, 10),

      SemVer.new(0, 1, 0),
      SemVer.new(0, 0, 2),
      SemVer.new(0, 0, 1),
      SemVer.new(0, 0, 0),
    ]

    ranges.zip(upper_bounds).each do |range, expected_upper_bound|
      # puts "#{range} should have upper bound: #{expected_upper_bound}"
      range.upper_bound.should eq(expected_upper_bound)
    end
  end

  it "should have an inclusive upper bound" do
    ranges = [
      SemVerRange.new(1, 1, 0, '>'),
      SemVerRange.new(1, 1, 0, '>='),
      SemVerRange.new(1, 0, 1, '>'),
      SemVerRange.new(1, 0, 0, '>'),

      SemVerRange.new(1, 1,  x, '~>'),
      SemVerRange.new(1, x, x),
      SemVerRange.new(1, 1, 0, '~>'),

      SemVerRange.new(1, 1, 0),
      SemVerRange.new(1, 1, 0, '<='),
      SemVerRange.new(1, 0, 1, '~>'),
      SemVerRange.new(1, 0, 0, '~>'),
      SemVerRange.new(1, 0, x),
      SemVerRange.new(1, 1, 0, '<'),

      SemVerRange.new(1, 0, 0),
      SemVerRange.new(1, 0, 0, '<='),
      SemVerRange.new(0, 1, 2, '~>'),
      SemVerRange.new(0, 1, 1, '~>'),
      SemVerRange.new(1, 0, 0, '<'),
      SemVerRange.new(0, 9, 9),

      SemVerRange.new(0, 0, 0, '~>'),
      SemVerRange.new(0, 0, 1),
      SemVerRange.new(0, 0, 0, '<='),
      SemVerRange.new(0, 0, 0, '<'),
    ]

    inclusive_upper_bounds = [
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,
      XSemVer::BIGGEST_SEMVER,

      SemVer.new(1, i, i),
      SemVer.new(1, i, i),
      SemVer.new(1, 1, i),

      SemVer.new(1, 1, 0),
      SemVer.new(1, 1, 0),
      SemVer.new(1, 0, i),
      SemVer.new(1, 0, i),
      SemVer.new(1, 0, i),
      SemVer.new(1, 0, i),

      SemVer.new(1, 0, 0),
      SemVer.new(1, 0, 0),
      SemVer.new(0, 1, i),
      SemVer.new(0, 1, i),
      SemVer.new(0, i, i),
      SemVer.new(0, 9, 9),

      SemVer.new(0, 0, i),
      SemVer.new(0, 0, 1),
      SemVer.new(0, 0, 0),
      SemVer.new(-1, -1, -1),
    ]

    ranges.zip(inclusive_upper_bounds).each do |range, expected_inclusive_upper_bound|
      # puts "#{range} should have an inclusive upper bound: #{expected_inclusive_upper_bound} (upper == #{range.upper_bound})"
      range.upper_bound_inclusive.should eq(expected_inclusive_upper_bound)
    end
  end

  it "should have a lower bound" do
    ranges = [
      SemVerRange.new(1, 1, 0, '>'),
      SemVerRange.new(1, 1, 0, '>='),
      SemVerRange.new(1, 0, 1, '>'),
      SemVerRange.new(1, 0, 0, '>'),

      SemVerRange.new(1, 1,  x, '~>'),
      SemVerRange.new(1, x, x),
      SemVerRange.new(1, 1, 0, '~>'),

      SemVerRange.new(1, 1, 0),
      SemVerRange.new(1, 1, 0, '<='),
      SemVerRange.new(1, 0, 1, '~>'),
      SemVerRange.new(1, 0, 0, '~>'),
      SemVerRange.new(1, 0, x),
      SemVerRange.new(1, 1, 0, '<'),

      SemVerRange.new(1, 0, 0),
      SemVerRange.new(1, 0, 0, '<='),
      SemVerRange.new(0, 1, 2, '~>'),
      SemVerRange.new(0, 1, 1, '~>'),
      SemVerRange.new(1, 0, 0, '<'),
      SemVerRange.new(0, 9, 9),

      SemVerRange.new(0, 0, 0, '~>'),
      SemVerRange.new(0, 0, 1),
      SemVerRange.new(0, 0, 0, '<='),
      SemVerRange.new(0, 0, 0, '<'),
    ]

    lower_bounds = [
      SemVer.new(1, 1, 1),
      SemVer.new(1, 1, 0),
      SemVer.new(1, 0, 2),
      SemVer.new(1, 0, 1),

      SemVer.new(1, 1, 0),
      SemVer.new(1, 0, 0),
      SemVer.new(1, 1, 0),

      SemVer.new(1, 1, 0),
      XSemVer::SMALLEST_SEMVER,
      SemVer.new(1, 0, 1),
      SemVer.new(1, 0, 0),
      SemVer.new(1, 0, 0),
      XSemVer::SMALLEST_SEMVER,

      SemVer.new(1, 0, 0),
      XSemVer::SMALLEST_SEMVER,
      SemVer.new(0, 1, 2),
      SemVer.new(0, 1, 1),
      XSemVer::SMALLEST_SEMVER,
      SemVer.new(0, 9, 9),

      SemVer.new(0, 0, 0),
      SemVer.new(0, 0, 1),
      SemVer.new(0, 0, 0),
      XSemVer::IMPOSSIBLY_SMALLEST_SEMVER,
    ]

    ranges.zip(lower_bounds).each do |range, expected_lower_bound|
      # puts "#{range} should have lower bound: #{expected_lower_bound}"
      range.lower_bound.should eq(expected_lower_bound)
      range.lower_bound_inclusive.should eq(expected_lower_bound)
    end
  end


  it "should compare against other simple ranges" do
    ranges = [
      SemVerRange.new(0, 1, 0),
      SemVerRange.new(0, 1, 1),
      SemVerRange.new(0, 2, 0),
      SemVerRange.new(1, 0, 0)
    ]

    (ranges.size - 1).times do |n|
      ranges[n].should < ranges[n+1]
    end
  end

  it "should compare against semvers" do
    ranges = [
      SemVerRange.new(0, 1, 0),
      SemVerRange.new(0, 1, 1),
      SemVerRange.new(0, 2, 0),
      SemVerRange.new(1, 0, 0),
    ]

    semvers_equal_but_still_greater = [
      SemVer.new(0, 1, 0),
      SemVer.new(0, 1, 1),
      SemVer.new(0, 2, 0),
      SemVer.new(1, 0, 0),
    ]

    (ranges.size - 1).times do |n|
      # SemVerRange should be less than SemVerRange when they have equivalent parts"
      ranges[n].should < semvers_equal_but_still_greater[n]

      (n + 1).upto(semvers_equal_but_still_greater.size - 1) do |j|
        # print "\n", "#{ranges[n].inspect} < #{semvers_equal_but_still_greater[j]}", "\n\n"
        ranges[n].should < semvers_equal_but_still_greater[j]
      end
    end
  end

  it "should compare against strings" do
    small_range = SemVerRange.new(0, 1, 0)
    big_range = SemVerRange.new(1, 0, 1)

    strings = [
      "v0.1.0",
      "v0.1.1",
      "v0.2.0",
      "v1.0.0",
    ]

    strings.each do |string|
      small_range.should < string
      big_range.should > string
    end
  end


  it "should compare against ranges and semvers" do
    correct_order_groups = [
      [
        SemVerRange.new(1, 1, 0, '>'),
        SemVerRange.new(1, 1, 0, '>='),
        SemVerRange.new(1, 0, 1, '>'),
        SemVerRange.new(1, 0, 0, '>'),
      ], [
        SemVerRange.new(1, 1,  x, '~>'),
        SemVerRange.new(1, x, x),
        SemVerRange.new(1, 1, 0, '~>'),
      ], [
        SemVerRange.new(1, 1, 0),
        SemVerRange.new(1, 1, 0, '<='),
        SemVerRange.new(1, 0, 1, '~>'),
        SemVerRange.new(1, 0, 0, '~>'),
        SemVerRange.new(1, 0, x),
        SemVerRange.new(1, 1, 0, '<'),
      ], [
        SemVerRange.new(1, 0, 0),
        SemVerRange.new(1, 0, 0, '<='),
        SemVerRange.new(0, 1, x, '~>'),
        SemVerRange.new(1, 0, 0, '<'),
      ], [
        SemVerRange.new(0, 9, 9),
        SemVerRange.new(0, 1, 2, '~>'),
        SemVerRange.new(0, 1, 1, '~>'),
      ], [
        SemVerRange.new(0, 0, 0, '~>'),
        SemVerRange.new(0, 0, 1),
        SemVerRange.new(0, 0, 0, '<='),
        SemVerRange.new(0, 0, 0, '<'),
      ]
    ]

    # Make ascending (since listed above as descending)
    correct_order_groups = correct_order_groups.reverse.map {|g| g.reverse}

    correct_order_groups.each_with_index do |correct_order, group_index|

      # Test ALL (!) perumtations of the group
      correct_order.permutation do |mixed_up_array|
        mixed_up_array.sort.should eq(correct_order)
      end

      # First of this group is greater than the last of last group
      if group_index > 0
        previous_group = correct_order_groups[group_index - 1]
        correct_order[0].should be > previous_group[-1]
      end

    end
  end

  it "should increment the patch by default" do
    SemVerRange.new(1).increment.should eq(SemVerRange.new(1,0,1))
    SemVerRange.new(1, 2).increment.should eq(SemVerRange.new(1,2,1))
    SemVerRange.new(1, 2, 42).increment.should eq(SemVerRange.new(1,2,43))
  end

  it "should increment the part before the wildcard if there is one" do
    SemVerRange.new(1, 2, x).increment.should eq(SemVerRange.new(1, 3, x))
    SemVerRange.new(1, '*', '*').increment.should eq(SemVerRange.new(2, '*', '*'))
  end

  it "should match other semvers" do

    match_data = [{
      range: SemVerRange.new(1, 1, 0, '>'),
      matches: [
        SemVer.new(100, 100, 100),
        SemVer.new(1, 2, 0),
        SemVer.new(1, 1, 1),
      ],

      doesnt_match: [
        SemVer.new(1, 1, 0),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(1, 1, 0, '>='),
      matches: [
        SemVer.new(100, 100, 100),
        SemVer.new(1, 2, 0),
        SemVer.new(1, 1, 1),
        SemVer.new(1, 1, 0),
      ],

      doesnt_match: [
        SemVer.new(1, 0, 100),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 0, 1),
      ]

    }, {
      range: SemVerRange.new(1, 0, 1, '>'),
      matches: [
        SemVer.new(100, 100, 100),
        SemVer.new(1, 1, 0),
        SemVer.new(1, 0, 2),
      ],
      doesnt_match: [
        SemVer.new(1, 0, 1),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(1, 0, 0, '>'),
      matches: [
        SemVer.new(100, 100, 100),
        SemVer.new(1, 1, 0),
        SemVer.new(1, 0, 1),
      ],
      doesnt_match: [
        SemVer.new(1, 0, 0),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(1, 1, x, '~>'),
      matches: [
        SemVer.new(1, 100, 0),
        SemVer.new(1, 2, 0),
        SemVer.new(1, 1, 0),
      ],
      doesnt_match: [
        SemVer.new(100, 0, 0),
        SemVer.new(2, 0, 0),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(1, x, x),
      matches: [
        SemVer.new(1, 100, 100),
        SemVer.new(1, 1, 1),
        SemVer.new(1, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(2, 0, 0),
        SemVer.new(0, 1, 0),
        SemVer.new(0, 1, 1),
      ]
    }, {
      range: SemVerRange.new(1, 1, 0, '~>'),
      matches: [
        SemVer.new(1, 1, 100),
        SemVer.new(1, 1, 1),
        SemVer.new(1, 1, 0),
      ],
      doesnt_match: [
        SemVer.new(100, 0, 0),
        SemVer.new(1, 2, 0),
        SemVer.new(1, 0, 100),
        SemVer.new(1, 0, 0),
      ]
    }, {
      range: SemVerRange.new(1, 1, 0),
      matches: [
        SemVer.new(1, 1, 0),
      ],
      doesnt_match: [
        SemVer.new(2, 1, 0),
        SemVer.new(1, 2, 0),
        SemVer.new(1, 1, 1),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 1, 0),
      ]
    }, {
      range: SemVerRange.new(1, 1, 0, '<='),
      matches: [
        SemVer.new(1, 1, 0),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(1, 1, 1),
        SemVer.new(2, 0, 0),
      ]
    }, {
      range: SemVerRange.new(1, 0, x),
      matches: [
        SemVer.new(1, 0, 100),
        SemVer.new(1, 0, 1),
        SemVer.new(1, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(1, 1, 0),
        SemVer.new(0, 100, 100),
      ]
    }, {
      range: SemVerRange.new(1, 1, 0, '<'),
      matches: [
        SemVer.new(1, 0, 100),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(1, 1, 0),
        SemVer.new(2, 0, 0),
      ]
    }, {
      range: SemVerRange.new(0, 1, x, '~>'),
      matches: [
        SemVer.new(0, 100, 100),
        SemVer.new(0, 100, 0),
        SemVer.new(0, 1, 100),
        SemVer.new(0, 1, 0),
      ],
      doesnt_match: [
        SemVer.new(100, 0, 0),
        SemVer.new(1, 0, 0),
        SemVer.new(0, 0, 100),
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(0, 1, 2, '~>'),
      matches: [
        SemVer.new(0, 1, 100),
        SemVer.new(0, 1, 2),
      ],
      doesnt_match: [
        SemVer.new(0, 2, 0),
        SemVer.new(0, 1, 1),
      ]
    }, {
      range: SemVerRange.new(0, 1, 1, '~>'),
      matches: [
        SemVer.new(0, 1, 100),
        SemVer.new(0, 1, 1),
      ],
      doesnt_match: [
        SemVer.new(0, 2, 0),
        SemVer.new(0, 1, 0),
      ]

    }, {
      range: SemVerRange.new(0, 0, 0, '~>'),
      matches: [
        SemVer.new(0, 0, 100),
        SemVer.new(0, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(0, 1, 0),
      ]
    }, {
      range: SemVerRange.new(0, 0, 0, '<='),
      matches: [
        SemVer.new(0, 0, 0),
      ],
      doesnt_match: [
        SemVer.new(0, 0, 1),
      ]
    }, {
      range: SemVerRange.new(0, 0, 0, '<'),
      matches: [],
      doesnt_match: [
        SemVer.new(0, 0, 0),
      ]
    }]

    match_data.each do |data|
      data[:matches].each do |to_match|
        # puts "#{data[:range].inspect}.matches? #{to_match.inspect}"
        data[:range].matches?(to_match).should be_true
      end

      data[:doesnt_match].each do |to_not_match|
        # puts "#{data[:range].inspect} doesn't match #{to_not_match.inspect}"
        data[:range].matches?(to_not_match).should be_false
      end
    end
  end

  it "should match other strings" do
    SemVerRange.new(1, 2, x).matches?("v1.2.3").should be_true
  end

  it "should not match other ranges" do
    expect { SemVerRange.new(1, 2, x).matches? SemVerRange.new(1,2,x) }.to raise_error
  end

  it "should parse wildcard ranges" do
    range_strings = [
      "1.0.x",
      "1.x.x",
      "1.0.*",
      "1.*.*",
    ]

    expected_ranges = [
      SemVerRange.new(1, 0, x),
      SemVerRange.new(1, x, x),
      SemVerRange.new(1, 0, '*'),
      SemVerRange.new(1, '*', '*'),
    ]

    range_strings.zip(expected_ranges).each do |str, expected|
      SemVerRange.parse(str, TAG_FORMAT_WITHOUT_V).should eq(expected)
    end
  end

  it "should parse ranges with comparison operators" do
    range_strings = [
      "> 1.0.0",
      ">= 1.0.0",
      "< 1.0.0",
      "<= 1.0.0",
      "~> 1.0.0",
      "~1.0.0",
      "=1.0.0",
    ]

    expected_ranges = [
      SemVerRange.new(1, 0, 0, ">"),
      SemVerRange.new(1, 0, 0, ">="),
      SemVerRange.new(1, 0, 0, "<"),
      SemVerRange.new(1, 0, 0, "<="),
      SemVerRange.new(1, 0, 0, "~>"),
      SemVerRange.new(1, 0, 0, "~"),
      SemVerRange.new(1, 0, 0, "="),
    ]

    range_strings.zip(expected_ranges).each do |str, expected|
      SemVerRange.parse(str, TAG_FORMAT_WITHOUT_V).should eq(expected)
    end
  end

  it "should parse strings without comparison operators as regular semvers" do
    SemVerRange.parse("1.0.0", TAG_FORMAT_WITHOUT_V).should eq(SemVer.new(1, 0, 0))
  end

  # it "should parse missing parts as zeros" do
  #   range_strings = [
  #     "=1",
  #     "< 1.0",
  #   ]
  #
  #   expected_ranges = [
  #     SemVerRange.new(1, 0, 0),
  #     SemVerRange.new(1, 0, 0, "<"),
  #   ]
  #
  #   range_strings.zip(expected_ranges).each do |str, expected|
  #     SemVerRange.parse(str, TAG_FORMAT_WITHOUT_V).should eq(expected)
  #   end
  # end

  # it "should parse missing parts as wildcards when approximate" do
  #   range_strings = [
  #     "~> 1",
  #     "~1.0",
  #   ]
  #
  #   expected_ranges = [
  #     SemVerRange.new(1, 0, 0, "~>"),
  #     SemVerRange.new(1, 0, 0, "~"),
  #   ]
  #
  #   range_strings.zip(expected_ranges).each do |str, expected|
  #     SemVerRange.parse(str, TAG_FORMAT_WITHOUT_V).should eq(expected)
  #   end
  # end

  it "shouldn't parse ranges with prerelase or metadata strings" do
    range_strings = [
      "=1.0.0-alpha",
      "< 1.0.0+metadata",
      "1.0.x-alpha+metadata",
    ]

    range_strings.each do |str|
      # print "\n", "str:  #{str.inspect}", "\n\n"
      expect { SemVerRange.parse(str, TAG_FORMAT_WITHOUT_V) }.to raise_error XSemVer::InvalidSemVerRangeError
    end
  end
end
