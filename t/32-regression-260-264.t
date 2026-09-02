#!/usr/bin/perl
#
# Regression tests for Fields 260/264 derived from isbdmarc2016.pdf Current/Future examples.
# Only includes test cases that should PASS with current code.
# Excludes $g alone (example 15) and $e/$f/$g group (example 14) — needs review.
#
# NOTE on pchrs behavior:
# - $a/$a separator " ; " via COMPOUND key aa (postfix: appended to first $a;
#   prefix: prepended to second $a). $b/$a via compound ba.
# - $b/$b separator " : " is appended via pchrs (b => ' : ')
# - All pchrs values are comma-space ', ' NOT space-comma-space ' , '

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

# --- Field 260 ---

my $rules_260 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{260};
ok( defined $rules_260, '260 rules loaded' );

# --- Example 10: Multiple $b with $c ---
# Doc: Future: 260 ## $a Washington, D.C. $b U.S. Dept... $b For sale by... $c 1981
# Doc: Current: 260 ## $a Washington, D.C. : $b U.S. Dept... : $b For sale by... , $c 1981
{
    # render: 260 ## $a Washington, D.C. $b U.S. Dept. of Agriculture, Forest Service $b For sale by the Supt. of Docs. U.S. G.P.O. $c 1981
    my $field = make_field( '260', ' ', ' ',
        a => 'Washington, D.C.',
        b => 'U.S. Dept. of Agriculture, Forest Service',
        b => 'For sale by the Supt. of Docs. U.S. G.P.O.',
        c => '1981',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'postfix' );
    is( $result[1], 'Washington, D.C. : ',                          '260 ex10: $a gets " : " for first $b' );
    is( $result[3], 'U.S. Dept. of Agriculture, Forest Service : ', '260 ex10: first $b gets " : " for second $b' );
    is( $result[5], 'For sale by the Supt. of Docs. U.S. G.P.O., ', '260 ex10: second $b gets ", " for $c' );
    is( $result[7], '1981',                                          '260 ex10: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'prefix' );
    is( $result_pr[1], 'Washington, D.C.',                            '260 ex10 prefix: $a unchanged' );
    is( $result_pr[3], ' : U.S. Dept. of Agriculture, Forest Service', '260 ex10 prefix: first $b gets " : " prepended' );
    is( $result_pr[5], ' : For sale by the Supt. of Docs. U.S. G.P.O.', '260 ex10 prefix: second $b gets " : " prepended' );
    is( $result_pr[7], ', 1981',                                        '260 ex10 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '260 ex10: combined string identical' );
}

# --- Example 11: Multiple $a with $b and $c ---
# Doc: Future: 260 ## $a New York $a Berlin $b Springer Verlag $c 1977
# Doc: Current: 260 ## $a New York ; $a Berlin : $b Springer Verlag , $c 1977
# Note: " ; " is appended to the FIRST $a via the COMPOUND pchrs key aa
# (postfix), and moves to the second $a only in prefix mode.
{
    # render: 260 ## $a New York $a Berlin $b Springer Verlag $c 1977
    my $field = make_field( '260', ' ', ' ',
        a => 'New York',
        a => 'Berlin',
        b => 'Springer Verlag',
        c => '1977',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'postfix' );
    is( $result[1], 'New York ; ',       '260 ex11: first $a gets " ; " (compound aa)' );
    is( $result[3], 'Berlin : ',   '260 ex11: second $a gets " : " for $b' );
    is( $result[5], 'Springer Verlag, ', '260 ex11: $b gets ", " for $c' );
    is( $result[7], '1977',           '260 ex11: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'prefix' );
    is( $result_pr[1], 'New York',         '260 ex11 prefix: first $a unchanged' );
    is( $result_pr[3], ' ; Berlin',        '260 ex11 prefix: second $a gets " ; " prepended (pending aa)' );
    is( $result_pr[5], ' : Springer Verlag', '260 ex11 prefix: $b gets " : " prepended' );
    is( $result_pr[7], ', 1977',            '260 ex11 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '260 ex11: combined string identical' );
}

# --- Example 12: Interleaved $a/$b ---
# Doc: Future: 260 ## $a Paris $b Gauthier-Villars $a Chicago $b University of Chicago Press $c 1955
# Doc: Current: 260 ## $a Paris : $b Gauthier-Villars ; $a Chicago : $b University of Chicago Press , $c 1955
# Note: " ; " is appended to $b when followed by $a (compound ba) in postfix,
# and moves to the second $a (prepended) in prefix mode.
{
    # render: 260 ## $a Paris $b Gauthier-Villars $a Chicago $b University of Chicago Press $c 1955
    my $field = make_field( '260', ' ', ' ',
        a => 'Paris',
        b => 'Gauthier-Villars',
        a => 'Chicago',
        b => 'University of Chicago Press',
        c => '1955',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'postfix' );
    is( $result[1], 'Paris : ',                       '260 ex12: first $a gets " : " for first $b' );
    is( $result[3], 'Gauthier-Villars ; ',               '260 ex12: $b gets " ; " when followed by $a (compound ba)' );
    is( $result[5], 'Chicago : ',                  '260 ex12: second $a gets " : " for second $b' );
    is( $result[7], 'University of Chicago Press, ',  '260 ex12: second $b gets ", " for $c' );
    is( $result[9], '1955',                           '260 ex12: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'prefix' );
    is( $result_pr[1], 'Paris',                         '260 ex12 prefix: first $a unchanged' );
    is( $result_pr[3], ' : Gauthier-Villars',           '260 ex12 prefix: first $b gets " : " prepended' );
    is( $result_pr[5], ' ; Chicago',                    '260 ex12 prefix: second $a gets " ; " via pending (ba)' );
    is( $result_pr[7], ' : University of Chicago Press', '260 ex12 prefix: second $b gets " : " prepended' );
    is( $result_pr[9], ', 1955',                         '260 ex12 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '260 ex12: combined string identical' );
}

# --- Example 13: $q for address (between $a and $b) ---
# Doc: Future: 260 ## $a Washington, D.C. $q 1649 K St.... $b Wider Opportunities... $c 1979
# Doc: Current: 260 ## $a Washington, D.C. ($q 1649 K St....) : $b Wider Opportunities... , $c 1979
{
    # render: 260 ## $a Washington, D.C. $q 1649 K St., N.W., Washington 20006 $b Wider Opportunities for Women $c 1979
    my $field = make_field( '260', ' ', ' ',
        a => 'Washington, D.C.',
        q => '1649 K St., N.W., Washington 20006',
        b => 'Wider Opportunities for Women',
        c => '1979',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'postfix' );
    is( $result[1], 'Washington, D.C.',                               '260 ex13: $a unchanged (no pchrs for $q)' );
    is( $result[3], '(1649 K St., N.W., Washington 20006) : ',        '260 ex13: $q wrapped in (), gets " : " for $b' );
    is( $result[5], 'Wider Opportunities for Women, ',                '260 ex13: $b gets ", " for $c' );
    is( $result[7], '1979',                                           '260 ex13: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'prefix' );
    is( $result_pr[1], 'Washington, D.C.',                               '260 ex13 prefix: $a unchanged' );
    is( $result_pr[3], '(1649 K St., N.W., Washington 20006)',           '260 ex13 prefix: $q wrapped in () only' );
    is( $result_pr[5], ' : Wider Opportunities for Women',               '260 ex13 prefix: $b gets " : " prepended' );
    is( $result_pr[7], ', 1979',                                          '260 ex13 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '260 ex13: combined string identical' );
}

# --- Example 16: $3 (materials specified) ---
# Doc: Future: 260 3# $3 June 1993- $a London $b Elle
# Doc: Current: 260 3# $3 June 1993-: $a London : $b Elle
{
    # render: 260 3# $3 June 1993- $a London $b Elle
    my $field = make_field( '260', '3', '#',
        '3' => 'June 1993-',
        a   => 'London',
        b   => 'Elle',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'postfix' );
    is( $result[1], 'June 1993-: ',   '260 ex16: $3 gets ": " appended via post' );
    is( $result[3], 'London : ',      '260 ex16: $a gets " : " for $b' );
    is( $result[5], 'Elle',           '260 ex16: $b (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_260, 'prefix' );
    is( $result_pr[1], 'June 1993-: ',  '260 ex16 prefix: $3 gets ": " via post' );
    is( $result_pr[3], 'London',        '260 ex16 prefix: $a unchanged' );
    is( $result_pr[5], ' : Elle',       '260 ex16 prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '260 ex16: combined string identical' );
}

# --- Field 264 ---

my $rules_264 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{264};
ok( defined $rules_264, '264 rules loaded' );

# --- Example 17: Basic $a/$b/$c ---
{
    # render: 264 #1 $a Washington, D.C. $b U.S. Dept. of Agriculture, Forest Service $c 1981
    my $field = make_field( '264', '#', '1',
        a => 'Washington, D.C.',
        b => 'U.S. Dept. of Agriculture, Forest Service',
        c => '1981',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'postfix' );
    is( $result[1], 'Washington, D.C. : ',                          '264 ex17: $a gets " : " for $b' );
    is( $result[3], 'U.S. Dept. of Agriculture, Forest Service, ',  '264 ex17: $b gets ", " for $c' );
    is( $result[5], '1981',                                         '264 ex17: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'prefix' );
    is( $result_pr[1], 'Washington, D.C.',                            '264 ex17 prefix: $a unchanged' );
    is( $result_pr[3], ' : U.S. Dept. of Agriculture, Forest Service', '264 ex17 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ', 1981',                                       '264 ex17 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '264 ex17: combined string identical' );
}

# --- Example 18: Multiple $a ---
# " ; " is appended to the FIRST $a via the COMPOUND key aa (postfix),
# moving to the second $a only in prefix mode.
{
    # render: 264 #1 $a New York $a Berlin $b Springer Verlag $c 1977
    my $field = make_field( '264', '#', '1',
        a => 'New York',
        a => 'Berlin',
        b => 'Springer Verlag',
        c => '1977',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'postfix' );
    is( $result[1], 'New York ; ',       '264 ex18: first $a gets " ; " (compound aa)' );
    is( $result[3], 'Berlin : ',       '264 ex18: second $a gets " : " for $b' );
    is( $result[5], 'Springer Verlag, ',  '264 ex18: $b gets ", " for $c' );
    is( $result[7], '1977',              '264 ex18: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'prefix' );
    is( $result_pr[1], 'New York',         '264 ex18 prefix: first $a unchanged' );
    is( $result_pr[3], ' ; Berlin',        '264 ex18 prefix: second $a gets " ; " prepended (pending aa)' );
    is( $result_pr[5], ' : Springer Verlag', '264 ex18 prefix: $b gets " : " prepended' );
    is( $result_pr[7], ', 1977',            '264 ex18 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '264 ex18: combined string identical' );
}

# --- Example 19: Interleaved $a/$b ---
{
    # render: 264 #1 $a Paris $b Gauthier-Villars $a Chicago $b University of Chicago Press $c 1955
    my $field = make_field( '264', '#', '1',
        a => 'Paris',
        b => 'Gauthier-Villars',
        a => 'Chicago',
        b => 'University of Chicago Press',
        c => '1955',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'postfix' );
    is( $result[1], 'Paris : ',                       '264 ex19: first $a gets " : " for first $b' );
    is( $result[3], 'Gauthier-Villars ; ',               '264 ex19: $b gets " ; " when followed by $a (compound ba)' );
    is( $result[5], 'Chicago : ',                  '264 ex19: second $a gets " : " for second $b' );
    is( $result[7], 'University of Chicago Press, ',  '264 ex19: second $b gets ", " for $c' );
    is( $result[9], '1955',                           '264 ex19: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'prefix' );
    is( $result_pr[1], 'Paris',                         '264 ex19 prefix: first $a unchanged' );
    is( $result_pr[3], ' : Gauthier-Villars',           '264 ex19 prefix: first $b gets " : " prepended' );
    is( $result_pr[5], ' ; Chicago',                    '264 ex19 prefix: second $a gets " ; " via pending (ba)' );
    is( $result_pr[7], ' : University of Chicago Press', '264 ex19 prefix: second $b gets " : " prepended' );
    is( $result_pr[9], ', 1955',                         '264 ex19 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '264 ex19: combined string identical' );
}

# --- Example 20: $q for address ---
{
    # render: 264 #1 $a Washington, D.C. $q 1649 K St., N.W., Washington 20006 $b Wider Opportunities for Women $c 1979
    my $field = make_field( '264', '#', '1',
        a => 'Washington, D.C.',
        q => '1649 K St., N.W., Washington 20006',
        b => 'Wider Opportunities for Women',
        c => '1979',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'postfix' );
    is( $result[1], 'Washington, D.C.',                               '264 ex20: $a unchanged' );
    is( $result[3], '(1649 K St., N.W., Washington 20006) : ',        '264 ex20: $q wrapped in (), gets " : " for $b' );
    is( $result[5], 'Wider Opportunities for Women, ',                '264 ex20: $b gets ", " for $c' );
    is( $result[7], '1979',                                           '264 ex20: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'prefix' );
    is( $result_pr[1], 'Washington, D.C.',                               '264 ex20 prefix: $a unchanged' );
    is( $result_pr[3], '(1649 K St., N.W., Washington 20006)',           '264 ex20 prefix: $q wrapped in () only' );
    is( $result_pr[5], ' : Wider Opportunities for Women',               '264 ex20 prefix: $b gets " : " prepended' );
    is( $result_pr[7], ', 1979',                                          '264 ex20 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '264 ex20: combined string identical' );
}

# --- Example 21: $3 (materials specified) ---
{
    # render: 264 31 $3 June 1993- $a London $b Elle
    my $field = make_field( '264', '3', '1',
        '3' => 'June 1993-',
        a   => 'London',
        b   => 'Elle',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'postfix' );
    is( $result[1], 'June 1993-: ',   '264 ex21: $3 gets ": " appended via post' );
    is( $result[3], 'London : ',      '264 ex21: $a gets " : " for $b' );
    is( $result[5], 'Elle',           '264 ex21: $b (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules_264, 'prefix' );
    is( $result_pr[1], 'June 1993-: ',  '264 ex21 prefix: $3 gets ": " via post' );
    is( $result_pr[3], 'London',        '264 ex21 prefix: $a unchanged' );
    is( $result_pr[5], ' : Elle',       '264 ex21 prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '264 ex21: combined string identical' );
}

done_testing();
