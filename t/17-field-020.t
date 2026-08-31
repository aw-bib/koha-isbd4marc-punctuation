#
# Tests for Field 020 derived from isbdmarc2016.pdf Current/Future examples.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules_020 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{'020'};
ok( defined $rules_020, '020 rules loaded' );

# --- Example 1: $a + $q (single qualifying info) ---
# Doc: Future:  020 ## $a 9780060723804 $q acid-free paper
# Doc: Current: 020 ## $a 9780060723804 $q (acid-free paper)
{
    # render: 020 ## $a 9780060723804 $q acid-free paper
    my $field = make_field(
        '020', ' ', ' ',
        a => '9780060723804',
        q => 'acid-free paper',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'postfix' );
    is( $result[1], '9780060723804', '020 example 1 postfix: $a unchanged' );
    is(
        $result[3],
        '(acid-free paper)',
        '020 example 1 postfix: $q wrapped in ()'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'prefix' );
    is( $result_pr[1], '9780060723804', '020 example 1 prefix: $a unchanged' );
    is(
        $result_pr[3],
        '(acid-free paper)',
        '020 example 1 prefix: $q wrapped in ()'
    );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '020 example 1: combined string identical'
    );
}

# --- Example 2: $a + $q (single qualifying info, trade) ---
# Doc: Future:  020 ## $a 9780060799748 $q trade
# Doc: Current: 020 ## $a 9780060799748 $q (trade)
{
    # render: 020 ## $a 9780060799748 $q trade
    my $field = make_field(
        '020', ' ', ' ',
        a => '9780060799748',
        q => 'trade',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'postfix' );
    is( $result[1], '9780060799748', '020 example 2 postfix: $a unchanged' );
    is( $result[3], '(trade)', '020 example 2 postfix: $q wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'prefix' );
    is( $result_pr[1], '9780060799748', '020 example 2 prefix: $a unchanged' );
    is( $result_pr[3], '(trade)', '020 example 2 prefix: $q wrapped in ()' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '020 example 2: combined string identical'
    );
}

# --- Example 3: $a + $q + $c (qualifying info + terms of availability) ---
# Doc: Future:  020 ## $a 0717941728 $q folded $c $0.45
# Doc: Current: 020 ## $a 0717941728 $q (folded) : $c $0.45
{
    # render: 020 ## $a 0717941728 $q folded $c \$0.45
    my $field = make_field(
        '020', ' ', ' ',
        a => '0717941728',
        q => 'folded',
        c => '$0.45',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'postfix' );
    is( $result[1], '0717941728', '020 example 3 postfix: $a unchanged' );
    is( $result[3], '(folded) : ',
        '020 example 3 postfix: $q wrapped in () and gets " : " for $c' );
    is( $result[5], '$0.45', '020 example 3 postfix: $c unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'prefix' );
    is( $result_pr[1], '0717941728', '020 example 3 prefix: $a unchanged' );
    is( $result_pr[3], '(folded)',   '020 example 3 prefix: $q wrapped in ()' );
    is( $result_pr[5], ' : $0.45',
        '020 example 3 prefix: $c gets " : " prepended' );

    is(
        join( '', @result[ 1, 3, 5 ] ),
        join( '', @result_pr[ 1, 3, 5 ] ),
        '020 example 3: combined string identical'
    );
}

# --- Example 4: $a + $q + $q + $c (two qualifying infos + terms) ---
# Doc: Future:  020 ## $a 0914378260 $q pbk. $q v. 1 $c $5.00
# Doc: Current: 020 ## $a 0914378260 $q (pbk. ; $q v. 1) : $c $5.00
{
    # render: 020 ## $a 0914378260 $q pbk. $q v. 1 $c \$5.00
    my $field = make_field(
        '020', ' ', ' ',
        a => '0914378260',
        q => 'pbk.',
        q => 'v. 1',
        c => '$5.00',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'postfix' );
    is( $result[1], '0914378260', '020 example 4 postfix: $a unchanged' );
    is( $result[3], '(pbk.', '020 example 4 postfix: first $q opens paren' );
    is(
        $result[5],
        ' ; v. 1) : ',
'020 example 4 postfix: second $q gets " ; " + close paren + " : " for $c'
    );
    is( $result[7], '$5.00', '020 example 4 postfix: $c unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'prefix' );
    is( $result_pr[1], '0914378260', '020 example 4 prefix: $a unchanged' );
    is( $result_pr[3], '(pbk.', '020 example 4 prefix: first $q opens paren' );
    is( $result_pr[5], ' ; v. 1)',
        '020 example 4 prefix: second $q gets " ; " + close paren' );
    is( $result_pr[7], ' : $5.00',
        '020 example 4 prefix: $c gets " : " prepended' );

    is(
        join( '', @result[ 1, 3, 5, 7 ] ),
        join( '', @result_pr[ 1, 3, 5, 7 ] ),
        '020 example 4: combined string identical'
    );
}

# --- Edge case: $a alone ---
{
    # render: 020 ## $a 9780060723804
    my $field = make_field( '020', ' ', ' ', a => '9780060723804', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'postfix' );
    is( $result[1], '9780060723804', '020: $a alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_020, 'prefix' );
    is( $result_pr[1], '9780060723804', '020 prefix: $a alone unchanged' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '020: combined string identical (just $a)'
    );
}

done_testing();
