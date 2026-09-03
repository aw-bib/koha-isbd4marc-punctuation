# Tests for Fields 243 (Collective Uniform Title), 730 (Added Entry -
# Uniform Title) and 830 (Series Added Entry - Uniform Title), derived from
# isbdmarc2016.pdf §5.5 (Uniform Titles).
#
# All three are UNIFORM TITLE fields governed by §5.5, same as 130/240:
#   $a is the (plain) title; $b is a repeatable QUALIFYING-INFORMATION
#   group wrapped in ONE pair of parentheses, multiple $b separated by
#   ' : ' (shared helper _decorate_qualifier_group_pre).
#
#   243 and 730 alias 240 via use_rules => '240' (Appendix B lists 240,
#   243 and 730 together for $b/$j/$n). 730 additionally has $i
#   (relationship info) and $x (ISSN), both N/A (no punct) -> pass through.
#
#   830 is the series variant: the same §5.5 block PLUS $v (volume /
#   sequential designation) which gets ' ; ' (830 only, alongside 800/810/
#   811) and $x (ISSN, N/A).

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

my $rules_243 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'243'};
ok( defined $rules_243, '243 rules loaded' );

my $rules_730 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'730'};
ok( defined $rules_730, '730 rules loaded' );

my $rules_830 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'830'};
ok( defined $rules_830, '830 rules loaded' );

# --- Aliasing: 243 and 730 reuse the 240 uniform-title block ---
{
    is( $rules_243->{use_rules}, '240',
        '243 aliases 240 via use_rules (uniform-title block)' );
    is( $rules_730->{use_rules}, '240',
        '730 aliases 240 via use_rules (uniform-title block)' );
}

# --- 243 example 1: $a + single $b (collective uniform title) ---
{
    # render: 243 00 $a Works $b Selections
    my $field = make_field(
        '243', '0', '0',
        a => 'Works',
        b => 'Selections',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_243, 'postfix' );
    is( $result[1], 'Works', '243 example 1 postfix: $a unchanged' );
    is( $result[3], '(Selections)',
        '243 example 1 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_243, 'prefix' );
    is( $result_pr[1], 'Works', '243 example 1 prefix: $a unchanged' );
    is( $result_pr[3], '(Selections)',
        '243 example 1 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '243 example 1: combined string identical' );
}

# --- 243 example 2: $a + TWO $b (multiple qualifiers, ' : ') ---
{
    # render: 243 00 $a Works $b Selections $b Abridgements
    my $field = make_field(
        '243', '0', '0',
        a => 'Works',
        b => 'Selections',
        b => 'Abridgements',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_243, 'postfix' );
    is( $result[1], 'Works', '243 example 2 postfix: $a unchanged' );
    is( $result[3], '(Selections',
        '243 example 2 postfix: first $b opens the paren' );
    is( $result[5], ' : Abridgements)',
        '243 example 2 postfix: second $b gets " : " + close paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_243, 'prefix' );
    is( $result_pr[1], 'Works', '243 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Selections',
        '243 example 2 prefix: first $b opens the paren' );
    is( $result_pr[5], ' : Abridgements)',
        '243 example 2 prefix: second $b gets " : " + close paren' );

    check_combined( \@result, \@result_pr,
        '243 example 2: combined string identical' );
}

# --- 730 example 1: $i (relationship info, N/A) + $a $l ---
# $i must pass through unchanged (no punct); $a gets '. ' before $l.
{
    # render: 730 0# $i Contains $a Bible $l English
    my $field = make_field(
        '730', '0', '#',
        i => 'Contains',
        a => 'Bible',
        l => 'English',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_730, 'postfix' );
    is( $result[1], 'Contains',
        '730 example 1 postfix: $i (relationship info) passes through (N/A)' );
    is( $result[3], 'Bible. ',
        '730 example 1 postfix: $a gets ". " before $l' );
    is( $result[5], 'English',
        '730 example 1 postfix: $l (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_730, 'prefix' );
    is( $result_pr[1], 'Contains',
        '730 example 1 prefix: $i (relationship info) passes through (N/A)' );
    is( $result_pr[3], 'Bible',
        '730 example 1 prefix: $a unchanged (punct moved to $l)' );
    is( $result_pr[5], '. English',
        '730 example 1 prefix: $l gets ". " prepended' );

    check_combined( \@result, \@result_pr,
        '730 example 1: combined string identical' );
}

# --- 730 example 2: $a + $b qualifier group + $l ---
# Confirms the shared $b paren-group works via the 240 alias on 730.
{
    # render: 730 0# $a Bible $b Old Testament $l English
    my $field = make_field(
        '730', '0', '#',
        a => 'Bible',
        b => 'Old Testament',
        l => 'English',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_730, 'postfix' );
    is( $result[1], 'Bible', '730 example 2 postfix: $a unchanged' );
    is( $result[3], '(Old Testament). ',
        '730 example 2 postfix: $b wrapped in (), gets ". " before $l' );
    is( $result[5], 'English',
        '730 example 2 postfix: $l (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_730, 'prefix' );
    is( $result_pr[1], 'Bible', '730 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Old Testament)',
        '730 example 2 prefix: $b wrapped in () (punct moved to $l)' );
    is( $result_pr[5], '. English',
        '730 example 2 prefix: $l gets ". " prepended' );

    check_combined( \@result, \@result_pr,
        '730 example 2: combined string identical' );
}

# --- 830 example 1: $a + $v (volume, ' ;') ---
# $v (volume) is 830-only extra on top of the §5.5 block.
{
    # render: 830 #0 $a Lecture notes in physics $v 123
    my $field = make_field(
        '830', '#', '0',
        a => 'Lecture notes in physics',
        v => '123',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'postfix' );
    is( $result[1], 'Lecture notes in physics ;',
        '830 example 1 postfix: $a gets " ;" before $v' );
    is( $result[3], '123',
        '830 example 1 postfix: $v (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'prefix' );
    is( $result_pr[1], 'Lecture notes in physics',
        '830 example 1 prefix: $a unchanged (punct moved to $v)' );
    is( $result_pr[3], ' ;123',
        '830 example 1 prefix: $v gets " ;" prepended (series $v convention)' );

    check_combined( \@result, \@result_pr,
        '830 example 1: combined string identical' );
}

# --- 830 example 2: $a + $b qualifier group + $v ---
{
    # render: 830 #0 $a Lecture notes in physics $b New series $v 123
    my $field = make_field(
        '830', '#', '0',
        a => 'Lecture notes in physics',
        b => 'New series',
        v => '123',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'postfix' );
    is( $result[1], 'Lecture notes in physics',
        '830 example 2 postfix: $a unchanged' );
    is( $result[3], '(New series) ;',
        '830 example 2 postfix: $b wrapped in (), gets " ;" before $v' );
    is( $result[5], '123',
        '830 example 2 postfix: $v (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'prefix' );
    is( $result_pr[1], 'Lecture notes in physics',
        '830 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(New series)',
        '830 example 2 prefix: $b wrapped in () (punct moved to $v)' );
    is( $result_pr[5], ' ;123',
        '830 example 2 prefix: $v gets " ;" prepended (series $v convention)' );

    check_combined( \@result, \@result_pr,
        '830 example 2: combined string identical' );
}

# --- 830 edge: $a alone ---
{
    # render: 830 #0 $a Lecture notes in physics
    my $field = make_field( '830', '#', '0', a => 'Lecture notes in physics' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'postfix' );
    is( $result[1], 'Lecture notes in physics', '830: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_830, 'prefix' );
    is( $result_pr[1], 'Lecture notes in physics',
        '830 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '830: combined string identical (just $a)' );
}

done_testing();
