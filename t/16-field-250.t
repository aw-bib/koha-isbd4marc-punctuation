#
# Tests for Field 250 derived from isbdmarc2016.pdf Current/Future examples.

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

my $rules_250 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{250};
ok( defined $rules_250, '250 rules loaded' );

# --- Example 1: $a + $r (parallel edition) ---
# Doc: Current: 250 ## $a Canadian ed. = Éd. canadienne.
{
    # render: [doc §4.9] 250 ## $a Canadian ed. $r Éd. canadienne
    my $field = make_field(
        '250', ' ', ' ',
        a => 'Canadian ed.',
        r => 'Éd. canadienne',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is(
        $result[1],
        'Canadian ed. = ',
        '250 example 1 postfix: $a gets " = " for $r'
    );
    is(
        $result[3],
        'Éd. canadienne',
        '250 example 1 postfix: $r unchanged (last sf)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], 'Canadian ed.', '250 example 1 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' = Éd. canadienne',
        '250 example 1 prefix: $r gets " = " prepended'
    );

    check_combined( \@result, \@result_pr, '250 example 1: combined string identical' );
}

# --- Example 2: $a + $c (statement of responsibility) ---
# Doc: Current: 250 ## $a 3rd draft / $b edited by Paul Watson.
{
    # render: [doc §4.9] 250 ## $a 3rd draft $c edited by Paul Watson
    my $field = make_field(
        '250', ' ', ' ',
        a => '3rd draft',
        c => 'edited by Paul Watson',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is( $result[1], '3rd draft / ',
        '250 example 2 postfix: $a gets " / " for $c' );
    is(
        $result[3],
        'edited by Paul Watson',
        '250 example 2 postfix: $c unchanged (last sf)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], '3rd draft', '250 example 2 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' / edited by Paul Watson',
        '250 example 2 prefix: $c gets " / " prepended'
    );

    check_combined( \@result, \@result_pr, '250 example 2: combined string identical' );
}

# --- Example 3: $a + $c (edition with reviser) ---
# Doc: Current: 250 ## $a 4th ed. / $b revised by J.G. Le Mesurier and E. McIntosh.
{
    # render: [doc §4.9] 250 ## $a 4th ed. $c revised by J.G. Le Mesurier and E. McIntosh
    my $field = make_field(
        '250', ' ', ' ',
        a => '4th ed.',
        c => 'revised by J.G. Le Mesurier and E. McIntosh',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is( $result[1], '4th ed. / ',
        '250 example 3 postfix: $a gets " / " for $c' );
    is(
        $result[3],
        'revised by J.G. Le Mesurier and E. McIntosh',
        '250 example 3 postfix: $c unchanged (last sf)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], '4th ed.', '250 example 3 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' / revised by J.G. Le Mesurier and E. McIntosh',
        '250 example 3 prefix: $c gets " / " prepended'
    );

    check_combined( \@result, \@result_pr, '250 example 3: combined string identical' );
}

# --- Example 4: $a + $c (edition with revisions note) ---
# Doc: Current: 250 ## $a Rev. ed. / $b with revisions, an introduction, and a chapter on writing by E.B. White.
{
    # render: [doc §4.9] 250 ## $a Rev. ed. $c with revisions, an introduction, and a chapter on writing by E.B. White
    my $field = make_field(
        '250', ' ', ' ',
        a => 'Rev. ed.',
        c =>
'with revisions, an introduction, and a chapter on writing by E.B. White',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is( $result[1], 'Rev. ed. / ',
        '250 example 4 postfix: $a gets " / " for $c' );
    is(
        $result[3],
'with revisions, an introduction, and a chapter on writing by E.B. White',
        '250 example 4 postfix: $c unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], 'Rev. ed.', '250 example 4 prefix: $a unchanged' );
    is(
        $result_pr[3],
' / with revisions, an introduction, and a chapter on writing by E.B. White',
        '250 example 4 prefix: $c gets " / " prepended'
    );

    check_combined( \@result, \@result_pr, '250 example 4: combined string identical' );
}

# --- Edge case: $a alone ---
{
    # render: 250 ## $a 2nd ed.
    my $field = make_field( '250', ' ', ' ', a => '2nd ed.', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is( $result[1], '2nd ed.', '250: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], '2nd ed.', '250 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '250: combined string identical (just $a)' );
}

# --- Edge case: $a + $c + $d (responsibility + subsequent responsibility) ---
# Not directly from doc examples, but tests the $c->$d chain
{
    # render: 250 ## $a 2nd ed. $c revised by John Smith $d with a foreword by Jane Doe
    my $field = make_field(
        '250', ' ', ' ',
        a => '2nd ed.',
        c => 'revised by John Smith',
        d => 'with a foreword by Jane Doe',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'postfix' );
    is( $result[1], '2nd ed. / ',               '250: $a gets " / " for $c' );
    is( $result[3], 'revised by John Smith ; ', '250: $c gets " ; " for $d' );
    is(
        $result[5],
        'with a foreword by Jane Doe',
        '250: $d unchanged (last sf)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_250, 'prefix' );
    is( $result_pr[1], '2nd ed.', '250 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' / revised by John Smith',
        '250 prefix: $c gets " / " prepended'
    );
    is(
        $result_pr[5],
        ' ; with a foreword by Jane Doe',
        '250 prefix: $d gets " ; " prepended'
    );

    check_combined( \@result, \@result_pr, '250: combined string identical ($a+$c+$d)' );
}

done_testing();
