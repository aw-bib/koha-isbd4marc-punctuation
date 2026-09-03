#!/usr/bin/perl
#
# Test that the LoC/PCC rule set has the expected structure
# and that each entry has valid keys.
# This file is specific to the LoC/PCC rule set (see $SET below).

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

# Load the rules for the set under test, by name.
my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);

# 1. Rules are defined
ok( defined $rules, "rules_for('$SET') is defined" );

# 2. Expected tags are present
my @expected_tags = qw(020 100 110 111 130 210 222 240 242 243 245 246 247 250 260 264 300 490 502 505 520 600 610 611 630 648 650 651 655 656 657 658 700 710 711 730 800 810 811 830);
my @got_tags = sort keys %$rules;
is_deeply( \@got_tags, \@expected_tags, "$SET has exactly the expected field tags" );

# 3. Each rule has valid keys
my @valid_keys = qw(pchrs post wrap cb_pre cb_post use_rules);
for my $tag (@expected_tags) {
    my $entry = $rules->{$tag};
ok( defined $entry, "Rules entry for $tag is defined" );

    for my $key ( keys %$entry ) {
        ok( grep( /^$key$/, @valid_keys ), "Key '$key' in $tag is a valid rule key" );
    }
}

# 4. 247 has its own rules (no longer aliases to 246)
ok( !exists $rules->{247}->{use_rules}, '247 has its own rules (no use_rules alias)' );
# 5. 247 should NOT have cb_pre (it has no $i subfield)
ok( !exists $rules->{247}->{cb_pre}, '247 has no cb_pre (no $i handling)' );

done_testing();
