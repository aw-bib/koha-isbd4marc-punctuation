#!/usr/bin/perl
#
# Tests for _decorate_field with Corporate Name rules (110/610/710/810).
#
# ISBD punctuation for corporate names (spec §5.3 / colleague ISBDX10):
#   $a '' | $b '. ' | $e ', ' | $g '()' | $p ', ' | $r ', ' | $s '. ' | $t '. '
#   compound keys: cc '; '  dc ' : '  nd ' : '  (inside $n/$d/$c group)
#   $n/$d/$c grouped in one pair of parens via _decorate_x10_pre
#   $a, $n, $o, $u, $x, $y, $z: no individual punctuation
# 110/710 identical; 610 (subject) excludes $v/$x/$y/$z; 810 (series) adds
# $v ' ;'.

use strict;
use warnings;
use Test::More;
use lib '.';
use lib 't/lib';
use Koha::RecordProcessor::Base;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

sub _decorate {
    my ( $rules_key, $attach_mode, @sfs ) = @_;
    $attach_mode //= 'postfix';
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{$rules_key};
    my $field = MARC::Field->new( $rules_key, ' ', ' ', @sfs );
    return [ Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, $attach_mode ) ];
}

sub combined {
    my ($res) = @_;
    my $c = '';
    for ( my $i = 1 ; $i < @$res ; $i += 2 ) { $c .= $res->[$i]; }
    return $c;
}

sub check_combined {
    my ( $rules_key, $desc, @sfs ) = @_;
    my $postfix = _decorate( $rules_key, 'postfix', @sfs );
    my $prefix  = _decorate( $rules_key, 'prefix', @sfs );
    is( combined($prefix), combined($postfix), "Combined string identical: $desc" );
}

# ===== 110 (Main Entry - Corporate Name) =====
# ex 1: $a + $b
{
    # render: 110 ## $a Canada $b Department of Agriculture
    my $r = _decorate( '110', 'postfix', a => 'Canada', b => 'Department of Agriculture' );
  is( combined($r), 'Canada. Department of Agriculture', '110 ex1: combined' );
  is( $r->[1], 'Canada. ', '110 ex1: $a gets ". " before $b' );
  is( $r->[3], 'Department of Agriculture', '110 ex1: $b last' );
  check_combined( '110', '110 ex1: $a+$b', a => 'Canada', b => 'Department of Agriculture' ) }

# ex 2: $a + $g (wrapped + leading space) + $b
{
    # render: 110 ## $a Fairfax County $g Va. $b Division of Mapping
    my $r = _decorate( '110', 'postfix', a => 'Fairfax County', g => 'Va.', b => 'Division of Mapping' );
  is( combined($r), 'Fairfax County (Va.). Division of Mapping', '110 ex2: combined' );
  is( $r->[1], 'Fairfax County', '110 ex2: $a unchanged' );
  is( $r->[3], ' (Va.). ', '110 ex2: $g wrapped (lead space) + $b next ". "' );
  is( $r->[5], 'Division of Mapping', '110 ex2: $b last' );
  check_combined( '110', '110 ex2: $a+$g+$b', a => 'Fairfax County', g => 'Va.', b => 'Division of Mapping' ) }

# ex 4-7: $a + single $g qualifiers
{
    # render: 110 ## $a National Gardening Association $g U.S.
    my $r = _decorate( '110', 'postfix', a => 'National Gardening Association', g => 'U.S.' );
  is( combined($r), 'National Gardening Association (U.S.)', '110 ex4: combined' );
  is( $r->[3], ' (U.S.)', '110 ex4: $g wrapped (lead space)' );
  check_combined( '110', '110 ex4: $a+$g', a => 'National Gardening Association', g => 'U.S.' ) }

{
    # render: 110 ## $a PRONAPADE $g Firm
    my $r = _decorate( '110', 'postfix', a => 'PRONAPADE', g => 'Firm' );
  is( combined($r), 'PRONAPADE (Firm)', '110 ex5: combined' );
  is( $r->[3], ' (Firm)', '110 ex5: $g wrapped (lead space)' );
  check_combined( '110', '110 ex5: $a+$g', a => 'PRONAPADE', g => 'Firm' ) }

{
    # render: 110 ## $a Scientific Society of San Antonio $g 1892-1894
    my $r = _decorate( '110', 'postfix', a => 'Scientific Society of San Antonio', g => '1892-1894' );
  is( combined($r), 'Scientific Society of San Antonio (1892-1894)', '110 ex6: combined' );
  is( $r->[3], ' (1892-1894)', '110 ex6: $g wrapped (lead space)' );
  check_combined( '110', '110 ex6: $a+$g', a => 'Scientific Society of San Antonio', g => '1892-1894' ) }

{
    # render: 110 ## $a St. James Church $g Bronx, New York, N.Y.
    my $r = _decorate( '110', 'postfix', a => 'St. James Church', g => 'Bronx, New York, N.Y.' );
  is( combined($r), 'St. James Church (Bronx, New York, N.Y.)', '110 ex7: combined' );
  is( $r->[3], ' (Bronx, New York, N.Y.)', '110 ex7: $g wrapped (lead space)' );
  check_combined( '110', '110 ex7: $a+$g', a => 'St. James Church', g => 'Bronx, New York, N.Y.' ) }

# multiple $b subordinate units chain
{
    # render: 110 ## $a Canada $b Department $b Section
    my $r = _decorate( '110', 'postfix', a => 'Canada', b => 'Department', b => 'Section' );
  is( combined($r), 'Canada. Department. Section', '110: multiple $b combined' );
  is( $r->[1], 'Canada. ', '110: $a gets ". " before first $b' );
  is( $r->[3], 'Department. ', '110: first $b gets ". " before second $b' );
  is( $r->[5], 'Section', '110: second $b last' );
  check_combined( '110', '110: multiple $b', a => 'Canada', b => 'Department', b => 'Section' ) }

# $e relator term
{
    # render: 110 ## $a ABC Corporation $e issuing body
    my $r = _decorate( '110', 'postfix', a => 'ABC Corporation', e => 'issuing body' );
  is( combined($r), 'ABC Corporation, issuing body', '110: $e relator combined' );
  is( $r->[1], 'ABC Corporation, ', '110: $a gets ", " before $e' );
  is( $r->[3], 'issuing body', '110: $e last' );
  check_combined( '110', '110: $a+$e', a => 'ABC Corporation', e => 'issuing body' ) }

# EX 8 / GROUPING: $n/$d/$c wrapped in one pair of parens, joined by ' : '
# $d + $c
{
    # render: 110 ## $a Democratic Party $g Tex. $b State Convention $d 1857 $c Waco, Tex.
    my $r = _decorate( '110', 'postfix', a => 'Democratic Party', g => 'Tex.', b => 'State Convention', d => '1857', c => 'Waco, Tex.' );
  is( combined($r), 'Democratic Party (Tex.). State Convention (1857 : Waco, Tex.)', '110 ex8: $d+$c grouped' );
  is( $r->[1], 'Democratic Party', '110 ex8: $a unchanged' );
  is( $r->[3], ' (Tex.). ', '110 ex8: $g wrapped + $b next ". "' );
  is( $r->[5], 'State Convention', '110 ex8: $b unchanged (no comma before group)' );
  is( $r->[7], ' (1857 : ', '110 ex8: $d opens group, gets " : " (dc)' );
  is( $r->[9], 'Waco, Tex.)', '110 ex8: $c closes group' );
  check_combined( '110', '110 ex8: $a+$g+$b+$d+$c', a => 'Democratic Party', g => 'Tex.', b => 'State Convention', d => '1857', c => 'Waco, Tex.' ) }

# $n + $d + $c (full meeting group)
{
    # render: 110 ## $a Symposium $n 2nd $d 1983 $c Berlin
    my $r = _decorate( '110', 'postfix', a => 'Symposium', n => '2nd', d => '1983', c => 'Berlin' );
  is( combined($r), 'Symposium (2nd : 1983 : Berlin)', '110: $n+$d+$c grouped' );
  is( $r->[1], 'Symposium', '110: $a unchanged' );
  is( $r->[3], ' (2nd : ', '110: $n opens group, gets " : " (nd)' );
  is( $r->[5], '1983 : ', '110: $d gets " : " (dc)' );
  is( $r->[7], 'Berlin)', '110: $c closes group' );
  check_combined( '110', '110: $a+$n+$d+$c', a => 'Symposium', n => '2nd', d => '1983', c => 'Berlin' ) }

# multiple $c (locations) joined by ' ; ' (cc)
{
    # render: 110 ## $a Meeting $d 1983 $c Berlin $c Leipzig
    my $r = _decorate( '110', 'postfix', a => 'Meeting', d => '1983', c => 'Berlin', c => 'Leipzig' );
  is( combined($r), 'Meeting (1983 : Berlin ; Leipzig)', '110: multiple $c use " ; " (cc)' );
  check_combined( '110', '110: $a+$d+$c+$c', a => 'Meeting', d => '1983', c => 'Berlin', c => 'Leipzig' ) }

# lone $n (just meeting number) -> wrapped by group callback
{
    # render: 110 ## $a Symposium $n 1st
    my $r = _decorate( '110', 'postfix', a => 'Symposium', n => '1st' );
  is( combined($r), 'Symposium (1st)', '110: lone $n wrapped (lead space)' );
  is( $r->[1], 'Symposium', '110: $a unchanged' );
  is( $r->[3], ' (1st)', '110: lone $n opens+closes group' );
  check_combined( '110', '110: $a+$n', a => 'Symposium', n => '1st' ) }

# $u affiliation: no ISBD punctuation (decision, see code comment)
{
    # render: 110 ## $a ABC $u USA
    my $r = _decorate( '110', 'postfix', a => 'ABC', u => 'USA' );
  is( combined($r), 'ABCUSA', '110: $u unchanged (no ISBD punct)' );
  check_combined( '110', '110: $a+$u', a => 'ABC', u => 'USA' ) }

# $a alone
{
    # render: 110 ## $a Canada
    my $r = _decorate( '110', 'postfix', a => 'Canada' );
  is( combined($r), 'Canada', '110: $a alone unchanged' );
  check_combined( '110', '110: $a alone', a => 'Canada' ) }

# ===== 710 (Added Entry - Corporate Name) - aliases 110 =====
{
    # render: 710 ## $a Canada $b Department of Agriculture
    my $r = _decorate( '710', 'postfix', a => 'Canada', b => 'Department of Agriculture' );
  is( combined($r), 'Canada. Department of Agriculture', '710: aliases 110' );
  check_combined( '710', '710: $a+$b', a => 'Canada', b => 'Department of Agriculture' ) }

{
    # render: 710 ## $a United Nations $g General Assembly $e observer
    my $r = _decorate( '710', 'postfix', a => 'United Nations', g => 'General Assembly', e => 'observer' );
  is( combined($r), 'United Nations (General Assembly), observer', '710: $g+e' );
  is( $r->[3], ' (General Assembly), ', '710: $g wrapped + $e next ", "' );
  is( $r->[5], 'observer', '710: $e last' );
  check_combined( '710', '710: $a+$g+$e', a => 'United Nations', g => 'General Assembly', e => 'observer' ) }

# ===== 610 (Subject Added Entry - Corporate Name) =====
# subdivisions $v/$x/$y/$z are NOT punctuated
{
    # render: 610 ## $a ABC Corp. $b Division $v Periodicals $x History
    my $r = _decorate( '610', 'postfix', a => 'ABC Corp.', b => 'Division', v => 'Periodicals', x => 'History' );
  is( $r->[1], 'ABC Corp.. ', '610: $a gets ". " before $b' );
  is( $r->[3], 'Division', '610: $b unchanged (v not in pchrs)' );
  is( $r->[5], 'Periodicals', '610: $v unchanged' );
  is( $r->[7], 'History', '610: $x last' );
  check_combined( '610', '610: $a+$b+$v+$x', a => 'ABC Corp.', b => 'Division', v => 'Periodicals', x => 'History' ) }

{
    # render: 610 ## $a Catholic Church $g Spirit $v B $x E $y 17
    my $r = _decorate( '610', 'postfix', a => 'Catholic Church', g => 'Spirit', v => 'B', x => 'E', y => '17' );
  is( combined($r), 'Catholic Church (Spirit)BE17', '610: subdivision chain no punct' );
  is( $r->[3], ' (Spirit)', '610: $g wrapped (lead space)' );
  is( $r->[5], 'B', '610: $v unchanged' );
  is( $r->[7], 'E', '610: $x unchanged' );
  is( $r->[9], '17', '610: $y last' );
  check_combined( '610', '610: $a+$g+$v+$x+$y', a => 'Catholic Church', g => 'Spirit', v => 'B', x => 'E', y => '17' ) }

# ===== 810 (Series Added Entry - Corporate Name) =====
# $v (volume) IS punctuated with ' ;'
{
    # render: 810 ## $a ABC Corp. $v 12
    my $r = _decorate( '810', 'postfix', a => 'ABC Corp.', v => '12' );
  is( $r->[1], 'ABC Corp. ;', '810: $a gets " ;" before $v' );
  is( $r->[3], '12', '810: $v last' );
  check_combined( '810', '810: $a+$v', a => 'ABC Corp.', v => '12' ) }

{
    # render: 810 ## $a Canada $b Dept. $v v. 3
    my $r = _decorate( '810', 'postfix', a => 'Canada', b => 'Dept.', v => 'v. 3' );
  is( combined($r), 'Canada. Dept. ;v. 3', '810: $a+$b+$v' );
  is( $r->[1], 'Canada. ', '810: $a gets ". " before $b' );
  is( $r->[3], 'Dept. ;', '810: $b gets " ;" before $v' );
  is( $r->[5], 'v. 3', '810: $v last' );
  check_combined( '810', '810: $a+$b+$v', a => 'Canada', b => 'Dept.', v => 'v. 3' ) }

done_testing();
