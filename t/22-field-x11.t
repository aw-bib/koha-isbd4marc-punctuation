#!/usr/bin/perl
#
# Tests for _decorate_field with Meeting Name rules (111/611/711/811).
#
# ISBD punctuation for meeting names (spec §5.4 / mirrors x10 structure):
#   $e '. ' (subordinate unit) | $j ', ' (relator term) | $q '. '
#   $g '()' (qualifier, wrapped with leading space)
#   compound group keys (inside $n/$d/$c group): cc ' ; ' dc ' : ' nd ' : '
#   $n/$d/$c grouped in one pair of parens via _decorate_x10_pre
#   $a, $u: no punctuation
# 111/711 identical (711 via use_rules); 611 (subject) no $v/$x/$y/$z;
# 811 (series) adds $v ' ;'.

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

# ===== 111 (Main Entry - Meeting Name) =====
# ex 1: $n + $d within one paren group
{
    # render: 111 2# $a Brussels Hemoglobin Symposium $n 1st $d 1983
    my $r = _decorate(
        '111', 'postfix',
        a => 'Brussels Hemoglobin Symposium',
        n => '1st',
        d => '1983'
    );
    is(
        combined($r),
        'Brussels Hemoglobin Symposium (1st : 1983)',
        '111 ex1: combined'
    );
    is( $r->[1], 'Brussels Hemoglobin Symposium', '111 ex1: $a unchanged' );
    is( $r->[3], ' (1st : ',
        '111 ex1: $n opens group (lead space) + " : " (nd)' );
    is( $r->[5], '1983)', '111 ex1: $d closes group' );
    check_combined(
        '111', '111 ex1: $a+$n+$d',
        a => 'Brussels Hemoglobin Symposium',
        n => '1st',
        d => '1983'
    )
}

# ex 2: $g qualifier + $d/$c group
{
# render: 111 2# $a Governor's Conference on Aging $g N.Y. $d 1982 $c Albany, N.Y.
    my $r = _decorate(
        '111', 'postfix',
        a => "Governor's Conference on Aging",
        g => 'N.Y.',
        d => '1982',
        c => 'Albany, N.Y.'
    );
    is(
        combined($r),
        "Governor's Conference on Aging (N.Y.) (1982 : Albany, N.Y.)",
        '111 ex2: combined'
    );
    is( $r->[1], "Governor's Conference on Aging", '111 ex2: $a unchanged' );
    is( $r->[3], ' (N.Y.)',       '111 ex2: $g wrapped (lead space)' );
    is( $r->[5], ' (1982 : ',     '111 ex2: $d opens group + " : " (dc)' );
    is( $r->[7], 'Albany, N.Y.)', '111 ex2: $c closes group' );
    check_combined(
        '111', '111 ex2: $a+$g+$d+$c',
        a => "Governor's Conference on Aging",
        g => 'N.Y.',
        d => '1982',
        c => 'Albany, N.Y.'
    )
}

# ex 4: $g + $n/$d/$c full group
{
# render: 111 2# $a Military History Symposium $g U.S. $n 9th $d 1980 $c United States Air Force Academy
    my $r = _decorate(
        '111', 'postfix',
        a => 'Military History Symposium',
        g => 'U.S.',
        n => '9th',
        d => '1980',
        c => 'United States Air Force Academy'
    );
    is(
        combined($r),
'Military History Symposium (U.S.) (9th : 1980 : United States Air Force Academy)',
        '111 ex4: combined'
    );
    is( $r->[3], ' (U.S.)',  '111 ex4: $g wrapped (lead space)' );
    is( $r->[5], ' (9th : ', '111 ex4: $n opens group + " : " (nd)' );
    is( $r->[7], '1980 : ',  '111 ex4: $d gets " : " (dc)' );
    is(
        $r->[9],
        'United States Air Force Academy)',
        '111 ex4: $c closes group'
    );
    check_combined(
        '111', '111 ex4: $a+$g+$n+$d+$c',
        a => 'Military History Symposium',
        g => 'U.S.',
        n => '9th',
        d => '1980',
        c => 'United States Air Force Academy'
    )
}

# $e subordinate unit after a $n/$d/$c group (uses '. ' per meeting spec)
{
# render: 111 2# $a Olympic Games $n 21st $d 1976 $c Montréal, Québec $e Organizing Committee $e Arts and Culture Program $e Visual Arts Section
    my $r = _decorate(
        '111', 'postfix',
        a => 'Olympic Games',
        n => '21st',
        d => '1976',
        c => 'Montréal, Québec',
        e => 'Organizing Committee',
        e => 'Arts and Culture Program',
        e => 'Visual Arts Section'
    );
    is(
        combined($r),
'Olympic Games (21st : 1976 : Montréal, Québec). Organizing Committee. Arts and Culture Program. Visual Arts Section',
        '111: $e chain after group'
    );
    is( $r->[3], ' (21st : ',           '111: $n opens group (lead space)' );
    is( $r->[5], '1976 : ',             '111: $d gets " : " (dc)' );
    is( $r->[7], 'Montréal, Québec). ', '111: $c closes group + ". " for $e' );
    is(
        $r->[9],
        'Organizing Committee. ',
        '111: first $e gets ". " for next $e'
    );
    is(
        $r->[11],
        'Arts and Culture Program. ',
        '111: second $e gets ". " for next $e'
    );
    is( $r->[13], 'Visual Arts Section', '111: last $e unchanged' );
    check_combined(
        '111', '111: $a+$n+$d+$c+3x$e',
        a => 'Olympic Games',
        n => '21st',
        d => '1976',
        c => 'Montréal, Québec',
        e => 'Organizing Committee',
        e => 'Arts and Culture Program',
        e => 'Visual Arts Section'
    )
}

# $q name after jurisdiction -> '. '
{
    # render: 111 2# $a Boston $q a city on a hill $d 1980 $c Boston, Mass.
    my $r = _decorate(
        '111', 'postfix',
        a => 'Boston',
        q => 'a city on a hill',
        d => '1980',
        c => 'Boston, Mass.'
    );
    is(
        combined($r),
        'Boston. a city on a hill (1980 : Boston, Mass.)',
        '111: $q gets ". " then group'
    );
    is( $r->[1], 'Boston. ',         '111: $a gets ". " before $q' );
    is( $r->[3], 'a city on a hill', '111: $q unchanged (last before group)' );
    is( $r->[5], ' (1980 : ',        '111: $d opens group' );
    is( $r->[7], 'Boston, Mass.)',   '111: $c closes group' );
    check_combined(
        '111', '111: $a+$q+$d+$c',
        a => 'Boston',
        q => 'a city on a hill',
        d => '1980',
        c => 'Boston, Mass.'
    )
}

# $j relator term -> ', '
{
   # render: 111 2# $a Canadian Meteorological Society $g Canada $j issuing body
    my $r = _decorate(
        '111', 'postfix',
        a => 'Canadian Meteorological Society',
        g => 'Canada',
        j => 'issuing body'
    );
    is(
        combined($r),
        'Canadian Meteorological Society (Canada), issuing body',
        '111: $j relator'
    );
    is( $r->[3], ' (Canada), ',  '111: $g wrapped + $j next ", "' );
    is( $r->[5], 'issuing body', '111: $j last' );
    check_combined(
        '111', '111: $a+$g+$j',
        a => 'Canadian Meteorological Society',
        g => 'Canada',
        j => 'issuing body'
    )
}

# multiple $c locations joined by ' ; ' (cc)
{
    # render: 111 2# $a Meeting $d 1983 $c Berlin $c Leipzig
    my $r = _decorate(
        '111', 'postfix',
        a => 'Meeting',
        d => '1983',
        c => 'Berlin',
        c => 'Leipzig'
    );
    is(
        combined($r),
        'Meeting (1983 : Berlin ; Leipzig)',
        '111: multiple $c use " ; " (cc)'
    );
    check_combined(
        '111', '111: $a+$d+$c+$c',
        a => 'Meeting',
        d => '1983',
        c => 'Berlin',
        c => 'Leipzig'
    )
}

# lone $n (just a meeting number) -> still grouped (meeting name portion).
# The A1 discrimination only affects $n in the §5.5 title portion (after $t).
{
    # render: 111 2# $a Symposium $n 1st
    my $r = _decorate( '111', 'postfix', a => 'Symposium', n => '1st' );
    is( combined($r), 'Symposium (1st)', '111: lone $n wrapped (meeting)' );
    is( $r->[3],      ' (1st)',          '111: lone $n opens+closes group' );
    check_combined( '111', '111: $a+$n', a => 'Symposium', n => '1st' )
}

# $u affiliation: no ISBD punctuation
{
    # render: 111 2# $a ABC $u USA
    my $r = _decorate( '111', 'postfix', a => 'ABC', u => 'USA' );
    is( combined($r), 'ABCUSA', '111: $u unchanged (no ISBD punct)' );
    check_combined( '111', '111: $a+$u', a => 'ABC', u => 'USA' )
}

# $a alone
{
    # render: 111 2# $a Canada
    my $r = _decorate( '111', 'postfix', a => 'Canada' );
    is( combined($r), 'Canada', '111: $a alone unchanged' );
    check_combined( '111', '111: $a alone', a => 'Canada' )
}

# ===== 711 (Added Entry - Meeting Name) - aliases 111 =====
{
    # render: 711 2# $a Theatertreffen Berlin $g Festival
    my $r = _decorate(
        '711', 'postfix',
        a => 'Theatertreffen Berlin',
        g => 'Festival'
    );
    is(
        combined($r),
        'Theatertreffen Berlin (Festival)',
        '711 ex3: $g wrapped'
    );
    is( $r->[3], ' (Festival)', '711 ex3: $g wrapped (lead space)' );
    check_combined(
        '711', '711 ex3: $a+$g',
        a => 'Theatertreffen Berlin',
        g => 'Festival'
    )
}

{
# render: 711 2# $a Olympic Games $n 21st $d 1976 $c Montréal, Québec $e Organizing Committee
    my $r = _decorate(
        '711', 'postfix',
        a => 'Olympic Games',
        n => '21st',
        d => '1976',
        c => 'Montréal, Québec',
        e => 'Organizing Committee'
    );
    is(
        combined($r),
        'Olympic Games (21st : 1976 : Montréal, Québec). Organizing Committee',
        '711: group + $e'
    );
    check_combined(
        '711', '711: $a+$n+$d+$c+$e',
        a => 'Olympic Games',
        n => '21st',
        d => '1976',
        c => 'Montréal, Québec',
        e => 'Organizing Committee'
    )
}

# ===== 611 (Subject Added Entry - Meeting Name) =====
# subdivisions $v/$x/$y/$z are NOT punctuated
{
    # render: 611 2# $a Meeting $d 1980 $c Berlin $x History $v Periodicals
    my $r = _decorate(
        '611', 'postfix',
        a => 'Meeting',
        d => '1980',
        c => 'Berlin',
        x => 'History',
        v => 'Periodicals'
    );
    is(
        combined($r),
        'Meeting (1980 : Berlin)HistoryPeriodicals',
        '611: subdivisions no punct'
    );
    is( $r->[3], ' (1980 : ',   '611: $d opens group' );
    is( $r->[5], 'Berlin)',     '611: $c closes group' );
    is( $r->[7], 'History',     '611: $x unchanged' );
    is( $r->[9], 'Periodicals', '611: $v last unchanged' );
    check_combined(
        '611', '611: $a+$d+$c+$x+$v',
        a => 'Meeting',
        d => '1980',
        c => 'Berlin',
        x => 'History',
        v => 'Periodicals'
    )
}

# ===== 811 (Series Added Entry - Meeting Name) =====
# $v (volume) IS punctuated with ' ;'
{
    # render: 811 2# $a Symposium $n 5th $d 1990 $c Paris $v no. 3
    my $r = _decorate(
        '811', 'postfix',
        a => 'Symposium',
        n => '5th',
        d => '1990',
        c => 'Paris',
        v => 'no. 3'
    );
    is(
        combined($r),
        'Symposium (5th : 1990 : Paris) ;no. 3',
        '811: group + $v " ;"'
    );
    is( $r->[1], 'Symposium', '811: $a unchanged' );
    is( $r->[3], ' (5th : ',  '811: $n opens group' );
    is( $r->[5], '1990 : ',   '811: $d gets " : " (dc)' );
    is( $r->[7], 'Paris) ;',  '811: $c closes group + " ;" for $v' );
    is( $r->[9], 'no. 3',     '811: $v last' );
    check_combined(
        '811', '811: $a+$n+$d+$c+$v',
        a => 'Symposium',
        n => '5th',
        d => '1990',
        c => 'Paris',
        v => 'no. 3'
    )
}

# ===== Title-portion subfields (spec §5.5) =====
# These were the missing x11 keys — uniform-title subfields on the meeting
# name fields. Each was previously passed through with NO punctuation.

# $t uniform title/title of work -> '. '
{
    # render: 111 2# $a Symposium $t Proceedings
    my $r = _decorate( '111', 'postfix', a => 'Symposium', t => 'Proceedings' );
    is( combined($r), 'Symposium. Proceedings', '111 tp: $t gets ". "' );
    is( $r->[1],      'Symposium. ', '111 tp: $a gets ". " before $t' );
    is( $r->[3],      'Proceedings', '111 tp: $t last' );
    check_combined(
        '111', '111 tp: $a+$t',
        a => 'Symposium',
        t => 'Proceedings'
    )
}

# $k form subheading -> '. '
{
    # render: 111 2# $a Symposium $t Proceedings $k Selections
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        k => 'Selections'
    );
    is(
        combined($r),
        'Symposium. Proceedings. Selections',
        '111 tp: $k gets ". "'
    );
    is( $r->[1], 'Symposium. ',   '111 tp: $a gets ". " (t)' );
    is( $r->[3], 'Proceedings. ', '111 tp: $t gets ". " before $k' );
    is( $r->[5], 'Selections',    '111 tp: $k last' );
    check_combined(
        '111', '111 tp: $a+$t+$k',
        a => 'Symposium',
        t => 'Proceedings',
        k => 'Selections'
    )
}

# $l language -> '. '
{
    # render: 111 2# $a Symposium $t Proceedings $l English
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        l => 'English'
    );
    is(
        combined($r),
        'Symposium. Proceedings. English',
        '111 tp: $l gets ". "'
    );
    check_combined(
        '111', '111 tp: $a+$t+$l',
        a => 'Symposium',
        t => 'Proceedings',
        l => 'English'
    )
}

# $p name of part -> ', ' (pick).
# Note: because pchrs keys fire
# on the FOLLOWING subfield, a title before $p gets the $p value (', ') and
# $p before $k gets $k's value ('. ') — consistent with how x00 behaves.
{
    # render: 111 2# $a Symposium $t Proceedings $p Volume 1 $k Selections
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        p => 'Volume 1',
        k => 'Selections'
    );
    is(
        combined($r),
        'Symposium. Proceedings, Volume 1. Selections',
        '111 tp: $p in title chain'
    );
    is( $r->[3], 'Proceedings, ', '111 tp: $t gets ", " before $p (key p)' );
    is( $r->[5], 'Volume 1. ',    '111 tp: $p gets ". " before $k (key k)' );
    check_combined(
        '111', '111 tp: $a+$t+$p+$k',
        a => 'Symposium',
        t => 'Proceedings',
        p => 'Volume 1',
        k => 'Selections'
    )
}

# $f date of a work -> '. '
{
    # render: 111 2# $a Symposium $t Proceedings $f 2005
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        f => '2005'
    );
    is( combined($r), 'Symposium. Proceedings. 2005', '111 tp: $f gets ". "' );
    check_combined(
        '111', '111 tp: $a+$t+$f',
        a => 'Symposium',
        t => 'Proceedings',
        f => '2005'
    )
}

# $s version -> '. ' (pick)
{
    # render: 111 2# $a Symposium $t Proceedings $s 2nd ed.
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        s => '2nd ed.'
    );
    is(
        combined($r),
        'Symposium. Proceedings. 2nd ed.',
        '111 tp: $s gets ". "'
    );
    check_combined(
        '111', '111 tp: $a+$t+$s',
        a => 'Symposium',
        t => 'Proceedings',
        s => '2nd ed.'
    )
}

# $h medium -> '. '
{
    # render: 111 2# $a Symposium $t Proceedings $h microform
    my $r = _decorate(
        '111', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        h => 'microform'
    );
    is(
        combined($r),
        'Symposium. Proceedings. microform',
        '111 tp: $h gets ". "'
    );
    check_combined(
        '111', '111 tp: $a+$t+$h',
        a => 'Symposium',
        t => 'Proceedings',
        h => 'microform'
    )
}

# Title-portion also applies to 811 (series). $v follows the title chain.
{
    # render: 811 2# $a Symposium $t Proceedings $l English $v no. 3
    my $r = _decorate(
        '811', 'postfix',
        a => 'Symposium',
        t => 'Proceedings',
        l => 'English',
        v => 'no. 3'
    );
    is(
        combined($r),
        'Symposium. Proceedings. English ;no. 3',
        '811 tp: title chain + $v'
    );
    is( $r->[1], 'Symposium. ',   '811 tp: $a gets ". " before $t' );
    is( $r->[3], 'Proceedings. ', '811 tp: $t gets ". " before $l' );
    is( $r->[5], 'English ;',     '811 tp: $l gets " ;" before $v' );
    is( $r->[7], 'no. 3',         '811 tp: $v last' );
    check_combined(
        '811', '811 tp: $a+$t+$l+$v',
        a => 'Symposium',
        t => 'Proceedings',
        l => 'English',
        v => 'no. 3'
    )
}

done_testing();
