#!/usr/bin/perl
#
# Regression tests for Fields 246/247 derived from isbdmarc2016.pdf Current/Future examples.
# Only includes test cases that should PASS with current code.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# --- Field 246 ---

my $rules_246 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{246};
ok( defined $rules_246, '246 rules loaded' );

# --- Example 8: $i + $a ---
# Doc: Future: 246 1# $i Panel title $a Welcome to big Wyoming
# Doc: Current: 246 1# $i Panel title: $a Welcome to big Wyoming
{
    # render: 246 1# $i Panel title $a Welcome to big Wyoming
    my $field = make_field( '246', '1', ' ',
        i => 'Panel title',
        a => 'Welcome to big Wyoming',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_246, 'postfix' );
    is( $result[1], 'Panel title: ',             '246 example 8: $i gets ": " appended' );
    is( $result[3], 'Welcome to big Wyoming',    '246 example 8: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_246, 'prefix' );
    is( $result_pr[1], 'Panel title: ',          '246 example 8 prefix: $i still gets ": " via cb_pre' );
    is( $result_pr[3], 'Welcome to big Wyoming', '246 example 8 prefix: $a unchanged' );

    is( join('', @result[1,3]), join('', @result_pr[1,3]), '246 example 8: combined string identical' );
}

# --- Field 247 ---

my $rules_247 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{247};
ok( defined $rules_247, '247 rules loaded' );

# --- Example 9: $a + $g + $f ---
# Doc: Future: 247 10 $a Progress report... $g varies slightly $f 1st-10th
# Doc: Current: 247 10 $a Progress report... $g (varies slightly) $f 1st-10th
{
    # render: 247 10 $a Progress report under the joint program to improve accounting in the Federal Government $g varies slightly $f 1st-10th
    my $field = make_field( '247', '1', '0',
        a => 'Progress report under the joint program to improve accounting in the Federal Government',
        g => 'varies slightly',
        f => '1st-10th',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_247, 'postfix' );
    is(
        $result[1],
        'Progress report under the joint program to improve accounting in the Federal Government',
        '247 example 9: $a unchanged'
    );
    is( $result[3], '(varies slightly), ',  '247 example 9: $g wrapped in (), gets ", " for $f' );
    is( $result[5], '1st-10th',             '247 example 9: $f unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_247, 'prefix' );
    is(
        $result_pr[1],
        'Progress report under the joint program to improve accounting in the Federal Government',
        '247 example 9 prefix: $a unchanged'
    );
    is( $result_pr[3], '(varies slightly)',  '247 example 9 prefix: $g wrapped in () only' );
    is( $result_pr[5], ', 1st-10th',         '247 example 9 prefix: $f gets ", " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '247 example 9: combined string identical' );
}

done_testing();
