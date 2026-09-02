#!/usr/bin/perl
#
# Tests for _decorate_field with 245 rules.
#
# ISBD punctuation for 245:
#   $a : $b / $c ; $d . $e , $f , $g [$h] . $n , $p : $k . $s
#
# NOTE: All punctuation strings include a trailing space per ISBD spec.
# E.g. " : " not " :", so test strings must match exactly.

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

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{245};
ok( defined $rules, '245 rules loaded' );

# --- Test 1: $a alone (no punctuation needed) ---
{
    # render: 245 00 $a The great book
    my $field = make_field( '245', '0', '0', a => 'The great book' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( scalar @result, 2, '245: $a alone returns 2 elements (sf + value)' );
    is( $result[1],     'The great book', '245: $a alone is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'The great book', '245 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '245: combined string identical' );
}

# --- Test 2: $a followed by $b ---
{
    # render: 245 00 $a The great book $b a subtitle
    my $field = make_field(
        '245', '0', '0',
        a => 'The great book',
        b => 'a subtitle',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'The great book : ', '245: $a gets " : " when $b follows' );
    is( $result[3], 'a subtitle',        '245: $b is unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'The great book', '245 prefix: $a unchanged' );
    is( $result_pr[3], ' : a subtitle', '245 prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '245: combined string identical' );
}

# --- Test 3: $a followed by $b followed by $c ---
{
    # render: 245 00 $a The great book $b a subtitle $c by an author
    my $field = make_field(
        '245', '0', '0',
        a => 'The great book',
        b => 'a subtitle',
        c => 'by an author',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'The great book : ', '245: $a gets " : " for $b' );
    is( $result[3], 'a subtitle / ',     '245: $b gets " / " for $c' );
    is( $result[5], 'by an author', '245: last subfield ($c) is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'The great book', '245 prefix: $a unchanged' );
    is( $result_pr[3], ' : a subtitle', '245 prefix: $b gets " : " prepended' );
    is(
        $result_pr[5],
        ' / by an author',
        '245 prefix: $c gets " / " prepended'
    );

    check_combined( \@result, \@result_pr, '245: combined string identical' );
}

# --- Test 4: $n followed by $p ---
# $n (number of part) is followed by $p (name of part).
# Since input has no punctuation (per leader/18), values are clean.
{
    # render: 245 00 $n Part one $p Chapter two
    my $field = make_field(
        '245', '0', '0',
        n => 'Part one',
        p => 'Chapter two',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Part one, ',
        '245: $n gets ", " when $p follows (per current rules)' );
    is( $result[3], 'Chapter two', '245: $p (last) is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Part one',      '245 prefix: $n unchanged' );
    is( $result_pr[3], ', Chapter two', '245 prefix: $p gets ", " prepended' );

    check_combined( \@result, \@result_pr, '245: combined string identical' );
}

# --- Test 5: $h gets wrapped in brackets ---
{
    # render: 245 00 $a The great book $h electronic resource $c by an author
    my $field = make_field(
        '245', '0', '0',
        a => 'The great book',
        h => 'electronic resource',
        c => 'by an author',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'The great book', '245: $a unchanged' );
    is(
        $result[3],
        '[electronic resource] / ',
        '245: $h wrapped in brackets, then " / " for $c'
    );
    is( $result[5], 'by an author', '245: $c unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'The great book', '245 prefix: $a unchanged' );
    is(
        $result_pr[3],
        '[electronic resource]',
        '245 prefix: $h wrapped in brackets only (no punct)'
    );
    is(
        $result_pr[5],
        ' / by an author',
        '245 prefix: $c gets " / " prepended'
    );

    check_combined( \@result, \@result_pr, '245: combined string identical' );
}

done_testing();
