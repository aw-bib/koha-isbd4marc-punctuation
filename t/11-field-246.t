#!/usr/bin/perl
#
# Tests for _decorate_field with 246 rules (also applies to 247 via use_rules).
#
# ISBD punctuation for 246:
#   $i: $a : $b / $c . $n , $p , $f = $r
#   $g wrapped in (...)
#   $h wrapped in [...]

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field combined_string check_combined);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{246};
ok( defined $rules, '246 rules loaded' );

# --- Test 1: $a alone ---
{
    # render: 246 1# $a Alternate title
    my $field = make_field( '246', '1', ' ', a => 'Alternate title' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Alternate title', '246: $a alone is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Alternate title', '246 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

# --- Test 2: $i followed by $a ---
# Note: $i gets ": " appended via cb_pre (not via pchrs), so it's the same in both modes.
{
    # render: 246 1# $i Cover title $a Alternate title
    my $field = make_field(
        '246', '1', ' ',
        i => 'Cover title',
        a => 'Alternate title',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Cover title: ',   '246: $i gets ": " appended' );
    is( $result[3], 'Alternate title', '246: $a is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is(
        $result_pr[1],
        'Cover title: ',
        '246 prefix: $i still gets ": " via cb_pre'
    );
    is(
        $result_pr[3],
        'Alternate title',
        '246 prefix: $a unchanged (no pchrs for a)'
    );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

# --- Test 3: $a followed by $b ---
{
    # render: 246 1# $a Alternate title $b a subtitle
    my $field = make_field(
        '246', '1', ' ',
        a => 'Alternate title',
        b => 'a subtitle',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Alternate title : ',
        '246: $a gets " : " when $b follows' );
    is( $result[3], 'a subtitle', '246: $b unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Alternate title', '246 prefix: $a unchanged' );
    is( $result_pr[3], ' : a subtitle', '246 prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

# --- Test 4: $a followed by $f ---
{
    # render: 246 1# $a Alternate title $f 2005
    my $field = make_field(
        '246', '1', ' ',
        a => 'Alternate title',
        f => '2005',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Alternate title, ', '246: $a gets ", " when $f follows' );
    is( $result[3], '2005',              '246: $f unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Alternate title', '246 prefix: $a unchanged' );
    is( $result_pr[3], ', 2005', '246 prefix: $f gets ", " prepended' );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

# --- Test 5: $g wrapped in parentheses ---
{
    # render: 246 1# $a Alternate title $g some info
    my $field = make_field(
        '246', '1', ' ',
        a => 'Alternate title',
        g => 'some info',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Alternate title', '246: $a unchanged' );
    is( $result[3], '(some info)',     '246: $g wrapped in parentheses' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Alternate title', '246 prefix: $a unchanged' );
    is( $result_pr[3], '(some info)', '246 prefix: $g wrapped in parentheses' );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

# --- Test 6: $h wrapped in brackets ---
{
    # render: 246 1# $a Alternate title $h electronic
    my $field = make_field(
        '246', '1', ' ',
        a => 'Alternate title',
        h => 'electronic',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Alternate title', '246: $a unchanged' );
    is( $result[3], '[electronic]',    '246: $h wrapped in brackets' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Alternate title', '246 prefix: $a unchanged' );
    is( $result_pr[3], '[electronic]', '246 prefix: $h wrapped in brackets' );

    check_combined( \@result, \@result_pr, '246: combined string identical' );
}

done_testing();
