# Tests for Field 630 (Subject Added Entry - Uniform Title), derived from
# isbdmarc2016.pdf §5.5 (Uniform Titles).
#
# 630 is part of the same §5.5 uniform-title family as 130/240/243/730/830
# (K10plus confirms the grouping: its ISBDX30 dict is shared by 130/630/730/
# 830, with 630 = base minus $v). $a is the (plain) title and $b is the
# repeatable QUALIFYING-INFORMATION group wrapped in ONE pair of parens,
# multiple $b separated by ' : ' (shared _decorate_qualifier_group_pre, same
# as 240/130/243/730/830).
#
# 630's ONE genuine difference from the base uniform-title block: $e (relator
# term, 630 only) -> ', ' per §5.5. $v (volume, 830-only) is absent, and the
# $x/$y/$z subject subdivisions get no punctuation. Implemented as its own
# standalone block (like 830) because use_rules is a full alias (no merge).

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

my $rules_630 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'630'};
ok( defined $rules_630, '630 rules loaded' );

# 630 does NOT alias 240 (it is its own block to add the $e key).
ok( !exists $rules_630->{use_rules},
    '630 has its own rules (no use_rules alias; standalone block)' );

# --- 630 example 1: $e (relator, 630-only) + $l ---
# $e is the subject-only relator term -> ', ' (spec §5.5).
{
    # render: 630 00 $a Bible $e author $l English
    my $field = make_field(
        '630', '0', '0',
        a => 'Bible',
        e => 'author',
        l => 'English',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'postfix' );
    is( $result[1], 'Bible, ',
        '630 example 1 postfix: $a gets ", " before $e (relator)' );
    is( $result[3], 'author. ',
        '630 example 1 postfix: $e gets ". " before $l' );
    is( $result[5], 'English',
        '630 example 1 postfix: $l (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'prefix' );
    is( $result_pr[1], 'Bible',
        '630 example 1 prefix: $a unchanged (punct moved to $e)' );
    is( $result_pr[3], ', author',
        '630 example 1 prefix: $e gets ", " prepended' );
    is( $result_pr[5], '. English',
        '630 example 1 prefix: $l gets ". " prepended' );

    check_combined( \@result, \@result_pr,
        '630 example 1: combined string identical' );
}

# --- 630 example 2: $b qualifier group (shared 240/$5.5 block) + $l ---
{
    # render: 630 00 $a Bible $b Old Testament $l English
    my $field = make_field(
        '630', '0', '0',
        a => 'Bible',
        b => 'Old Testament',
        l => 'English',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'postfix' );
    is( $result[1], 'Bible', '630 example 2 postfix: $a unchanged' );
    is( $result[3], '(Old Testament). ',
        '630 example 2 postfix: $b wrapped in (), gets ". " before $l' );
    is( $result[5], 'English',
        '630 example 2 postfix: $l (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'prefix' );
    is( $result_pr[1], 'Bible', '630 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Old Testament)',
        '630 example 2 prefix: $b wrapped in () (punct moved to $l)' );
    is( $result_pr[5], '. English',
        '630 example 2 prefix: $l gets ". " prepended' );

    check_combined( \@result, \@result_pr,
        '630 example 2: combined string identical' );
}

# --- 630 example 3: TWO $b (multiple qualifiers, ' : ') + $e ---
{
    # render: 630 00 $a Bible $b Old Testament $b Apocrypha $e editor
    my $field = make_field(
        '630', '0', '0',
        a => 'Bible',
        b => 'Old Testament',
        b => 'Apocrypha',
        e => 'editor',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'postfix' );
    is( $result[1], 'Bible', '630 example 3 postfix: $a unchanged' );
    is( $result[3], '(Old Testament',
        '630 example 3 postfix: first $b opens the paren' );
    is( $result[5], ' : Apocrypha), ',
        '630 example 3 postfix: second $b closes paren, gets ", " before $e' );
    is( $result[7], 'editor',
        '630 example 3 postfix: $e (final, no trailing punct)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'prefix' );
    is( $result_pr[1], 'Bible', '630 example 3 prefix: $a unchanged' );
    is( $result_pr[3], '(Old Testament',
        '630 example 3 prefix: first $b opens the paren' );
    is( $result_pr[5], ' : Apocrypha)',
        '630 example 3 prefix: second $b closes paren' );
    is( $result_pr[7], ', editor',
        '630 example 3 prefix: $e gets ", " prepended' );

    check_combined( \@result, \@result_pr,
        '630 example 3: combined string identical' );
}

# --- 630 edge: $a alone ---
{
    # render: 630 00 $a Bible
    my $field = make_field( '630', '0', '0', a => 'Bible' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'postfix' );
    is( $result[1], 'Bible', '630: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_630, 'prefix' );
    is( $result_pr[1], 'Bible', '630 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '630: combined string identical (just $a)' );
}

done_testing();
