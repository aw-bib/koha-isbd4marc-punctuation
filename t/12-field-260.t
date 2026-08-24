#!/usr/bin/perl
#
# Tests for _decorate_field with 260 rules.
#
# ISBD punctuation for 260 (Imprint):
#   $a ; $a : $b , $c ( $e : $f , $g ) (q)

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{260};
ok( defined $rules, '260 rules loaded' );

# --- Test 1: $a alone ---
{
    my $field = make_field( '260', ' ', ' ', a => 'New York' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York', '260: $a alone is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a alone unchanged' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '260: combined string identical'
    );
}

# --- Test 2: $a followed by $b followed by $c ---
{
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        b => 'Penguin',
        c => '2005',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York : ', '260: $a gets " : " when $b follows' );
    is( $result[3], 'Penguin, ',   '260: $b gets ", " when $c follows' );
    is( $result[5], '2005',        '260: $c unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York',   '260 prefix: $a unchanged' );
    is( $result_pr[3], ' : Penguin', '260 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ', 2005',     '260 prefix: $c gets ", " prepended' );

    is(
        join( '', @result[ 1, 3, 5 ] ),
        join( '', @result_pr[ 1, 3, 5 ] ),
        '260: combined string identical'
    );
}

# --- Test 3: Multiple $a (e.g. New York ; London) ---
# Note: " ; " is PREPENDED to second $a via cb_pre (not via pchrs), so same in both modes.
{
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        a => 'London',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York', '260: first $a unchanged' );
    is( $result[3], ' ; London',
        '260: second $a gets " ; " prefix via cb_pre' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: first $a unchanged' );
    is( $result_pr[3], ' ; London',
        '260 prefix: second $a still gets " ; " via cb_pre' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '260: combined string identical'
    );
}

# --- Test 4: $q wrapped in parentheses ---
# $q is handled via wrap (not pchrs), so same in both modes.
{
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        q => 'some qualifier',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York',         '260: $a unchanged' );
    is( $result[3], '(some qualifier)', '260: $q wrapped in parentheses' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a unchanged' );
    is(
        $result_pr[3],
        '(some qualifier)',
        '260 prefix: $q wrapped in parentheses'
    );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '260: combined string identical'
    );
}

# --- Test 5: $e/$f/$g grouping ---
# $e opens a paren: " ($value "
# $f continues: " : $value"
# $g closes: ", $value)"
# This is entirely handled by cb_pre, so same in both modes.
{
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        e => 'a manufacturer',
        f => 'a place',
        g => '2005',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York', '260: $a unchanged' );
    is(
        $result[3],
        ' (a manufacturer ',
        '260: $e opens paren with trailing space'
    );
    is( $result[5], ' : a place',
        '260: $f gets " : " prefix when $e precedes' );
    is( $result[7], ', 2005)', '260: $g closes paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' (a manufacturer ',
        '260 prefix: $e opens paren with trailing space'
    );
    is( $result_pr[5], ' : a place',
        '260 prefix: $f gets " : " prefix when $e precedes' );
    is( $result_pr[7], ', 2005)', '260 prefix: $g closes paren' );

    is(
        join( '', @result[ 1, 3, 5, 7 ] ),
        join( '', @result_pr[ 1, 3, 5, 7 ] ),
        '260: combined string identical'
    );
}

# --- Test 6: $3 always gets ": " appended ---
# $3 uses "post" (always-appended suffix), not pchrs, so same in both modes.
{
    my $field = make_field(
        '260', ' ', ' ',
        '3' => '1990',
        a   => 'New York',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], '1990: ',   '260: $3 gets ": " appended via post' );
    is( $result[3], 'New York', '260: $a unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], '1990: ',   '260 prefix: $3 still gets ": " via post' );
    is( $result_pr[3], 'New York', '260 prefix: $a unchanged' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '260: combined string identical'
    );
}

done_testing();
