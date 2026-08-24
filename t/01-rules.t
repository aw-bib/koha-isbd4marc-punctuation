#!/usr/bin/perl
#
# Test that the RULES constant has the expected structure
# and that each entry has valid keys.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# Access the RULES constant via the package sub
my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES;

# 1. Rules is defined
ok( defined $rules, 'RULES constant is defined' );

# 2. Expected tags are present
my @expected_tags = qw(245 246 247 260 264 490);
my @got_tags = sort keys %$rules;
is_deeply( \@got_tags, \@expected_tags, 'RULES has exactly the expected field tags' );

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
