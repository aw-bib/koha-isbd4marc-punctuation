#!/usr/bin/perl
#
# Tests for _decorate_field with Corporate Name rules (110/610/710/810).
#
# ISBD punctuation for corporate names (spec §5.3):
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
use t::lib::TestHelper qw(combined_string);

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

sub _decorate {
    my ( $rules_key, $attach_mode, @sfs ) = @_;
    $attach_mode //= 'postfix';
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{$rules_key};
    my $field = MARC::Field->new( $rules_key, ' ', ' ', @sfs );
    return [
        Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field(
            $field, $rules, $attach_mode
        )
    ];
}

sub combined {
    my ($res) = @_;
    return combined_string($res);    # single source of truth in TestHelper
}

sub check_combined {
    my ( $rules_key, $desc, @sfs ) = @_;
    my $postfix = _decorate( $rules_key, 'postfix', @sfs );
    my $prefix  = _decorate( $rules_key, 'prefix',  @sfs );
    is( combined($prefix), combined($postfix),
        "Combined string identical: $desc" );
}

# ===== 110 (Main Entry - Corporate Name) =====
# ex 1: $a + $b
{
    # Doc: Current: 110 1# $a Canada. $b Department of Agriculture.
    # render: [doc §5.3] 110 ## $a Canada $b Department of Agriculture
    my $r = _decorate(
        '110', 'postfix',
        a => 'Canada',
        b => 'Department of Agriculture'
    );
    is( $r->[1], 'Canada. ', '110 ex1: $a gets ". " before $b' );
    is( $r->[3], 'Department of Agriculture', '110 ex1: $b last' );
    check_combined(
        '110', '110 ex1: $a+$b',
        a => 'Canada',
        b => 'Department of Agriculture'
    )
}

# ex 2: $a + $g (wrapped + leading space) + $b
{
    # Doc: Current: 110 1# $a Fairfax County (Va.). $b Division of Mapping.
    # render: [doc §5.3] 110 ## $a Fairfax County $g Va. $b Division of Mapping
    my $r = _decorate(
        '110', 'postfix',
        a => 'Fairfax County',
        g => 'Va.',
        b => 'Division of Mapping'
    );
    is( $r->[1], 'Fairfax County', '110 ex2: $a unchanged' );
    is( $r->[3], ' (Va.). ',
        '110 ex2: $g wrapped (lead space) + $b next ". "' );
    is( $r->[5], 'Division of Mapping', '110 ex2: $b last' );
    check_combined(
        '110', '110 ex2: $a+$g+$b',
        a => 'Fairfax County',
        g => 'Va.',
        b => 'Division of Mapping'
    )
}

# ex 4-7: $a + single $g qualifiers
{
    # Doc: Current: 110 2# $a National Gardening Association (U.S.)
    # render: [doc §5.3] 110 ## $a National Gardening Association $g U.S.
    my $r = _decorate(
        '110', 'postfix',
        a => 'National Gardening Association',
        g => 'U.S.'
    );
    is( $r->[3], ' (U.S.)', '110 ex4: $g wrapped (lead space)' );
    check_combined(
        '110', '110 ex4: $a+$g',
        a => 'National Gardening Association',
        g => 'U.S.'
    )
}

{
    # Doc: Current: 110 2# $a PRONAPADE (Firm)
    # render: [doc §5.3] 110 ## $a PRONAPADE $g Firm
    my $r = _decorate( '110', 'postfix', a => 'PRONAPADE', g => 'Firm' );
    is( $r->[3],      ' (Firm)',          '110 ex5: $g wrapped (lead space)' );
    check_combined( '110', '110 ex5: $a+$g', a => 'PRONAPADE', g => 'Firm' )
}

{
    # Doc: Current: 110 2# $a Scientific Society of San Antonio (1892-1894)
    # render: [doc §5.3] 110 ## $a Scientific Society of San Antonio $g 1892-1894
    my $r = _decorate(
        '110', 'postfix',
        a => 'Scientific Society of San Antonio',
        g => '1892-1894'
    );
    is( $r->[3], ' (1892-1894)', '110 ex6: $g wrapped (lead space)' );
    check_combined(
        '110', '110 ex6: $a+$g',
        a => 'Scientific Society of San Antonio',
        g => '1892-1894'
    )
}

{
    # Doc: Current: 110 2# $a St. James Church (Bronx, New York, N.Y.)
    # render: [doc §5.3] 110 ## $a St. James Church $g Bronx, New York, N.Y.
    my $r = _decorate(
        '110', 'postfix',
        a => 'St. James Church',
        g => 'Bronx, New York, N.Y.'
    );
    is(
        $r->[3],
        ' (Bronx, New York, N.Y.)',
        '110 ex7: $g wrapped (lead space)'
    );
    check_combined(
        '110', '110 ex7: $a+$g',
        a => 'St. James Church',
        g => 'Bronx, New York, N.Y.'
    )
}

# multiple $b subordinate units chain
{
    # render: 110 ## $a Canada $b Department $b Section
    my $r = _decorate(
        '110', 'postfix',
        a => 'Canada',
        b => 'Department',
        b => 'Section'
    );
    is( $r->[1], 'Canada. ',     '110: $a gets ". " before first $b' );
    is( $r->[3], 'Department. ', '110: first $b gets ". " before second $b' );
    is( $r->[5], 'Section',      '110: second $b last' );
    check_combined(
        '110', '110: multiple $b',
        a => 'Canada',
        b => 'Department',
        b => 'Section'
    )
}

# $e relator term
{
    # render: 110 ## $a ABC Corporation $e issuing body
    my $r = _decorate(
        '110', 'postfix',
        a => 'ABC Corporation',
        e => 'issuing body'
    );
    is( $r->[1], 'ABC Corporation, ', '110: $a gets ", " before $e' );
    is( $r->[3], 'issuing body',      '110: $e last' );
    check_combined(
        '110', '110: $a+$e',
        a => 'ABC Corporation',
        e => 'issuing body'
    )
}

# EX 8 / GROUPING: $n/$d/$c wrapped in one pair of parens, joined by ' : '
# $d + $c
{
    # Doc: Current: 110 2# $a Democratic Party (Tex.). $b State Convention $d (1857 : $c Waco, Tex.)
# render: [doc §5.3] 110 ## $a Democratic Party $g Tex. $b State Convention $d 1857 $c Waco, Tex.
    my $r = _decorate(
        '110', 'postfix',
        a => 'Democratic Party',
        g => 'Tex.',
        b => 'State Convention',
        d => '1857',
        c => 'Waco, Tex.'
    );
    is( $r->[1], 'Democratic Party', '110 ex8: $a unchanged' );
    is( $r->[3], ' (Tex.). ',        '110 ex8: $g wrapped + $b next ". "' );
    is(
        $r->[5],
        'State Convention',
        '110 ex8: $b unchanged (no comma before group)'
    );
    is( $r->[7], ' (1857 : ',   '110 ex8: $d opens group, gets " : " (dc)' );
    is( $r->[9], 'Waco, Tex.)', '110 ex8: $c closes group' );
    check_combined(
        '110', '110 ex8: $a+$g+$b+$d+$c',
        a => 'Democratic Party',
        g => 'Tex.',
        b => 'State Convention',
        d => '1857',
        c => 'Waco, Tex.'
    )
}

# $n + $d + $c (full meeting group)
{
    # render: [doc §5.3 - derived] 110 ## $a Symposium $n 2nd $d 1983 $c Berlin
    my $r = _decorate(
        '110', 'postfix',
        a => 'Symposium',
        n => '2nd',
        d => '1983',
        c => 'Berlin'
    );
    is( $r->[1], 'Symposium', '110: $a unchanged' );
    is( $r->[3], ' (2nd : ',  '110: $n opens group, gets " : " (nd)' );
    is( $r->[5], '1983 : ',   '110: $d gets " : " (dc)' );
    is( $r->[7], 'Berlin)',   '110: $c closes group' );
    check_combined(
        '110', '110: $a+$n+$d+$c',
        a => 'Symposium',
        n => '2nd',
        d => '1983',
        c => 'Berlin'
    )
}

# multiple $c (locations) joined by ' ; ' (cc)
{
    # render: [doc §5.3 - derived] 110 ## $a Meeting $d 1983 $c Berlin $c Leipzig
    my $r = _decorate(
        '110', 'postfix',
        a => 'Meeting',
        d => '1983',
        c => 'Berlin',
        c => 'Leipzig'
    );
    is( $r->[1], 'Meeting',    '110: $a unchanged' );
    is( $r->[3], ' (1983 : ',  '110: $d opens group' );
    is( $r->[5], 'Berlin ; ',  '110: first $c gets " ; " (cc)' );
    is( $r->[7], 'Leipzig)',   '110: last $c closes group' );
    check_combined(
        '110', '110: $a+$d+$c+$c',
        a => 'Meeting',
        d => '1983',
        c => 'Berlin',
        c => 'Leipzig'
    )
}

# lone $n (just a meeting number, no $d/$c) -> still grouped (meeting name
# portion). The A1 discrimination only affects $n in the §5.5 TITLE portion
# (after $t), not a lone meeting number after the name. See
# _decorate_x10_pre AMBIGUITY DECISION note.
{
    # render: [doc §5.3 - derived] 110 ## $a Symposium $n 1st
    my $r = _decorate( '110', 'postfix', a => 'Symposium', n => '1st' );
    is( $r->[1],      'Symposium',       '110: $a unchanged' );
    is( $r->[3],      ' (1st)',          '110: lone $n opens+closes group' );
    check_combined( '110', '110: $a+$n', a => 'Symposium', n => '1st' )
}

# $u affiliation: no ISBD punctuation (decision, see code comment)
{
    # render: 110 ## $a ABC $u USA
    my $r = _decorate( '110', 'postfix', a => 'ABC', u => 'USA' );
    is( $r->[3], 'USA', '110: $u unchanged (no ISBD punct)' );
    check_combined( '110', '110: $a+$u', a => 'ABC', u => 'USA' )
}

# $a alone
{
    # render: 110 ## $a Canada
    my $r = _decorate( '110', 'postfix', a => 'Canada' );
    is( $r->[1], 'Canada', '110: $a alone unchanged' );
    check_combined( '110', '110: $a alone', a => 'Canada' )
}

# ===== 710 (Added Entry - Corporate Name) - aliases 110 =====
{
    # Doc: Current: 710 1# $a Canada. $b Department of Agriculture.
    # render: [doc §5.3] 710 ## $a Canada $b Department of Agriculture
    my $r = _decorate(
        '710', 'postfix',
        a => 'Canada',
        b => 'Department of Agriculture'
    );
    my $r110 = _decorate(
        '110', 'postfix',
        a => 'Canada',
        b => 'Department of Agriculture'
    );
    is( combined($r), combined($r110), '710: aliases 110 (identical combined output)' );
    check_combined(
        '710', '710: $a+$b',
        a => 'Canada',
        b => 'Department of Agriculture'
    )
}

{
    # render: 710 ## $a United Nations $g General Assembly $e observer
    my $r = _decorate(
        '710', 'postfix',
        a => 'United Nations',
        g => 'General Assembly',
        e => 'observer'
    );
    is( $r->[3], ' (General Assembly), ', '710: $g wrapped + $e next ", "' );
    is( $r->[5], 'observer',              '710: $e last' );
    check_combined(
        '710', '710: $a+$g+$e',
        a => 'United Nations',
        g => 'General Assembly',
        e => 'observer'
    )
}

# ===== 610 (Subject Added Entry - Corporate Name) =====
# subdivisions $v/$x/$y/$z are NOT punctuated
{
    # render: 610 ## $a ABC Corp. $b Division $v Periodicals $x History
    my $r = _decorate(
        '610', 'postfix',
        a => 'ABC Corp.',
        b => 'Division',
        v => 'Periodicals',
        x => 'History'
    );
    is( $r->[1], 'ABC Corp.. ', '610: $a gets ". " before $b' );
    is( $r->[3], 'Division',    '610: $b unchanged (v not in pchrs)' );
    is( $r->[5], 'Periodicals', '610: $v unchanged' );
    is( $r->[7], 'History',     '610: $x last' );
    check_combined(
        '610', '610: $a+$b+$v+$x',
        a => 'ABC Corp.',
        b => 'Division',
        v => 'Periodicals',
        x => 'History'
    )
}

{
    # render: 610 ## $a Catholic Church $g Spirit $v B $x E $y 17
    my $r = _decorate(
        '610', 'postfix',
        a => 'Catholic Church',
        g => 'Spirit',
        v => 'B',
        x => 'E',
        y => '17'
    );
    is( $r->[3], ' (Spirit)', '610: $g wrapped (lead space)' );
    is( $r->[5], 'B',         '610: $v unchanged' );
    is( $r->[7], 'E',         '610: $x unchanged' );
    is( $r->[9], '17',        '610: $y last' );
    check_combined(
        '610', '610: $a+$g+$v+$x+$y',
        a => 'Catholic Church',
        g => 'Spirit',
        v => 'B',
        x => 'E',
        y => '17'
    )
}

# ===== 810 (Series Added Entry - Corporate Name) =====
# $v (volume) IS punctuated with ' ;'
{
    # render: 810 ## $a ABC Corp. $v 12
    my $r = _decorate( '810', 'postfix', a => 'ABC Corp.', v => '12' );
    is( $r->[1], 'ABC Corp. ;', '810: $a gets " ;" before $v' );
    is( $r->[3], '12',          '810: $v last' );
    check_combined( '810', '810: $a+$v', a => 'ABC Corp.', v => '12' )
}

{
    # render: 810 ## $a Canada $b Dept. $v v. 3
    my $r =
      _decorate( '810', 'postfix', a => 'Canada', b => 'Dept.', v => 'v. 3' );
    is( $r->[1],      'Canada. ',            '810: $a gets ". " before $b' );
    is( $r->[3],      'Dept. ;',             '810: $b gets " ;" before $v' );
    is( $r->[5],      'v. 3',                '810: $v last' );
    check_combined(
        '810', '810: $a+$b+$v',
        a => 'Canada',
        b => 'Dept.',
        v => 'v. 3'
    )
}

# ===== Title-portion subfields (spec §5.5) =====
# These were missing x10 keys — uniform-title subfields on the corporate name
# fields. $n => '. ' and $p => ', ' follow the §5.5 LoC/PCC reading
# (Ecuador 710 example), DIFFERING from x00 (which uses n=', ', p='. ').

# $t + $n + $p + $l — the §5.5 Ecuador 710 example
{
    # Doc: Current: 710 1# $a Ecuador. $t Plan Nacional de Desarrollo, 1980-1984. $n Parte 1, $p Grandes objetivos nacionales. $l English.
# render: [doc §5.5] 710 ## $a Ecuador $t Plan Nacional de Desarrollo, 1980-1984 $n Parte 1 $p Grandes objetivos nacionales $l English
    my $r = _decorate(
        '710', 'postfix',
        a => 'Ecuador',
        t => 'Plan Nacional de Desarrollo, 1980-1984',
        n => 'Parte 1',
        p => 'Grandes objetivos nacionales',
        l => 'English',
    );
    is( $r->[1], 'Ecuador. ', '710 tp: $a gets ". " before $t' );
    is(
        $r->[3],
        'Plan Nacional de Desarrollo, 1980-1984. ',
        '710 tp: $t gets ". " before $n'
    );
    is( $r->[5], 'Parte 1, ', '710 tp: $n gets ", " before $p' );
    is(
        $r->[7],
        'Grandes objetivos nacionales. ',
        '710 tp: $p gets ". " before $l'
    );
    is( $r->[9], 'English', '710 tp: $l last' );
    check_combined(
        '710', '710 tp: $a+$t+$n+$p+$l',
        a => 'Ecuador',
        t => 'Plan Nacional de Desarrollo, 1980-1984',
        n => 'Parte 1',
        p => 'Grandes objetivos nacionales',
        l => 'English',
    )
}

# $t uniform title -> '. '
{
    # render: [doc §5.5 - derived] 110 ## $a Canada $t Annual report
    my $r = _decorate( '110', 'postfix', a => 'Canada', t => 'Annual report' );
    is( $r->[1],      'Canada. ', '110 tp: $a gets ". " before $t' );
    check_combined(
        '110', '110 tp: $a+$t',
        a => 'Canada',
        t => 'Annual report'
    )
}

# $t + $k form subheading -> '. '
{
    # render: [doc §5.5 - derived] 110 ## $a Canada $t Annual report $k Selections
    my $r = _decorate(
        '110', 'postfix',
        a => 'Canada',
        t => 'Annual report',
        k => 'Selections'
    );
    is( $r->[1], 'Canada. ',       '110 tp: $a gets ". " before $t' );
    is( $r->[3], 'Annual report. ', '110 tp: $t gets ". " before $k' );
    is( $r->[5], 'Selections',     '110 tp: $k last' );
    check_combined(
        '110', '110 tp: $a+$t+$k',
        a => 'Canada',
        t => 'Annual report',
        k => 'Selections'
    )
}

# $t + $l language -> '. '
{
    # render: [doc §5.5 - derived] 110 ## $a Canada $t Annual report $l English
    my $r = _decorate(
        '110', 'postfix',
        a => 'Canada',
        t => 'Annual report',
        l => 'English'
    );
    is( $r->[1], 'Canada. ',       '110 tp: $a gets ". " before $t' );
    is( $r->[3], 'Annual report. ', '110 tp: $t gets ". " before $l' );
    is( $r->[5], 'English',         '110 tp: $l last' );
    check_combined(
        '110', '110 tp: $a+$t+$l',
        a => 'Canada',
        t => 'Annual report',
        l => 'English'
    )
}

# $t + $m medium of performance -> ', '
{
    # render: [doc §5.5 - derived] 110 ## $a Philharmonia $t Symphonies $m orchestra
    my $r = _decorate(
        '110', 'postfix',
        a => 'Philharmonia',
        t => 'Symphonies',
        m => 'orchestra'
    );
    is( $r->[1], 'Philharmonia. ', '110 tp: $a gets ". " before $t' );
    is( $r->[3], 'Symphonies, ',   '110 tp: $t gets ", " before $m' );
    is( $r->[5], 'orchestra',      '110 tp: $m last' );
    check_combined(
        '110', '110 tp: $a+$t+$m',
        a => 'Philharmonia',
        t => 'Symphonies',
        m => 'orchestra'
    )
}

# $t + $f date of work -> '. '
{
    # render: [doc §5.5 - derived] 110 ## $a Canada $t Annual report $f 2005
    my $r = _decorate(
        '110', 'postfix',
        a => 'Canada',
        t => 'Annual report',
        f => '2005'
    );
    is( $r->[1], 'Canada. ',       '110 tp: $a gets ". " before $t' );
    is( $r->[3], 'Annual report. ', '110 tp: $t gets ". " before $f' );
    is( $r->[5], '2005',            '110 tp: $f last' );
    check_combined(
        '110', '110 tp: $a+$t+$f',
        a => 'Canada',
        t => 'Annual report',
        f => '2005'
    )
}

# $t + $r key for music -> ', '
{
    # render: [doc §5.5 - derived] 110 ## $a Philharmonia $t Sonatas $r E major
    my $r = _decorate(
        '110', 'postfix',
        a => 'Philharmonia',
        t => 'Sonatas',
        r => 'E major'
    );
    is( $r->[1], 'Philharmonia. ', '110 tp: $a gets ". " before $t' );
    is( $r->[3], 'Sonatas, ',      '110 tp: $t gets ", " before $r' );
    is( $r->[5], 'E major',        '110 tp: $r last' );
    check_combined(
        '110', '110 tp: $a+$t+$r',
        a => 'Philharmonia',
        t => 'Sonatas',
        r => 'E major'
    )
}

# Title-portion also on 810 (series); $v follows the title chain.
{
    # render: [doc §5.5 - derived] 810 ## $a Canada $t Annual report $l English $v no. 3
    my $r = _decorate(
        '810', 'postfix',
        a => 'Canada',
        t => 'Annual report',
        l => 'English',
        v => 'no. 3'
    );
    is( $r->[1], 'Canada. ',       '810 tp: $a gets ". " before $t' );
    is( $r->[3], 'Annual report. ', '810 tp: $t gets ". " before $l' );
    is( $r->[5], 'English ;', '810 tp: $l gets " ;" before $v' );
    is( $r->[7], 'no. 3',     '810 tp: $v last' );
    check_combined(
        '810', '810 tp: $a+$t+$l+$v',
        a => 'Canada',
        t => 'Annual report',
        l => 'English',
        v => 'no. 3'
    )
}

done_testing();
