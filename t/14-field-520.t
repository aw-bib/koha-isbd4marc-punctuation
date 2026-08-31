#
# Regression tests for Field 520 derived from isbdmarc2016.pdf Current/Future examples.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules_520 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{520};
ok( defined $rules_520, '520 rules loaded' );

# --- Example 1: $a + $z (preceding dash) ---
# Doc: Future:  520 ## $a Papers "originally commissioned as course material for a series of continuing legal education seminars" $z Pref., v. 1
# Doc: Current: 520 ## $a Papers "originally commissioned as course material for a series of continuing legal education seminars"--Pref., v. 1.
{
    # render: 520 ## $a Papers "originally commissioned as course material for a series of continuing legal education seminars" $z Pref., v. 1
    my $field = make_field(
        '520', ' ', ' ',
        a =>
'Papers "originally commissioned as course material for a series of continuing legal education seminars"',
        z => 'Pref., v. 1',
    );

# Postfix mode: $a gets " -- " appended (look-ahead to $z), $z is last sf so unchanged
    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'postfix' );
    is(
        $result[1],
'Papers "originally commissioned as course material for a series of continuing legal education seminars" -- ',
        '520 example 1 postfix: $a gets " -- " appended'
    );
    is( $result[3], 'Pref., v. 1',
        '520 example 1 postfix: $z unchanged (last sf)' );

    # Prefix mode: $a unchanged, $z gets " -- " prepended
    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'prefix' );
    is(
        $result_pr[1],
'Papers "originally commissioned as course material for a series of continuing legal education seminars"',
        '520 example 1 prefix: $a unchanged'
    );
    is(
        $result_pr[3],
        ' -- Pref., v. 1',
        '520 example 1 prefix: $z gets " -- " prepended'
    );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '520 example 1: combined string identical'
    );
}

# --- Example 2: $a + $z (preceding dash, multi-word source) ---
# Doc: Future:  520 1# $a "Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production" $z Cf. Video rating guide for libraries, winter 1990
# Doc: Current: 520 1# $a "Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production"--Cf. Video rating guide for libraries, winter 1990.
{
    # render: 520 1# $a "Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production" $z Cf. Video rating guide for libraries, winter 1990
    my $field = make_field(
        '520', '1', '#',
        a =>
'"Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production"',
        z => 'Cf. Video rating guide for libraries, winter 1990',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'postfix' );
    is(
        $result[1],
'"Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production" -- ',
        '520 example 2 postfix: $a gets " -- " appended'
    );
    is(
        $result[3],
        'Cf. Video rating guide for libraries, winter 1990',
        '520 example 2 postfix: $z unchanged (last sf)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'prefix' );
    is(
        $result_pr[1],
'"Combines the most frequently asked questions regarding AIDS with the most prominent US physician, former Surgeon General C. Everett Koop, resulting in an informative 38-minute production"',
        '520 example 2 prefix: $a unchanged'
    );
    is(
        $result_pr[3],
        ' -- Cf. Video rating guide for libraries, winter 1990',
        '520 example 2 prefix: $z gets " -- " prepended'
    );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '520 example 2: combined string identical'
    );
}

# --- Edge case: $a only, no $z ---
{
    # render: 520 ## $a Just a summary with no source note
    my $field =
      make_field( '520', ' ', ' ', a => 'Just a summary with no source note', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'postfix' );
    is(
        $result[1],
        'Just a summary with no source note',
        '520: $a alone unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'prefix' );
    is(
        $result_pr[1],
        'Just a summary with no source note',
        '520 prefix: $a alone unchanged'
    );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '520: combined string identical (no $z)'
    );
}

# --- Edge case: $z only (unusual but valid) ---
{
    # render: 520 ## $z Source only
    my $field = make_field( '520', ' ', ' ', z => 'Source only', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'postfix' );
    is( $result[1], 'Source only',
        '520: $z alone unchanged (no preceding $a)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_520, 'prefix' );
    is( $result_pr[1], 'Source only', '520 prefix: $z alone unchanged' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '520: combined string identical (just $z)'
    );
}

done_testing();
