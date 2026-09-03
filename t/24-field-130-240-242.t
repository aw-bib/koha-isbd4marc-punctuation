# Tests for Fields 130 (Main Entry - Uniform Title), 240 (Uniform Title)
# and 242 (Translation of Title by Cataloging Agency), derived from
# isbdmarc2016.pdf §5.5 (Uniform Titles) and §4.4 (Field 242).
#
# 130 and 240 are UNIFORM TITLE fields (§5.5): $a is the (plain) title;
# $b is a repeatable QUALIFYING-INFORMATION group wrapped in ONE pair of
# parentheses, multiple $b separated by ' : '. This is the same
# repeatable-group pattern as 020 $q / 210 $b / 222 $b, handled by the
# shared engine helper _decorate_qualifier_group_pre (020 separator ' ; ',
# 210 ', ', 222 '. ', here ' : '). 240 is canonical; 130 aliases it
# (use_rules => 240): both have the same §5.5 title-portion subfields, and
# 130's $d is not in the §5.5 list (see code comment).
#
# 242 is a TITLE STATEMENT field (§4.4), a near-clone of 245 but WITHOUT
# parallel-data subfields ($r/$t). Context-dependent subfields ($a/$o/$p)
# are documented gaps, like 245.
#
# NOTE on mode assertions: in POSTFIX mode punctuation is appended to the
# PRECEDING subfield; in PREFIX mode it is prepended to the FOLLOWING
# subfield ($pending). The COMBINED string is identical in both modes
# (asserted via check_combined) — only the subfield ownership differs.

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

my $rules_130 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'130'};
ok( defined $rules_130, '130 rules loaded' );

my $rules_240 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'240'};
ok( defined $rules_240, '240 rules loaded' );

my $rules_242 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'242'};
ok( defined $rules_242, '242 rules loaded' );

# --- 130 example 1 (§5.5): $a + single $b + $p ---
# Doc: Future:  130 0# $a Statistical bulletin $b Bamako, Mali $p Supplement
# Doc: Current: 130 0# $a Statistical bulletin (Bamako, Mali). $p Supplement.
{
    # render: 130 0# $a Statistical bulletin $b Bamako, Mali $p Supplement
    my $field = make_field(
        '130', '0', '#',
        a => 'Statistical bulletin',
        b => 'Bamako, Mali',
        p => 'Supplement',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'postfix' );
    is( $result[1], 'Statistical bulletin',
        '130 example 1 postfix: $a unchanged (natural start)' );
    is( $result[3], '(Bamako, Mali), ',
        '130 example 1 postfix: $b wrapped in (), gets ", " before $p' );
    is( $result[5], 'Supplement',
        '130 example 1 postfix: $p (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'prefix' );
    is( $result_pr[1], 'Statistical bulletin',
        '130 example 1 prefix: $a unchanged' );
    is( $result_pr[3], '(Bamako, Mali)',
        '130 example 1 prefix: $b wrapped in () (punct moved to $p)' );
    is( $result_pr[5], ', Supplement',
        '130 example 1 prefix: $p gets ", " prepended' );

    check_combined( \@result, \@result_pr,
        '130 example 1: combined string identical' );
}

# --- 130 example 2 (§5.5): $a + single $b ---
# Doc: Future:  130 0# $a San Francisco journal $b 1980
# Doc: Current: 130 0# $a San Francisco journal (1980)
{
    # render: 130 0# $a San Francisco journal $b 1980
    my $field = make_field(
        '130', '0', '#',
        a => 'San Francisco journal',
        b => '1980',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'postfix' );
    is( $result[1], 'San Francisco journal',
        '130 example 2 postfix: $a unchanged' );
    is( $result[3], '(1980)', '130 example 2 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'prefix' );
    is( $result_pr[1], 'San Francisco journal',
        '130 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(1980)', '130 example 2 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '130 example 2: combined string identical' );
}

# --- 130 example 3 (§5.5): $a + TWO $b (multiple qualifiers, ' : ') + $l ---
# Doc: Future:  130 0# $a Dialogue $b Montreal, Quebec $b 1962 $l English
# Doc: Current: 130 0# $a Dialogue (Montreal, Quebec : 1962). $l English.
{
    # render: 130 0# $a Dialogue $b Montreal, Quebec $b 1962 $l English
    my $field = make_field(
        '130', '0', '#',
        a => 'Dialogue',
        b => 'Montreal, Quebec',
        b => '1962',
        l => 'English',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'postfix' );
    is( $result[1], 'Dialogue', '130 example 3 postfix: $a unchanged' );
    is( $result[3], '(Montreal, Quebec',
        '130 example 3 postfix: first $b opens the paren' );
    is( $result[5], ' : 1962). ',
        '130 example 3 postfix: second $b gets " : " + close paren, then ". " before $l' );
    is( $result[7], 'English',
        '130 example 3 postfix: $l (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'prefix' );
    is( $result_pr[1], 'Dialogue', '130 example 3 prefix: $a unchanged' );
    is( $result_pr[3], '(Montreal, Quebec',
        '130 example 3 prefix: first $b opens the paren' );
    is( $result_pr[5], ' : 1962)',
        '130 example 3 prefix: second $b gets " : " + close paren' );
    is( $result_pr[7], '. English',
        '130 example 3 prefix: $l gets ". " prepended' );

    check_combined( \@result, \@result_pr,
        '130 example 3: combined string identical' );
}

# --- 130 edge: $a alone ---
{
    # render: 130 0# $a Statistical bulletin
    my $field = make_field( '130', '0', '#', a => 'Statistical bulletin' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'postfix' );
    is( $result[1], 'Statistical bulletin', '130: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_130, 'prefix' );
    is( $result_pr[1], 'Statistical bulletin', '130 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '130: combined string identical (just $a)' );
}

# --- 130 aliases 240 via use_rules (shared uniform-title §5.5 block) ---
{
    is(
        $rules_130->{use_rules},
        '240',
        '130 aliases 240 via use_rules (shared uniform-title block)'
    );
}

# --- 240 example 1 (§5.5 / Appendix C.5 worked example):
#      $a $m $j $r $p $o (music uniform title) ---
# Doc: Future:  240 10 $a Sonatas $m piano $j no. 8, op. 13 $r C minor
#                        $p Adagio cantabile $o arranged
# Doc: Current: 240 10 $a Sonatas, $m piano, $n no. 8, op. 13, $r C minor.
#                        $p Adagio cantabile; $o arranged.
{
    # render: 240 10 $a Sonatas $m piano $j no. 8, op. 13 $r C minor $p Adagio cantabile $o arranged
    my $field = make_field(
        '240', '1', '0',
        a => 'Sonatas',
        m => 'piano',
        j => 'no. 8, op. 13',
        r => 'C minor',
        p => 'Adagio cantabile',
        o => 'arranged',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'postfix' );
    is( $result[1], 'Sonatas, ',
        '240 example 1 postfix: $a gets ", " before $m' );
    is( $result[3], 'piano, ',
        '240 example 1 postfix: $m gets ", " before $j' );
    is( $result[5], 'no. 8, op. 13, ',
        '240 example 1 postfix: $j gets ", " when $r follows' );
    is( $result[7], 'C minor, ',
        '240 example 1 postfix: $r gets ", " (key for music; $p follows)' );
    is( $result[9], 'Adagio cantabile; ',
        '240 example 1 postfix: $p gets "; " when $o follows' );
    is( $result[11], 'arranged',
        '240 example 1 postfix: $o (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'prefix' );
    is( $result_pr[1], 'Sonatas',
        '240 example 1 prefix: $a unchanged (punct moved to $m)' );
    is( $result_pr[3], ', piano',
        '240 example 1 prefix: $m gets ", " prepended' );
    is( $result_pr[5], ', no. 8, op. 13',
        '240 example 1 prefix: $j gets ", " prepended' );
    is( $result_pr[7], ', C minor',
        '240 example 1 prefix: $r gets ", " prepended' );
    is( $result_pr[9], ', Adagio cantabile',
        '240 example 1 prefix: $p gets ", " prepended' );
    is( $result_pr[11], '; arranged',
        '240 example 1 prefix: $o gets "; " prepended' );

    check_combined( \@result, \@result_pr,
        '240 example 1: combined string identical' );
}

# --- 240 example 2: $a + TWO $b (multiple qualifiers, ' : ') ---
# Uniform titles can repeat the $b qualifying group like 130.
{
    # render: 240 10 $a Dialogue $b Montreal, Quebec $b 1962
    my $field = make_field(
        '240', '1', '0',
        a => 'Dialogue',
        b => 'Montreal, Quebec',
        b => '1962',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'postfix' );
    is( $result[1], 'Dialogue', '240 example 2 postfix: $a unchanged' );
    is( $result[3], '(Montreal, Quebec',
        '240 example 2 postfix: first $b opens the paren' );
    is( $result[5], ' : 1962)',
        '240 example 2 postfix: second $b gets " : " + close paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'prefix' );
    is( $result_pr[1], 'Dialogue', '240 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Montreal, Quebec',
        '240 example 2 prefix: first $b opens the paren' );
    is( $result_pr[5], ' : 1962)',
        '240 example 2 prefix: second $b gets " : " + close paren' );

    check_combined( \@result, \@result_pr,
        '240 example 2: combined string identical' );
}

# --- 240 edge: $a alone ---
{
    # render: 240 10 $a Sonatas
    my $field = make_field( '240', '1', '0', a => 'Sonatas' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'postfix' );
    is( $result[1], 'Sonatas', '240: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_240, 'prefix' );
    is( $result_pr[1], 'Sonatas', '240 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '240: combined string identical (just $a)' );
}

# --- 242 example 1 (§4.4): $a $n $p $q $y ---
# Doc: Future:  242 00 $a Annals of chemistry $n Series C
#                        $p Organic chemistry and biochemistry $y eng
# Doc: Current: 242 00 $a Annals of chemistry. $n Series C, $p Organic
#                        chemistry and biochemistry. $y eng
{
    # render: 242 00 $a Annals of chemistry $n Series C $p Organic chemistry and biochemistry $y eng
    my $field = make_field(
        '242', '0', '0',
        a => 'Annals of chemistry',
        n => 'Series C',
        p => 'Organic chemistry and biochemistry',
        y => 'eng',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'postfix' );
    is( $result[1], 'Annals of chemistry. ',
        '242 example 1 postfix: $a gets ". " before $n' );
    is( $result[3], 'Series C, ',
        '242 example 1 postfix: $n gets ", " before $p' );
    is( $result[5], 'Organic chemistry and biochemistry',
        '242 example 1 postfix: $p unchanged ($y has no punct)' );
    is( $result[7], 'eng',
        '242 example 1 postfix: $y language code (no punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'prefix' );
    is( $result_pr[1], 'Annals of chemistry',
        '242 example 1 prefix: $a unchanged (punct moved to $n)' );
    is( $result_pr[3], '. Series C',
        '242 example 1 prefix: $n gets ". " prepended' );
    is( $result_pr[5], ', Organic chemistry and biochemistry',
        '242 example 1 prefix: $p gets ", " prepended' );
    is( $result_pr[7], 'eng',
        '242 example 1 prefix: $y language code (no punct)' );

    check_combined( \@result, \@result_pr,
        '242 example 1: combined string identical' );
}

# --- 242 example 2: $a $b $q (title proper + other info + alternative) ---
# 242 with $b (other title information) and $q (alternative title).
{
    # render: 242 10 $a Annals of chemistry $b Series C $q Organic chemistry
    my $field = make_field(
        '242', '1', '0',
        a => 'Annals of chemistry',
        b => 'Series C',
        q => 'Organic chemistry',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'postfix' );
    is( $result[1], 'Annals of chemistry : ',
        '242 example 2 postfix: $a gets " : " before $b' );
    is( $result[3], 'Series C, ',
        '242 example 2 postfix: $b gets ", " before $q' );
    is( $result[5], 'Organic chemistry',
        '242 example 2 postfix: $q (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'prefix' );
    is( $result_pr[1], 'Annals of chemistry',
        '242 example 2 prefix: $a unchanged (punct moved to $b)' );
    is( $result_pr[3], ' : Series C',
        '242 example 2 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ', Organic chemistry',
        '242 example 2 prefix: $q gets ", " prepended' );

    check_combined( \@result, \@result_pr,
        '242 example 2: combined string identical' );
}

# --- 242 edge: $a alone ---
{
    # render: 242 00 $a Annals of chemistry
    my $field = make_field( '242', '0', '0', a => 'Annals of chemistry' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'postfix' );
    is( $result[1], 'Annals of chemistry', '242: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_242, 'prefix' );
    is( $result_pr[1], 'Annals of chemistry',
        '242 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '242: combined string identical (just $a)' );
}

done_testing();
