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
my @expected_tags = qw(020 100 110 111 130 210 222 240 242 243 245 246 247 250 260 264 300 490 500 501 502 504 505 506 507 508 510 511 513 515 520 525 526 530 532 533 534 535 538 540 541 544 546 547 550 555 562 565 580 584 600 610 611 630 648 650 651 655 656 657 658 700 710 711 730 800 810 811 830);
my @got_tags = sort keys %$rules;
is_deeply( \@got_tags, \@expected_tags, "$SET has exactly the expected field tags" );

# 3. Each rule has valid keys
my @valid_keys = qw(name pchrs post wrap cb_pre cb_post use_rules);
for my $tag (@expected_tags) {
    my $entry = $rules->{$tag};
    ok( defined $entry, "Rules entry for $tag is defined" );

    for my $key ( keys %$entry ) {
        ok( grep( /^$key$/, @valid_keys ), "Key '$key' in $tag is a valid rule key" );
    }
}

# 3b. Every rule has a non-empty human-readable name (metadata, not a
#     punctuation rule). The engine ignores it; it documents what the
#     tag stands for in plain words.
for my $tag (@expected_tags) {
    my $name = $rules->{$tag}{name};
    ok( defined $name && $name ne '', "$tag has a non-empty 'name'" );
}

# 4. 247 has its own rules (no longer aliases to 246)
ok( !exists $rules->{247}->{use_rules}, '247 has its own rules (no use_rules alias)' );
# 5. 247 should NOT have cb_pre (it has no $i subfield)
ok( !exists $rules->{247}->{cb_pre}, '247 has no cb_pre (no $i handling)' );

done_testing();
