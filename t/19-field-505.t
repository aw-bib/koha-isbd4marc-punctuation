#
# Tests for Field 505 - Formatted Contents Note
# Derived from isbdmarc2016.pdf Current/Future examples.
#
# Simple approach: pchrs for $t ( -- ) and $r ( / ), wrap for $g (()).
# $t/$g get " -- " before $n via the COMPOUND pchrs keys tn/gn.
# Note: $i (display text) ends with ': ' via cb_pre.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules_505 = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{505};
ok( defined $rules_505, '505 rules loaded' );

# --- Example 1: Multiple $t (basic contents) ---
# Doc: Future:  505 00 $t Future land use plan $t Recommended capital improvements $t Existing land use $t Existing zoning
# Doc: Current: 505 0# $a Future land use plan -- Recommended capital improvements -- Existing land use -- Existing zoning.
# Note: doc shows $a in current, but subfields are reconstructed as $t in future.
# We test the $t-based future form reconstruction.
{
    # render: 505 00 $t Future land use plan $t Recommended capital improvements $t Existing land use $t Existing zoning
    my $field = make_field(
        '505', '0', '0',
        t => 'Future land use plan',
        t => 'Recommended capital improvements',
        t => 'Existing land use',
        t => 'Existing zoning',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
        'Future land use plan -- ',
        '505 ex1 postfix: first $t gets " -- " when second $t follows'
    );
    is(
        $result[3],
        'Recommended capital improvements -- ',
        '505 ex1 postfix: second $t gets " -- " when third $t follows'
    );
    is(
        $result[5],
        'Existing land use -- ',
        '505 ex1 postfix: third $t gets " -- " when fourth $t follows'
    );
    is(
        $result[7],
        'Existing zoning',
        '505 ex1 postfix: fourth $t (last) unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is(
        $result_pr[1],
        'Future land use plan',
        '505 ex1 prefix: first $t unchanged'
    );
    is(
        $result_pr[3],
        ' -- Recommended capital improvements',
        '505 ex1 prefix: second $t gets " -- " prepended'
    );
    is(
        $result_pr[5],
        ' -- Existing land use',
        '505 ex1 prefix: third $t gets " -- " prepended'
    );
    is(
        $result_pr[7],
        ' -- Existing zoning',
        '505 ex1 prefix: fourth $t gets " -- " prepended'
    );

    is(
        join( '', @result[ 1, 3, 5, 7 ] ),
        join( '', @result_pr[ 1, 3, 5, 7 ] ),
        '505 ex1: combined string identical'
    );
}

# --- Example 2: Multiple $t (area titles, same pattern) ---
{
    # render: 505 00 $t Area 1, Lone Pine to Big Pine $t Area 2, Bishop to Mammoth Lakes $t Area 3, June Lake to Bridgeport $t Area 4, White Mountains area
    my $field = make_field(
        '505', '0', '0',
        t => 'Area 1, Lone Pine to Big Pine',
        t => 'Area 2, Bishop to Mammoth Lakes',
        t => 'Area 3, June Lake to Bridgeport',
        t => 'Area 4, White Mountains area',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
        'Area 1, Lone Pine to Big Pine -- ',
        '505 ex2 postfix: first $t gets " -- "'
    );
    is(
        $result[3],
        'Area 2, Bishop to Mammoth Lakes -- ',
        '505 ex2 postfix: second $t gets " -- "'
    );
    is(
        $result[5],
        'Area 3, June Lake to Bridgeport -- ',
        '505 ex2 postfix: third $t gets " -- "'
    );
    is(
        $result[7],
        'Area 4, White Mountains area',
        '505 ex2 postfix: fourth $t (last) unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is(
        $result_pr[1],
        'Area 1, Lone Pine to Big Pine',
        '505 ex2 prefix: first $t unchanged'
    );
    is(
        $result_pr[3],
        ' -- Area 2, Bishop to Mammoth Lakes',
        '505 ex2 prefix: second $t gets " -- "'
    );
    is(
        $result_pr[5],
        ' -- Area 3, June Lake to Bridgeport',
        '505 ex2 prefix: third $t gets " -- "'
    );
    is(
        $result_pr[7],
        ' -- Area 4, White Mountains area',
        '505 ex2 prefix: fourth $t gets " -- "'
    );

    is(
        join( '', @result[ 1, 3, 5, 7 ] ),
        join( '', @result_pr[ 1, 3, 5, 7 ] ),
        '505 ex2: combined string identical'
    );
}

# --- Example 3: $t + $g + $t + $g (enhanced, with timings) ---
# Doc: Future:  505 00 $t Quatrain II $g 16:35 $t Water ways $g 1:57 $t Waves $g 10:49
# Doc: Current: 505 00 $t Quatrain II (16:35) -- $t Water ways (1:57) -- $t Waves (10:49).
{
    # render: 505 00 $t Quatrain II $g 16:35 $t Water ways $g 1:57 $t Waves $g 10:49
    my $field = make_field(
        '505', '0', '0',
        t => 'Quatrain II',
        g => '16:35',
        t => 'Water ways',
        g => '1:57',
        t => 'Waves',
        g => '10:49',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1], 'Quatrain II',
        '505 ex3 postfix: $t unchanged (next is $g, no pchrs for g)' );
    is(
        $result[3],
        '(16:35) -- ',
        '505 ex3 postfix: $g wrapped in () and gets " -- " when next $t follows'
    );
    is( $result[5], 'Water ways', '505 ex3 postfix: second $t unchanged' );
    is( $result[7], '(1:57) -- ',
        '505 ex3 postfix: second $g wrapped in () and gets " -- "' );
    is( $result[9], 'Waves', '505 ex3 postfix: third $t unchanged' );
    is( $result[11], '(10:49)',
        '505 ex3 postfix: third $g wrapped in () (last) no punct' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], 'Quatrain II', '505 ex3 prefix: first $t unchanged' );
    is( $result_pr[3], '(16:35)',
'505 ex3 prefix: first $g wrapped in () only (no preceding sf to get punct)'
    );
    is(
        $result_pr[5],
        ' -- Water ways',
        '505 ex3 prefix: second $t gets " -- " prepended'
    );
    is( $result_pr[7], '(1:57)',
        '505 ex3 prefix: second $g wrapped in () only' );
    is( $result_pr[9], ' -- Waves',
        '505 ex3 prefix: third $t gets " -- " prepended' );
    is( $result_pr[11], '(10:49)',
        '505 ex3 prefix: third $g wrapped in () (last)' );

    is(
        join( '', @result[ 1, 3, 5, 7, 9, 11 ] ),
        join( '', @result_pr[ 1, 3, 5, 7, 9, 11 ] ),
        '505 ex3: combined string identical'
    );
}

# --- Example 4: $t + $t + $t + $r (titles with statement of responsibility) ---
# Doc: Future:  505 20 $t Baptisms, 1816-1872 $t Church members, 1816-1831 $t History of the Second Presbyterian Church of West Durham $r by L.H. Fellows
# Doc: Current: 505 20 $t Baptisms, 1816-1872 -- $t Church members, 1816-1831 -- $t History of the Second Presbyterian Church of West Durham / $r by L.H. Fellows.
{
    # render: 505 20 $t Baptisms, 1816-1872 $t Church members, 1816-1831 $t History of the Second Presbyterian Church of West Durham $r by L.H. Fellows
    my $field = make_field(
        '505', '2', '0',
        t => 'Baptisms, 1816-1872',
        t => 'Church members, 1816-1831',
        t => 'History of the Second Presbyterian Church of West Durham',
        r => 'by L.H. Fellows',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
        'Baptisms, 1816-1872 -- ',
        '505 ex4 postfix: first $t gets " -- "'
    );
    is(
        $result[3],
        'Church members, 1816-1831 -- ',
        '505 ex4 postfix: second $t gets " -- "'
    );
    is(
        $result[5],
        'History of the Second Presbyterian Church of West Durham / ',
        '505 ex4 postfix: third $t gets " / " when $r follows'
    );
    is( $result[7], 'by L.H. Fellows', '505 ex4 postfix: $r (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is(
        $result_pr[1],
        'Baptisms, 1816-1872',
        '505 ex4 prefix: first $t unchanged'
    );
    is(
        $result_pr[3],
        ' -- Church members, 1816-1831',
        '505 ex4 prefix: second $t gets " -- " prepended'
    );
    is(
        $result_pr[5],
        ' -- History of the Second Presbyterian Church of West Durham',
        '505 ex4 prefix: third $t gets " -- " prepended'
    );
    is(
        $result_pr[7],
        ' / by L.H. Fellows',
        '505 ex4 prefix: $r gets " / " prepended'
    );

    is(
        join( '', @result[ 1, 3, 5, 7 ] ),
        join( '', @result_pr[ 1, 3, 5, 7 ] ),
        '505 ex4: combined string identical'
    );
}

# --- Standard: $t alone ---
{
    # render: 505 00 $t Single title
    my $field = make_field( '505', '0', '0', t => 'Single title', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1], 'Single title', '505 edge $t alone postfix: unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], 'Single title', '505 edge $t alone prefix: unchanged' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '505 edge $t alone: combined string identical'
    );
}

# --- Edge case: $g alone ---
{
    # render: 505 00 $g 16:35
    my $field = make_field( '505', '0', '0', g => '16:35', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1], '(16:35)', '505 edge $g alone postfix: wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], '(16:35)', '505 edge $g alone prefix: wrapped in ()' );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '505 edge $g alone: combined string identical'
    );
}

# --- Edge case: $a alone (basic format, second indicator #) ---
# $a has no ISBD punctuation rules
{
    # render: 505 0# $a Future land use plan -- Recommended capital improvements -- Existing land use -- Existing zoning
    my $field = make_field( '505', '0', '#',
        a =>
'Future land use plan -- Recommended capital improvements -- Existing land use -- Existing zoning',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
'Future land use plan -- Recommended capital improvements -- Existing land use -- Existing zoning',
        '505 edge $a alone postfix: unchanged (no rules for $a)'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is(
        $result_pr[1],
'Future land use plan -- Recommended capital improvements -- Existing land use -- Existing zoning',
        '505 edge $a alone prefix: unchanged'
    );

    is(
        join( '', $result[1] ),
        join( '', $result_pr[1] ),
        '505 edge $a alone: combined string identical'
    );
}

# --- Edge case: $t + $r (single title with responsibility) ---
{
    # render: 505 20 $t Quark models $r J. Rosner
    my $field = make_field(
        '505', '2', '0',
        t => 'Quark models',
        r => 'J. Rosner',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
        'Quark models / ',
        '505 edge $t+$r postfix: $t gets " / " when $r follows'
    );
    is( $result[3], 'J. Rosner',
        '505 edge $t+$r postfix: $r (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], 'Quark models', '505 edge $t+$r prefix: $t unchanged' );
    is( $result_pr[3], ' / J. Rosner',
        '505 edge $t+$r prefix: $r gets " / " prepended' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '505 edge $t+$r: combined string identical'
    );
}

# --- Edge case: $g + $t (misc info followed by title, no preceding punct on $g) ---
{
    # render: 505 10 $g 16:35 $t Waves
    my $field = make_field(
        '505', '1', '0',
        g => '16:35',
        t => 'Waves',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is(
        $result[1],
        '(16:35) -- ',
'505 edge $g+$t postfix: $g wrapped in () and gets " -- " when $t follows'
    );
    is( $result[3], 'Waves', '505 edge $g+$t postfix: $t (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], '(16:35)', '505 edge $g+$t prefix: $g wrapped in ()' );
    is( $result_pr[3], ' -- Waves',
        '505 edge $g+$t prefix: $t gets " -- " prepended' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '505 edge $g+$t: combined string identical'
    );
}

# --- Doc Example 5: $n + $t (part designation with titles) ---
# Doc: Future:  505 10 $n Nr. 1 $t Region Neusiedlersee $n Nr. 2 $t Region Rosalia/Lithagebirge ...
# Doc: Current: 505 10 $g Nr. 1. $t Region Neusiedlersee -- $g Nr. 2. $t Region Rosalia/Lithagebirge ...
# Note: In the Future form, $n replaces $g for part designations.
# $n gets -- when $t follows (via pchrs t => ' -- ').
# $t gets -- when $n follows (via COMPOUND pchrs key tn, the precise fix
#   that avoids firing on $i).
# Combined string: "Nr. 1 -- Region Neusiedlersee -- Nr. 2 -- ..."
{
    # render: 505 10 $n Nr. 1 $t Region Neusiedlersee $n Nr. 2 $t Region Rosalia/Lithagebirge $n Nr. 3 $t Region Mettelburgenland $n Nr. 4 $t Region s\u00fcdliches Burgenland $n Nr. 5 $t Region S\u00fcdburgland
    my $field = make_field(
        '505', '1', '0',
        n => 'Nr. 1',
        t => 'Region Neusiedlersee',
        n => 'Nr. 2',
        t => 'Region Rosalia/Lithagebirge',
        n => 'Nr. 3',
        t => 'Region Mettelburgenland',
        n => 'Nr. 4',
        t => 'Region s\u00fcdliches Burgenland',
        n => 'Nr. 5',
        t => 'Region S\u00fcdburgland',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1],  'Nr. 1 -- ',
        '505 ex5 postfix: $n gets " -- " when $t follows' );
    is( $result[3],  'Region Neusiedlersee -- ',
        '505 ex5 postfix: $t gets " -- " when $n follows' );
    is( $result[5],  'Nr. 2 -- ',
        '505 ex5 postfix: second $n gets " -- " when $t follows' );
    is( $result[7],  'Region Rosalia/Lithagebirge -- ',
        '505 ex5 postfix: second $t gets " -- " when $n follows' );
    is( $result[9],  'Nr. 3 -- ',
        '505 ex5 postfix: third $n gets " -- "' );
    is( $result[11], 'Region Mettelburgenland -- ',
        '505 ex5 postfix: third $t gets " -- "' );
    is( $result[13], 'Nr. 4 -- ',
        '505 ex5 postfix: fourth $n gets " -- "' );
    is( $result[15], 'Region s\u00fcdliches Burgenland -- ',
        '505 ex5 postfix: fourth $t gets " -- "' );
    is( $result[17], 'Nr. 5 -- ',
        '505 ex5 postfix: fifth $n gets " -- " when $t follows' );
    is( $result[19], 'Region S\u00fcdburgland',
        '505 ex5 postfix: fifth $t (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1],  'Nr. 1',
        '505 ex5 prefix: first $n clean (no preceding sf)' );
    is( $result_pr[3],  ' -- Region Neusiedlersee',
        '505 ex5 prefix: $t gets " -- " prepended (pending from $n, single key t)' );
    is( $result_pr[5],  ' -- Nr. 2',
        '505 ex5 prefix: $n gets " -- " prepended (pending from $t via compound tn)' );
    is( $result_pr[7],  ' -- Region Rosalia/Lithagebirge',
        '505 ex5 prefix: next $t gets " -- " prepended (pending from $n)' );
    is( $result_pr[9],  ' -- Nr. 3',
        '505 ex5 prefix: $n gets " -- " prepended (compound tn)' );
    is( $result_pr[11], ' -- Region Mettelburgenland',
        '505 ex5 prefix: $t gets " -- " prepended' );
    is( $result_pr[13], ' -- Nr. 4',
        '505 ex5 prefix: $n gets " -- " prepended (compound tn)' );
    is( $result_pr[15], ' -- Region s\u00fcdliches Burgenland',
        '505 ex5 prefix: $t gets " -- " prepended' );
    is( $result_pr[17], ' -- Nr. 5',
        '505 ex5 prefix: $n gets " -- " prepended (compound tn)' );
    is( $result_pr[19], ' -- Region S\u00fcdburgland',
        '505 ex5 prefix: last $t gets " -- " prepended (pending from $n)' );

    is(
        join( '', @result[ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19 ] ),
        join( '', @result_pr[ 1, 3, 5, 7, 9, 11, 13, 15, 17, 19 ] ),
        '505 ex5: combined string identical'
    );
}

# --- Doc Example 6: $i + $n + $t (display text with part designation and title) ---
# Doc: Future:  505 00 $i Contents of disc 1 $n Episode 1 $t The last of the free $n Episode 2 $t Hammers of the Scots $n Episode 3 $t Bishop makes kings
# Doc: Current: 505 0# $a Contents of disc 1: Episode 1. The last of the free -- Episode 2. Hammers of the Scots -- Episode 3. Bishop makes kings.
# $i gets ": " via cb_pre. $n gets " -- " when $t follows (pchrs t). $t gets " -- " when $n follows (COMPOUND key tn).
{
    # render: 505 00 $i Contents of disc 1 $n Episode 1 $t The last of the free $n Episode 2 $t Hammers of the Scots $n Episode 3 $t Bishop makes kings
    my $field = make_field(
        '505', '0', '0',
        i => 'Contents of disc 1',
        n => 'Episode 1',
        t => 'The last of the free',
        n => 'Episode 2',
        t => 'Hammers of the Scots',
        n => 'Episode 3',
        t => 'Bishop makes kings',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1],  'Contents of disc 1: ',
        '505 ex6 postfix: $i gets ": " via cb_pre, no pchrs for $i' );
    is( $result[3],  'Episode 1 -- ',
        '505 ex6 postfix: first $n gets " -- " when $t follows' );
    is( $result[5],  'The last of the free -- ',
        '505 ex6 postfix: first $t gets " -- " when $n follows' );
    is( $result[7],  'Episode 2 -- ',
        '505 ex6 postfix: second $n gets " -- " when $t follows' );
    is( $result[9],  'Hammers of the Scots -- ',
        '505 ex6 postfix: second $t gets " -- " when $n follows' );
    is( $result[11], 'Episode 3 -- ',
        '505 ex6 postfix: third $n gets " -- " when $t follows' );
    is( $result[13], 'Bishop makes kings',
        '505 ex6 postfix: third $t (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1],  'Contents of disc 1: ',
        '505 ex6 prefix: $i gets ": " via cb_pre (no pchrs pending from $i)' );
    is( $result_pr[3],  'Episode 1',
        '505 ex6 prefix: first $n unchanged (no pending — $i does not generate pchrs)' );
    is( $result_pr[5],  ' -- The last of the free',
        '505 ex6 prefix: $t gets " -- " prepended (pending from $n, single key t)' );
    is( $result_pr[7],  ' -- Episode 2',
        '505 ex6 prefix: $n gets " -- " prepended (pending from $t via compound tn)' );
    is( $result_pr[9],  ' -- Hammers of the Scots',
        '505 ex6 prefix: $t gets " -- " prepended (pending from $n)' );
    is( $result_pr[11], ' -- Episode 3',
        '505 ex6 prefix: $n gets " -- " prepended (compound tn)' );
    is( $result_pr[13], ' -- Bishop makes kings',
        '505 ex6 prefix: last $t gets " -- " prepended (pending from $n)' );

    is(
        join( '', @result[ 1, 3, 5, 7, 9, 11, 13 ] ),
        join( '', @result_pr[ 1, 3, 5, 7, 9, 11, 13 ] ),
        '505 ex6: combined string identical'
    );
}

# --- Edge case: $t + $g (title with misc info, no punct between them) ---
{
    # render: 505 00 $t Quatrain II $g 16:35
    my $field = make_field(
        '505', '0', '0',
        t => 'Quatrain II',
        g => '16:35',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'postfix' );
    is( $result[1], 'Quatrain II',
        '505 edge $t+$g postfix: $t unchanged (next is $g, no pchrs for g)' );
    is( $result[3], '(16:35)',
        '505 edge $t+$g postfix: $g wrapped in () (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_505, 'prefix' );
    is( $result_pr[1], 'Quatrain II', '505 edge $t+$g prefix: $t unchanged' );
    is( $result_pr[3], '(16:35)',
        '505 edge $t+$g prefix: $g wrapped in () only' );

    is(
        join( '', @result[ 1, 3 ] ),
        join( '', @result_pr[ 1, 3 ] ),
        '505 edge $t+$g: combined string identical'
    );
}

done_testing();
