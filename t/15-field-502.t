#
# Regression tests for Field 502 derived from isbdmarc2016.pdf Current/Future examples.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules_502 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{502};
ok( defined $rules_502, '502 rules loaded' );

# --- Example 1: $b + $c + $d ---
# Doc: Future:  502 ## $b M.A. $c University College, London $d 1969
# Doc: Current: 502 ## $a Thesis (M.A.)--University College, London, 1969.
{
    # render: 502 ## $b M.A. $c University College, London $d 1969
    my $field = make_field(
        '502', ' ', ' ',
        b => 'M.A.',
        c => 'University College, London',
        d => '1969',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'postfix' );
    is( $result[1], '(M.A.) -- ',
        '502 example 1 postfix: $b wrapped in () and gets " -- " for $c' );
    is(
        $result[3],
        'University College, London, ',
        '502 example 1 postfix: $c gets ", " for $d'
    );
    is( $result[5], '1969', '502 example 1 postfix: $d unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'prefix' );
    is( $result_pr[1], '(M.A.)',
        '502 example 1 prefix: $b wrapped in () only' );
    is(
        $result_pr[3],
        ' -- University College, London',
        '502 example 1 prefix: $c gets " -- " prepended'
    );
    is( $result_pr[5], ', 1969',
        '502 example 1 prefix: $d gets ", " prepended' );

    is(
        join( '', @result[ 1, 3, 5 ] ),
        join( '', @result_pr[ 1, 3, 5 ] ),
        '502 example 1: combined string identical'
    );
}

# --- Example 2: $b + $c + $d (Ph. D.) ---
# Doc: Future:  502 ## $b Ph. D. $c Ohio State University $d 2008
# Doc: Current: 502 ## $a Thesis (Ph. D.)--Ohio State University, 2008.
{
    # render: 502 ## $b Ph. D. $c Ohio State University $d 2008
    my $field = make_field(
        '502', ' ', ' ',
        b => 'Ph. D.',
        c => 'Ohio State University',
        d => '2008',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'postfix' );
    is( $result[1], '(Ph. D.) -- ',
        '502 example 2 postfix: $b wrapped in () and gets " -- " for $c' );
    is(
        $result[3],
        'Ohio State University, ',
        '502 example 2 postfix: $c gets ", " for $d'
    );
    is( $result[5], '2008', '502 example 2 postfix: $d unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'prefix' );
    is( $result_pr[1], '(Ph. D.)',
        '502 example 2 prefix: $b wrapped in () only' );
    is(
        $result_pr[3],
        ' -- Ohio State University',
        '502 example 2 prefix: $c gets " -- " prepended'
    );
    is( $result_pr[5], ', 2008',
        '502 example 2 prefix: $d gets ", " prepended' );

    is(
        join( '', @result[ 1, 3, 5 ] ),
        join( '', @result_pr[ 1, 3, 5 ] ),
        '502 example 2: combined string identical'
    );
}

# --- Example 3: $b + $c + $d (already in subfields with punct) ---
# Doc: Future:  502 ## $b Ph. D. $c University of Louisville $d 1997
# Doc: Current: 502 ## $b (Ph. D.)-- $c University of Louisville, $d 1997.
{
    # render: 502 ## $b Ph. D. $c University of Louisville $d 1997
    my $field = make_field(
        '502', ' ', ' ',
        b => 'Ph. D.',
        c => 'University of Louisville',
        d => '1997',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'postfix' );
    is( $result[1], '(Ph. D.) -- ',
        '502 example 3 postfix: $b wrapped in () and gets " -- " for $c' );
    is(
        $result[3],
        'University of Louisville, ',
        '502 example 3 postfix: $c gets ", " for $d'
    );
    is( $result[5], '1997', '502 example 3 postfix: $d unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'prefix' );
    is( $result_pr[1], '(Ph. D.)',
        '502 example 3 prefix: $b wrapped in () only' );
    is(
        $result_pr[3],
        ' -- University of Louisville',
        '502 example 3 prefix: $c gets " -- " prepended'
    );
    is( $result_pr[5], ', 1997',
        '502 example 3 prefix: $d gets ", " prepended' );

    is(
        join( '', @result[ 1, 3, 5 ] ),
        join( '', @result_pr[ 1, 3, 5 ] ),
        '502 example 3: combined string identical'
    );
}

# --- Edge case: $b only, no $c or $d ---
{
    # render: 502 ## $b M.A.
    my $field = make_field( '502', ' ', ' ', b => 'M.A.', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'postfix' );
    is( $result[1], '(M.A.)', '502: $b alone wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'prefix' );
    is( $result_pr[1], '(M.A.)', '502 prefix: $b alone wrapped in ()' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '502: combined string identical (just $b)'
    );
}

# --- Edge case: $c only (unusual but valid) ---
{
    # render: 502 ## $c Some University
    my $field = make_field( '502', ' ', ' ', c => 'Some University', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'postfix' );
    is( $result[1], 'Some University', '502: $c alone unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_502, 'prefix' );
    is( $result_pr[1], 'Some University', '502 prefix: $c alone unchanged' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '502: combined string identical (just $c)'
    );
}

done_testing();
