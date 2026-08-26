#!/usr/bin/perl
#
# Regression tests for Field 245 derived from isbdmarc2016.pdf Current/Future examples.
# Only includes test cases that should PASS with current code (after adding $r/$t to 245 pchrs).

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{245};
ok( defined $rules, '245 rules loaded' );

# --- Example 1: $a + $c (simple responsibility) ---
# Doc: Future: 245 14 $a The plays of Oscar Wilde $c Alan Bird
# Doc: Current: 245 14 $a The plays of Oscar Wilde / $c Alan Bird.
{
    my $field = make_field( '245', '1', '4',
        a => 'The plays of Oscar Wilde',
        c => 'Alan Bird',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'The plays of Oscar Wilde / ', '245 ex1: $a gets " / " for $c' );
    is( $result[3], 'Alan Bird',                    '245 ex1: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'The plays of Oscar Wilde', '245 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' / Alan Bird',              '245 ex1 prefix: $c gets " / " prepended' );

    is( join('', @result[1,3]), join('', @result_pr[1,3]), '245 ex1: combined string identical' );
}

# --- Example 2: $a + $b + $r (parallel title) ---
# Doc: Future: 245 10 $a Rock mechanics $b journal... $r Felsmechanik
# Doc: Current: 245 10 $a Rock mechanics : $b journal... = $r Felsmechanik.
{
    my $field = make_field( '245', '1', '0',
        a => 'Rock mechanics',
        b => 'journal of the International Society for Rock Mechanics',
        r => 'Felsmechanik',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Rock mechanics : ',                                               '245 ex2: $a gets " : " for $b' );
    is( $result[3], 'journal of the International Society for Rock Mechanics = ',       '245 ex2: $b gets " = " for $r' );
    is( $result[5], 'Felsmechanik',                                                      '245 ex2: $r (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Rock mechanics',                                                 '245 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ' : journal of the International Society for Rock Mechanics',     '245 ex2 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' = Felsmechanik',                                                '245 ex2 prefix: $r gets " = " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '245 ex2: combined string identical' );
}

# --- Example 3: $a + $c + $r + $c (parallel statements of responsibility) ---
# Doc: Future: 245 00 $a Retail et volaille $c Bureau... $r Livestock... $c Quebec...
# Doc: Current: 245 00 $a Retail et volaille / $c Bureau... = $r Livestock... / $c Quebec...
{
    my $field = make_field( '245', '0', '0',
        a => 'Retail et volaille',
        c => 'Bureau des statistiques de Québec',
        r => 'Livestock and poultry',
        c => 'Quebec Bureau of Statistics',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Retail et volaille / ',                        '245 ex3: $a gets " / " for $c' );
    is( $result[3], 'Bureau des statistiques de Québec = ',         '245 ex3: $c gets " = " for $r' );
    is( $result[5], 'Livestock and poultry / ',                     '245 ex3: $r gets " / " for second $c' );
    is( $result[7], 'Quebec Bureau of Statistics',                  '245 ex3: second $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Retail et volaille',                          '245 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ' / Bureau des statistiques de Québec',        '245 ex3 prefix: first $c gets " / " prepended' );
    is( $result_pr[5], ' = Livestock and poultry',                    '245 ex3 prefix: $r gets " = " prepended' );
    is( $result_pr[7], ' / Quebec Bureau of Statistics',              '245 ex3 prefix: second $c gets " / " prepended' );

    is( join('', @result[1,3,5,7]), join('', @result_pr[1,3,5,7]), '245 ex3: combined string identical' );
}

# --- Example 4: $c + $d + $d (subsequent statements of responsibility) ---
# Doc: Future: 245 10 $a How to play chess $c Kevin Wicker $d with a foreword... $d illustrated...
# Doc: Current: 245 10 $a How to play chess / $c Kevin Wicker ; $d with a foreword... ; $d illustrated...
{
    my $field = make_field( '245', '1', '0',
        a => 'How to play chess',
        c => 'Kevin Wicker',
        d => 'with a foreword by David Pritchard',
        d => 'illustrated by Karel Feuerstein',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'How to play chess / ',              '245 ex4: $a gets " / " for $c' );
    is( $result[3], 'Kevin Wicker ; ',                   '245 ex4: $c gets " ; " for first $d' );
    is( $result[5], 'with a foreword by David Pritchard ; ', '245 ex4: first $d gets " ; " for second $d' );
    is( $result[7], 'illustrated by Karel Feuerstein',   '245 ex4: second $d (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'How to play chess',               '245 ex4 prefix: $a unchanged' );
    is( $result_pr[3], ' / Kevin Wicker',                 '245 ex4 prefix: $c gets " / " prepended' );
    is( $result_pr[5], ' ; with a foreword by David Pritchard', '245 ex4 prefix: first $d gets " ; " prepended' );
    is( $result_pr[7], ' ; illustrated by Karel Feuerstein',    '245 ex4 prefix: second $d gets " ; " prepended' );

    is( join('', @result[1,3,5,7]), join('', @result_pr[1,3,5,7]), '245 ex4: combined string identical' );
}

done_testing();
