#!/usr/bin/perl
#
# Tests for the DACH-EXCLUSIVE fields: 249 and 532.
#
# These two tags exist ONLY in the DACH rule set (they are not part of the
# LoC/PCC baseline), so they can never appear in the equal-field guard
# (50-dach-01-equal.t) nor in the deltas test (50-dach-02-deltas.t) -
# they get their own dedicated pins. See RuleSets.md for the switchable-set
# model ("all RuleSets are descendants of the LoC/PCC set").
#
# 249 - Weitere Titel bei Zusammenstellungen (additional collective title).
#   German union-catalogue field, defined only in isbd.py (ISBD249).
#   Semantics (from the DNB description, supplied by the user 2026-09-14):
#     $a ~ 245$a  (individual title)  - repeatable
#     $v ~ 245$c  (statement of responsibility for that title) - repeatable
#     $b ~ 245$b  (collective/general title, once)             - not repeatable
#     $c ~ 245$c  (statement of responsibility of the collective title, once)
#   Each $a$v pair is one entry; entries are separated by '. '; within an
#   entry $a and $v are glued by ' / '.  isbd.py keys: a:'.', v:' /',
#   b:'.', c:' /'.
#   6a (880-link) NOT handled - 880 not supported by the engine (mirrors the
#   LoCPCC 880 WON'T-DO).
#
# 532 - Accessibility Note.
#   Free-text note; all subfields N/A (explicit empty block). Pass-through.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field combined_string check_combined);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $SET = 'DACH';
note( "Rule set under test: $SET (exclusive tags 249 + 532)" );

my $rules_249 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{249};
my $rules_532 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{532};
ok( defined $rules_249, '249 rules loaded (DACH-only tag)' );
ok( defined $rules_532, '532 rules loaded (DACH-only tag)' );

# --- 249: single $a$v block ---
{
    # render: 249 00 $a Haupttitel $v Band 1
    my $field = make_field( '249', ' ', ' ', a => 'Haupttitel', v => 'Band 1' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'postfix' );
    is( scalar @result, 4, '249: single $a$v returns 4 elements' );
    is( $result[1], 'Haupttitel / ', '249: $a gets " / " when $v follows' );
    is( $result[3], 'Band 1',        '249: $v is unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'prefix' );
    is( $result_pr[1], 'Haupttitel', '249 prefix: $a unchanged' );
    is( $result_pr[3], ' / Band 1',  '249 prefix: $v gets " / " prepended' );

    check_combined( \@result, \@result_pr, '249: single $a$v combined identical' );
}

# --- 249: two $a$v blocks (the "many entries" case) ---
{
    # render: 249 00 $a Titel Eins $v Verantwortlichkeit $a Titel Zwei $v Zweite Verantwortlichkeit
    my $field = make_field(
        '249', ' ', ' ',
        a => 'Titel Eins', v => 'Verantwortlichkeit',
        a => 'Titel Zwei', v => 'Zweite Verantwortlichkeit',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'postfix' );
    is( $result[1], 'Titel Eins / ',          '249: $a1 gets " / " ($v follows)' );
    is( $result[3], 'Verantwortlichkeit. ',   '249: $v1 gets " . " when a new $a follows' );
    is( $result[5], 'Titel Zwei / ', '249: $a2 gets " / " ($v follows)' );
    is( $result[7], 'Zweite Verantwortlichkeit', '249: $v2 is unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'prefix' );
    is( $result_pr[1], 'Titel Eins',            '249 prefix: $a1 unchanged' );
    is( $result_pr[3], ' / Verantwortlichkeit', '249 prefix: $v1 gets " / " prepended' );
    is( $result_pr[5], '. Titel Zwei',          '249 prefix: $a2 gets " . " prepended' );
    is( $result_pr[7], ' / Zweite Verantwortlichkeit', '249 prefix: $v2 gets " / " prepended' );

    check_combined( \@result, \@result_pr, '249: two-block combined identical' );
}

# --- 249: $a$v blocks followed by $b$c (collective title) ---
{
    # render: 249 00 $a Werk 1 $v Autor 1 $a Werk 2 $v Autor 2 $b Gesamttitel $c Hrsg. 1
    my $field = make_field(
        '249', ' ', ' ',
        a => 'Werk 1', v => 'Autor 1',
        a => 'Werk 2', v => 'Autor 2',
        b => 'Gesamttitel', c => 'Hrsg. 1',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'postfix' );
    is( $result[1],  'Werk 1 / ',      '249: $a1 gets " / " ($v follows)' );
    is( $result[3],  'Autor 1. ',      '249: $v1 gets " . " (new $a follows)' );
    is( $result[5],  'Werk 2 / ',      '249: $a2 gets " / " ($v follows)' );
    is( $result[7],  'Autor 2. ',      '249: $v2 gets " . " ($b follows)' );
    is( $result[9],  'Gesamttitel / ', '249: $b gets " / " ($c follows)' );
    is( $result[11], 'Hrsg. 1',        '249: $c is unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_249, 'prefix' );
    is( $result_pr[1],  'Werk 1',       '249 prefix: $a1 unchanged' );
    is( $result_pr[3],  ' / Autor 1',   '249 prefix: $v1 gets " / " prepended' );
    is( $result_pr[5],  '. Werk 2',     '249 prefix: $a2 gets " . " prepended' );
    is( $result_pr[7],  ' / Autor 2',   '249 prefix: $v2 gets " / " prepended' );
    is( $result_pr[9],  '. Gesamttitel','249 prefix: $b gets " . " prepended' );
    is( $result_pr[11], ' / Hrsg. 1',   '249 prefix: $c gets " / " prepended' );

    check_combined( \@result, \@result_pr, '249: $a$v/$b$c combined identical' );
}

# --- 532: free-text note (pass-through, no punctuation) ---
{
    # render: 532 0# $a Full text of the publication is available...
    my $field = make_field( '532', ' ', ' ',
        a => 'Full text of the publication is available...' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_532, 'postfix' );
    is( scalar @result, 2, '532: $a alone returns 2 elements' );
    is( $result[1], 'Full text of the publication is available...',
        '532: $a passes through verbatim (unstripped content, no punctuation)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_532, 'prefix' );
    is( $result_pr[1], 'Full text of the publication is available...',
        '532 prefix: $a passes through verbatim' );

    check_combined( \@result, \@result_pr, '532: combined string identical (verbatim)' );
}

done_testing();
