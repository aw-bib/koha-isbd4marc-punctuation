#
# PROVENANCE:
#   [doc §3.15] / [doc §3.16]  -> drawn verbatim from the reference doc
#   (no token)                 -> constructed
#
# This file covers 533 (Reproduction Note, §3.15) and 534 (Original Version
# Note, §3.16) - the two fields from the §3.x "Extraction of Punctuation"
# series that were deferred out of Phase 1 (t/29) because they need the
# '.()' period+paren engine pattern (introduced here).
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   533: $b '. ', $c ' : ', $d ', ', $e/$m/$n '. ', $f '.()' (parens), $a N/A
#   534: $b/$c/$e/$k/$l/$m/$n/$o/$t/$x/$z '. ', $f '.()' (parens),
#        $p trailing ': ' (post), $a N/A
#
# ENGINE NOTES (this task):
#   * '.()' sentinel: when $f follows another subfield, append a BARE period
#     to the preceding subfield and wrap $f's content in ( ). The space
#     before '(' comes from the single-space join in combined_string(), NOT
#     from the punctuation itself (so the rendered form is "... 35 mm.
#     (series)"). In prefix mode the period lands OUTSIDE the parens.
#   * colon-skip: a value that already ends in ':' (e.g. 534 $p's trailing
#     ': ' from `post`) never takes a further stacked pchrs.

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

my $R = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);

# --- both fields are defined ---
for my $t ( qw(533 534) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
ok( exists $R->{533}{pchrs}{f}, '533 defines $f via .() sentinel' );
is( $R->{533}{pchrs}{f}, '.()', '533 $f pchrs is the .() sentinel' );
is( $R->{534}{pchrs}{f}, '.()', '534 $f pchrs is the .() sentinel' );
is( $R->{534}{post}{p}, ': ', '534 $p has trailing ": " via post' );

# =====================================================================
# 533 – Reproduction Note (spec §3.15)
# $b . ; $c ' : '; $d ', '; $e/$m/$n '. '; $f '.()'. $a N/A.
# =====================================================================

# --- 533 ex 1 (doc §3.15) ---
# Doc: Current: 533 ## $a Photocopy. $b Seattle, Wash. : $c University of
#   Washington, $d 1979. $e 28 cm.
{
    # render: [doc §3.15] 533 ## $a Photocopy $b Seattle, Wash. $c University of Washington $d 1979 $e 28 cm
    my $field = make_field( '533', ' ', ' ', a => 'Photocopy', b => 'Seattle, Wash.', c => 'University of Washington', d => '1979', e => '28 cm' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'postfix' );
    is( $result[1], 'Photocopy. ',            '533 ex1 postfix: $a gets ". "' );
    is( $result[3], 'Seattle, Wash. : ',       '533 ex1 postfix: $b gets " : "' );
    is( $result[5], 'University of Washington, ', '533 ex1 postfix: $c gets ", "' );
    is( $result[7], '1979. ',                  '533 ex1 postfix: $d gets ". "' );
    is( $result[9], '28 cm',                   '533 ex1 postfix: $e (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'prefix' );
    is( $result_pr[1], 'Photocopy',            '533 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '. Seattle, Wash.',     '533 ex1 prefix: $b gets ". " prepended' );
    is( $result_pr[5], ' : University of Washington', '533 ex1 prefix: $c gets " : " prepended' );
    is( $result_pr[7], ', 1979',               '533 ex1 prefix: $d gets ", " prepended' );
    is( $result_pr[9], '. 28 cm',              '533 ex1 prefix: $e gets ". " prepended' );

    check_combined( \@result, \@result_pr, '533 ex1: combined string identical' );
}

# --- 533 ex 2 (doc §3.15) ---
# Doc: Current: 533 ## $a Microfilm. $m 1962-1965. $b Ann Arbor, Mich. :
#   $c University Microfilms International, $d 1988. $e 1 microfilm reel ;
#   35 mm.
{
    # render: [doc §3.15] 533 ## $a Microfilm $m 1962-1965 $b Ann Arbor, Mich. $c University Microfilms International $d 1988 $e 1 microfilm reel ; 35 mm
    my $field = make_field( '533', ' ', ' ', a => 'Microfilm', m => '1962-1965', b => 'Ann Arbor, Mich.', c => 'University Microfilms International', d => '1988', e => '1 microfilm reel ; 35 mm' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'postfix' );
    is( $result[1], 'Microfilm. ',                '533 ex2 postfix: $a gets ". "' );
    is( $result[3], '1962-1965. ',                '533 ex2 postfix: $m gets ". "' );
    is( $result[5], 'Ann Arbor, Mich. : ',        '533 ex2 postfix: $b gets " : "' );
    is( $result[7], 'University Microfilms International, ', '533 ex2 postfix: $c gets ", "' );
    is( $result[9], '1988. ',                     '533 ex2 postfix: $d gets ". "' );
    is( $result[11], '1 microfilm reel ; 35 mm',  '533 ex2 postfix: $e (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'prefix' );
    is( $result_pr[1], 'Microfilm',               '533 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '. 1962-1965',             '533 ex2 prefix: $m gets ". " prepended' );
    is( $result_pr[5], '. Ann Arbor, Mich.',      '533 ex2 prefix: $b gets ". " prepended' );
    is( $result_pr[7], ' : University Microfilms International', '533 ex2 prefix: $c gets " : " prepended' );
    is( $result_pr[9], ', 1988',                  '533 ex2 prefix: $d gets ", " prepended' );
    is( $result_pr[11], '. 1 microfilm reel ; 35 mm', '533 ex2 prefix: $e gets ". " prepended' );

    check_combined( \@result, \@result_pr, '533 ex2: combined string identical' );
}

# --- 533 ex 3 (doc §3.15) --- the '.()' case for $f
# Doc: Current: 533 ## $a Microfilm. $m July 1919-Nov. 1925. $b Ann Arbor,
#   Mich. : $c University Microfilms, $d 1966?-1980. $e 15 microfilm reels ;
#   35 mm. $f (Current periodical series ; publication no. 2313).
{
    # render: [doc §3.15] 533 ## $a Microfilm $m July 1919-Nov. 1925 $b Ann Arbor, Mich. $c University Microfilms $d 1966?-1980 $e 15 microfilm reels ; 35 mm $f Current periodical series ; publication no. 2313
    my $field = make_field( '533', ' ', ' ', a => 'Microfilm', m => 'July 1919-Nov. 1925', b => 'Ann Arbor, Mich.', c => 'University Microfilms', d => '1966?-1980', e => '15 microfilm reels ; 35 mm', f => 'Current periodical series ; publication no. 2313' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'postfix' );
    is( $result[1], 'Microfilm. ',                '533 ex3 postfix: $a gets ". "' );
    is( $result[3], 'July 1919-Nov. 1925. ',      '533 ex3 postfix: $m gets ". "' );
    is( $result[5], 'Ann Arbor, Mich. : ',        '533 ex3 postfix: $b gets " : "' );
    is( $result[7], 'University Microfilms, ',    '533 ex3 postfix: $c gets ", "' );
    is( $result[9], '1966?-1980. ',               '533 ex3 postfix: $d gets ". "' );
    is( $result[11], '15 microfilm reels ; 35 mm.', '533 ex3 postfix: $e gets "." (from .(), no trailing space)' );
    is( $result[13], '(Current periodical series ; publication no. 2313)', '533 ex3 postfix: $f wrapped in parens' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'prefix' );
    is( $result_pr[1], 'Microfilm',               '533 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '. July 1919-Nov. 1925',   '533 ex3 prefix: $m gets ". " prepended' );
    is( $result_pr[5], '. Ann Arbor, Mich.',      '533 ex3 prefix: $b gets ". " prepended' );
    is( $result_pr[7], ' : University Microfilms', '533 ex3 prefix: $c gets " : " prepended' );
    is( $result_pr[9], ', 1966?-1980',            '533 ex3 prefix: $d gets ", " prepended' );
    is( $result_pr[11], '. 15 microfilm reels ; 35 mm', '533 ex3 prefix: $e gets ". " prepended' );
    is( $result_pr[13], '. (Current periodical series ; publication no. 2313)', '533 ex3 prefix: period OUTSIDE $f parens' );

    check_combined( \@result, \@result_pr, '533 ex3: combined string identical' );
}

# --- 533 edge: $a alone (no punctuation) ---
{
    # render: 533 ## $a Photocopy
    my $field = make_field( '533', ' ', ' ', a => 'Photocopy' );
    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'postfix' );
    is( $result[1], 'Photocopy', '533 $a-alone: unchanged' );
    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'prefix' );
    check_combined( \@result, \@result_pr, '533 $a-alone: combined string identical' );
}

# --- 533 edge: repeatable $f (two series statements) ---
{
    # render: 533 ## $a Microfilm $e reel 1 $f Series A ; v. 1 $f Series B ; v. 2
    my $field = make_field( '533', ' ', ' ', a => 'Microfilm', e => 'reel 1', f => 'Series A ; v. 1', f => 'Series B ; v. 2' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'postfix' );
    is( $result[1], 'Microfilm. ',             '533 two-$f postfix: $a gets ". "' );
    is( $result[3], 'reel 1.',                 '533 two-$f postfix: $e gets "." (from $f .())' );
    is( $result[5], '(Series A ; v. 1).',      '533 two-$f postfix: first $f wrapped, gets "." before second $f' );
    is( $result[7], '(Series B ; v. 2)',       '533 two-$f postfix: second $f wrapped, last unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{533}, 'prefix' );
    check_combined( \@result, \@result_pr, '533 two-$f: combined string identical' );
}

# =====================================================================
# 534 – Original Version Note (spec §3.16)
# $b/$c/$e/$k/$l/$m/$n/$o/$t/$x/$z '. '; $f '.()'; $p trailing ': '.
# $a N/A.
# =====================================================================

# --- 534 ex 1 (doc §3.16) --- $p trailing colon + colon-skip on $c
# Doc: Current: 534 ## $p Originally published: $c New York : Garland, 1987.
{
    # render: [doc §3.16] 534 ## $p Originally published $c New York : Garland, 1987
    my $field = make_field( '534', ' ', ' ', p => 'Originally published', c => 'New York : Garland, 1987' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'postfix' );
    is( $result[1], 'Originally published: ', '534 ex1 postfix: $p gets trailing ": "' );
    is( $result[3], 'New York : Garland, 1987', '534 ex1 postfix: $c unchanged (no ". " after $p colon)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'prefix' );
    is( $result_pr[1], 'Originally published: ', '534 ex1 prefix: $p gets trailing ": "' );
    is( $result_pr[3], 'New York : Garland, 1987', '534 ex1 prefix: $c unchanged (colon-skip)' );

    check_combined( \@result, \@result_pr, '534 ex1: combined string identical' );
}

# --- 534 ex 2 (doc §3.16) --- $p then content via '. ' separators
# Doc: Current: 534 ## $p Originally issued: $a Frederick, John. $t Luck.
#   $n Published in: Argosy, 1919.
{
    # render: [doc §3.16] 534 ## $p Originally issued $a Frederick, John $t Luck $n Published in: Argosy, 1919
    my $field = make_field( '534', ' ', ' ', p => 'Originally issued', a => 'Frederick, John', t => 'Luck', n => 'Published in: Argosy, 1919' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'postfix' );
    is( $result[1], 'Originally issued: ',   '534 ex2 postfix: $p gets trailing ": "' );
    is( $result[3], 'Frederick, John. ',     '534 ex2 postfix: $a gets ". "' );
    is( $result[5], 'Luck. ',                '534 ex2 postfix: $t gets ". "' );
    is( $result[7], 'Published in: Argosy, 1919', '534 ex2 postfix: $n (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'prefix' );
    is( $result_pr[1], 'Originally issued: ', '534 ex2 prefix: $p gets trailing ": "' );
    is( $result_pr[3], 'Frederick, John',     '534 ex2 prefix: $a unchanged' );
    is( $result_pr[5], '. Luck',              '534 ex2 prefix: $t gets ". " prepended' );
    is( $result_pr[7], '. Published in: Argosy, 1919', '534 ex2 prefix: $n gets ". " prepended' );

    check_combined( \@result, \@result_pr, '534 ex2: combined string identical' );
}

# --- 534 ex 3 (doc §3.16) --- $p then '.()' on $f
# Doc: Current: 534 ## $p Reprint. Originally published: $c Oxford ; New
#   York : Pergamon Press, 1963. $f (International series of monographs on
#   electromagnetic waves ; v. 4).
{
    # render: [doc §3.16] 534 ## $p Reprint. Originally published $c Oxford ; New York : Pergamon Press, 1963 $f International series of monographs on electromagnetic waves ; v. 4
    my $field = make_field( '534', ' ', ' ', p => 'Reprint. Originally published', c => 'Oxford ; New York : Pergamon Press, 1963', f => 'International series of monographs on electromagnetic waves ; v. 4' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'postfix' );
    is( $result[1], 'Reprint. Originally published: ', '534 ex3 postfix: $p gets trailing ": "' );
    is( $result[3], 'Oxford ; New York : Pergamon Press, 1963.', '534 ex3 postfix: $c gets "." (from $f .())' );
    is( $result[5], '(International series of monographs on electromagnetic waves ; v. 4)', '534 ex3 postfix: $f wrapped in parens' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'prefix' );
    is( $result_pr[1], 'Reprint. Originally published: ', '534 ex3 prefix: $p gets trailing ": "' );
    is( $result_pr[3], 'Oxford ; New York : Pergamon Press, 1963', '534 ex3 prefix: $c unchanged' );
    is( $result_pr[5], '. (International series of monographs on electromagnetic waves ; v. 4)', '534 ex3 prefix: period OUTSIDE $f parens' );

    check_combined( \@result, \@result_pr, '534 ex3: combined string identical' );
}

# --- 534 edge: $p alone (trailing colon only) ---
{
    # render: 534 ## $p Originally published
    my $field = make_field( '534', ' ', ' ', p => 'Originally published' );
    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'postfix' );
    is( $result[1], 'Originally published: ', '534 $p-alone: gets trailing ": "' );
    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{534}, 'prefix' );
    check_combined( \@result, \@result_pr, '534 $p-alone: combined string identical' );
}

done_testing();
