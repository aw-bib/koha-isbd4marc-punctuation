#
# Tests for Fields 210 (Abbreviated Title) and 222 (Key Title),
# derived from isbdmarc2016.pdf §4.2 / §4.3 Current/Future examples.
#
# Both fields share the same shape: a repeatable $b (qualifying information)
# wrapped in ONE pair of parentheses, with multiple $b separated by a
# per-field separator — 210 uses ', ' (comma-space), 222 uses '. '
# (period-space). This is the same repeatable-group pattern as 020 $q
# (separator ' ; '), handled by the shared engine helper
# _decorate_qualifier_group_pre.

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

my $rules_210 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'210'};
ok( defined $rules_210, '210 rules loaded' );

my $rules_222 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{'222'};
ok( defined $rules_222, '222 rules loaded' );

# --- 210 Example 1: $a + single $b ---
# Doc: Future:  210 0# $a Plant prot. bull. $b Faridabad
# Doc: Current: 210 0# $a Plant prot. bull. $b (Faridabad)
{
    # render: 210 0# $a Plant prot. bull. $b Faridabad
    my $field = make_field(
        '210', '0', '#',
        a => 'Plant prot. bull.',
        b => 'Faridabad',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'postfix' );
    is( $result[1], 'Plant prot. bull.',
        '210 example 1 postfix: $a unchanged' );
    is( $result[3], '(Faridabad)',
        '210 example 1 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'prefix' );
    is( $result_pr[1], 'Plant prot. bull.',
        '210 example 1 prefix: $a unchanged' );
    is( $result_pr[3], '(Faridabad)',
        '210 example 1 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '210 example 1: combined string identical' );
}

# --- 210 Example 2: $a + single $b (abbreviation) ---
# Doc: Future:  210 0# $a Annu. rep. - Dep. Public Welfare $b Chic.
# Doc: Current: 210 0# $a Annu. rep. - Dep. Public Welfare $b (Chic.)
{
    # render: 210 0# $a Annu. rep. - Dep. Public Welfare $b Chic.
    my $field = make_field(
        '210', '0', '#',
        a => 'Annu. rep. - Dep. Public Welfare',
        b => 'Chic.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'postfix' );
    is( $result[1], 'Annu. rep. - Dep. Public Welfare',
        '210 example 2 postfix: $a unchanged' );
    is( $result[3], '(Chic.)', '210 example 2 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'prefix' );
    is( $result_pr[1], 'Annu. rep. - Dep. Public Welfare',
        '210 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Chic.)', '210 example 2 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '210 example 2: combined string identical' );
}

# --- 210 Example 3: $a + two $b (multiple qualifiers, ', ' separator) ---
# Doc: Future:  210 0# $a Fam. her. $b Montr. $b 1859
# Doc: Current: 210 0# $a Fam. her. $b (Montr., 1859)
{
    # render: 210 0# $a Fam. her. $b Montr. $b 1859
    my $field = make_field(
        '210', '0', '#',
        a => 'Fam. her.',
        b => 'Montr.',
        b => '1859',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'postfix' );
    is( $result[1], 'Fam. her.', '210 example 3 postfix: $a unchanged' );
    is( $result[3], '(Montr.',
        '210 example 3 postfix: first $b opens the paren' );
    is( $result[5], ', 1859)',
        '210 example 3 postfix: second $b gets ", " + close paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'prefix' );
    is( $result_pr[1], 'Fam. her.', '210 example 3 prefix: $a unchanged' );
    is( $result_pr[3], '(Montr.',
        '210 example 3 prefix: first $b opens the paren' );
    is( $result_pr[5], ', 1859)',
        '210 example 3 prefix: second $b gets ", " + close paren' );

    check_combined( \@result, \@result_pr,
        '210 example 3: combined string identical' );
}

# --- 210 Edge: $a alone ---
{
    # render: 210 0# $a Fam. her.
    my $field = make_field( '210', '0', '#', a => 'Fam. her.' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'postfix' );
    is( $result[1], 'Fam. her.', '210: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_210, 'prefix' );
    is( $result_pr[1], 'Fam. her.', '210 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '210: combined string identical (just $a)' );
}

# --- 222 Example 1: $a + single $b ---
# Doc: Future:  222 #0 $a Viva $b New York
# Doc: Current: 222 #0 $a Viva $b (New York)
{
    # render: 222 #0 $a Viva $b New York
    my $field = make_field(
        '222', '#', '0',
        a => 'Viva',
        b => 'New York',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'postfix' );
    is( $result[1], 'Viva', '222 example 1 postfix: $a unchanged' );
    is( $result[3], '(New York)', '222 example 1 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'prefix' );
    is( $result_pr[1], 'Viva', '222 example 1 prefix: $a unchanged' );
    is( $result_pr[3], '(New York)', '222 example 1 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '222 example 1: combined string identical' );
}

# --- 222 Example 2: $a + single $b (accented) ---
# Doc: Future:  222 #4 $a Der Öffentliche Dienst $b Köln
# Doc: Current: 222 #4 $a Der Öffentliche Dienst $b (Köln)
{
    # render: 222 #4 $a Der Öffentliche Dienst $b Köln
    my $field = make_field(
        '222', '#', '4',
        a => 'Der Öffentliche Dienst',
        b => 'Köln',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'postfix' );
    is( $result[1], 'Der Öffentliche Dienst',
        '222 example 2 postfix: $a unchanged' );
    is( $result[3], '(Köln)', '222 example 2 postfix: $b wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'prefix' );
    is( $result_pr[1], 'Der Öffentliche Dienst',
        '222 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(Köln)', '222 example 2 prefix: $b wrapped in ()' );

    check_combined( \@result, \@result_pr,
        '222 example 2: combined string identical' );
}

# --- 222 Example 3: $a + two $b (multiple qualifiers, '. ' separator) ---
# Doc: Future:  222 #0 $a Family herald $b Montreal $b 1859
# Doc: Current: 222 #0 $a Family herald $b (Montreal. 1859)
{
    # render: 222 #0 $a Family herald $b Montreal $b 1859
    my $field = make_field(
        '222', '#', '0',
        a => 'Family herald',
        b => 'Montreal',
        b => '1859',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'postfix' );
    is( $result[1], 'Family herald', '222 example 3 postfix: $a unchanged' );
    is( $result[3], '(Montreal',
        '222 example 3 postfix: first $b opens the paren' );
    is( $result[5], '. 1859)',
        '222 example 3 postfix: second $b gets ". " + close paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'prefix' );
    is( $result_pr[1], 'Family herald', '222 example 3 prefix: $a unchanged' );
    is( $result_pr[3], '(Montreal',
        '222 example 3 prefix: first $b opens the paren' );
    is( $result_pr[5], '. 1859)',
        '222 example 3 prefix: second $b gets ". " + close paren' );

    check_combined( \@result, \@result_pr,
        '222 example 3: combined string identical' );
}

# --- 222 Edge: $a alone ---
{
    # render: 222 #0 $a Viva
    my $field = make_field( '222', '#', '0', a => 'Viva' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'postfix' );
    is( $result[1], 'Viva', '222: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_222, 'prefix' );
    is( $result_pr[1], 'Viva', '222 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr,
        '222: combined string identical (just $a)' );
}

done_testing();
