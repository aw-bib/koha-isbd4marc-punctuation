#!/usr/bin/perl
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
    my $field = MARC::Field->new( '100', ' ', ' ', @sfs );
    return [
        Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field(
            $field, $rules, $attach_mode
        )
    ];
}

sub check_combined {
    my ( $rules_key, $desc, @sfs ) = @_;
    my $postfix = _decorate( $rules_key, 'postfix', @sfs );
    my $prefix  = _decorate( $rules_key, 'prefix',  @sfs );
    my $post_c  = join '', grep { ++$::i % 2 == 0 } @$postfix;
    local $::i = 0;
    my $pre_c = join '', grep { ++$::i % 2 == 0 } @$prefix;
    is( $pre_c, $post_c, "Combined string identical: $desc" );
}

# ===== 100 =====
{
    # render: 100 ## $a Smith, John
    my $r = _decorate( '100', 'postfix', a => 'Smith, John' );
    is( $r->[1], 'Smith, John', '100: $a alone' );
    check_combined( '100', '100: $a alone', a => 'Smith, John' )
}

{
    # render: 100 ## $a Morgan, Robert $d 1944-
    my $r = _decorate( '100', 'postfix', a => 'Morgan, Robert', d => '1944-' );
    is( $r->[1], 'Morgan, Robert, ', '100: $a before $d' );
    is( $r->[3], '1944-',            '100: $d last' );
    check_combined( '100', '100: $a+$d', a => 'Morgan, Robert', d => '1944-' )
}

{
    # render: 100 ## $a Reynolds, Joshua $c Sir $d 1723-1792 $j Pupil of
    my $r = _decorate(
        '100', 'postfix',
        a => 'Reynolds, Joshua',
        c => 'Sir',
        d => '1723-1792',
        j => 'Pupil of'
    );
    is( $r->[1], 'Reynolds, Joshua, ', '100: $a before $c' );
    is( $r->[3], 'Sir, ',              '100: $c before $d' );
    is( $r->[5], '1723-1792, ',        '100: $d before $j' );
    is( $r->[7], 'Pupil of',           '100: $j last' );
    check_combined(
        '100', '100: $a+$c+$d+$j',
        a => 'Reynolds, Joshua',
        c => 'Sir',
        d => '1723-1792',
        j => 'Pupil of'
    )
}

{
# render: 100 ## $a Hecht, Ben $d 1893-1964 $e writing $e direction $e production
    my $r = _decorate(
        '100', 'postfix',
        a => 'Hecht, Ben',
        d => '1893-1964',
        e => 'writing',
        e => 'direction',
        e => 'production'
    );
    is( $r->[1], 'Hecht, Ben, ', '100: $a before $d' );
    is( $r->[3], '1893-1964, ',  '100: $d before $e' );
    is( $r->[5], 'writing, ',    '100: $e1 before $e2' );
    is( $r->[7], 'direction, ',  '100: $e2 before $e3' );
    is( $r->[9], 'production',   '100: $e3 last' );
    check_combined(
        '100', '100: $a+$d+3x$e',
        a => 'Hecht, Ben',
        d => '1893-1964',
        e => 'writing',
        e => 'direction',
        e => 'production'
    )
}

{
    # render: 100 ## $a Beethoven, Ludwig van $d 1770-1827 $c Spirit
    my $r = _decorate(
        '100', 'postfix',
        a => 'Beethoven, Ludwig van',
        d => '1770-1827',
        c => 'Spirit'
    );
    is( $r->[1], 'Beethoven, Ludwig van, ', '100: $a before $d' );
    is( $r->[3], '1770-1827, ',             '100: $d before $c' );
    is( $r->[5], 'Spirit',                  '100: $c last' );
    check_combined(
        '100', '100: $a+$d+$c',
        a => 'Beethoven, Ludwig van',
        d => '1770-1827',
        c => 'Spirit'
    )
}

{
    # render: 100 ## $a Beeton $c Mrs. $q Isabella Mary $d 1836-1865
    my $r = _decorate(
        '100', 'postfix',
        a => 'Beeton',
        c => 'Mrs.',
        q => 'Isabella Mary',
        d => '1836-1865'
    );
    is( $r->[1], 'Beeton, ',          '100: $a before $c' );
    is( $r->[3], 'Mrs.',              '100: $c unchanged (q not in pchrs)' );
    is( $r->[5], '(Isabella Mary), ', '100: $q wrapped + before $d' );
    is( $r->[7], '1836-1865',         '100: $d last' );
    check_combined(
        '100', '100: $a+$c+$q+$d',
        a => 'Beeton',
        c => 'Mrs.',
        q => 'Isabella Mary',
        d => '1836-1865'
    )
}

{
    # render: 100 ## $a H. D. $q Hilda Doolittle $d 1886-1961
    my $r = _decorate(
        '100', 'postfix',
        a => 'H. D.',
        q => 'Hilda Doolittle',
        d => '1886-1961'
    );
    is( $r->[1], 'H. D.',               '100: $a unchanged (q not in pchrs)' );
    is( $r->[3], '(Hilda Doolittle), ', '100: $q wrapped + before $d' );
    is( $r->[5], '1886-1961',           '100: $d last' );
    check_combined(
        '100', '100: $a+$q+$d',
        a => 'H. D.',
        q => 'Hilda Doolittle',
        d => '1886-1961'
    )
}

{
    # render: 100 ## $a Charles Edward $b III $d 1720-1788
    my $r = _decorate(
        '100', 'postfix',
        a => 'Charles Edward',
        b => 'III',
        d => '1720-1788'
    );
    is( $r->[1], 'Charles Edward. ', '100: $a before $b' );
    is( $r->[3], 'III, ',            '100: $b before $d' );
    is( $r->[5], '1720-1788',        '100: $d last' );
    check_combined(
        '100', '100: $a+$b+$d',
        a => 'Charles Edward',
        b => 'III',
        d => '1720-1788'
    )
}

# ===== 700 =====
{
    # render: 700 ## $a Salamín C., Marcel A.
    my $r = _decorate( '700', 'postfix', a => 'Salamín C., Marcel A.' );
    is( $r->[1], 'Salamín C., Marcel A.', '700: $a alone' );
    check_combined( '700', '700: $a alone', a => 'Salamín C., Marcel A.' )
}

{
# render: 700 ## $a Charles Edward $c Prince, grandson of James II, King of England $d 1720-1788
    my $r = _decorate(
        '700', 'postfix',
        a => 'Charles Edward',
        c => 'Prince, grandson of James II, King of England',
        d => '1720-1788'
    );
    is( $r->[1], 'Charles Edward, ', '700: $a before $c' );
    is(
        $r->[3],
        'Prince, grandson of James II, King of England, ',
        '700: $c before $d'
    );
    is( $r->[5], '1720-1788', '700: $d last' );
    check_combined(
        '700', '700: $a+$c+$d',
        a => 'Charles Edward',
        c => 'Prince...',
        d => '1720-1788'
    )
}

{
    # render: 700 ## $a Shakespeare, William $d 1564-1616
    my $r = _decorate(
        '700', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616'
    );
    is( $r->[1], 'Shakespeare, William, ', '700: $a before $d' );
    is( $r->[3], '1564-1616',              '700: $d last' );
    check_combined(
        '700', '700: $a+$d',
        a => 'Shakespeare, William',
        d => '1564-1616'
    )
}

# ===== 600 =====
{
    # render: 600 ## $a Shakespeare, William $d 1564-1616 $v Biography
    my $r = _decorate(
        '600', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        v => 'Biography'
    );
    is( $r->[1], 'Shakespeare, William, ', '600: $a before $d' );
    is( $r->[3], '1564-1616', '600: $d unchanged (v not in pchrs)' );
    is( $r->[5], 'Biography', '600: $v last' );
    check_combined(
        '600', '600: $a+$d+$v',
        a => 'Shakespeare, William',
        d => '1564-1616',
        v => 'Biography'
    )
}

{
    # render: 600 ## $a Shakespeare, William $d 1564-1616 $x Criticism
    my $r = _decorate(
        '600', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        x => 'Criticism'
    );
    is( $r->[1], 'Shakespeare, William, ', '600: $a before $d' );
    is( $r->[3], '1564-1616', '600: $d unchanged (x not in pchrs)' );
    is( $r->[5], 'Criticism', '600: $x last' );
    check_combined(
        '600', '600: $a+$d+$x',
        a => 'Shakespeare, William',
        d => '1564-1616',
        x => 'Criticism'
    )
}

{
    # render: 600 ## $a Shakespeare, William $d 1564-1616 $v B $x E $y 17 $z E
    my $r = _decorate(
        '600', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        v => 'B',
        x => 'E',
        y => '17',
        z => 'E'
    );
    is( $r->[1],  'Shakespeare, William, ', '600: $a before $d' );
    is( $r->[3],  '1564-1616', '600: $d unch (v/x/y/z not in pchrs)' );
    is( $r->[5],  'B',         '600: $v unch' );
    is( $r->[7],  'E',         '600: $x unch' );
    is( $r->[9],  '17',        '600: $y unch' );
    is( $r->[11], 'E',         '600: $z last' );
    check_combined(
        '600', '600: $a+$d+$v+$x+$y+$z',
        a => 'S, W',
        d => '1564-1616',
        v => 'B',
        x => 'E',
        y => '17',
        z => 'E'
    )
}

{
    # render: 600 ## $a Moses $c (Biblical leader) $x Biography
    my $r = _decorate(
        '600', 'postfix',
        a => 'Moses',
        c => '(Biblical leader)',
        x => 'Biography'
    );
    is( $r->[1], 'Moses, ',           '600: $a before $c' );
    is( $r->[3], '(Biblical leader)', '600: $c unch (x not in pchrs)' );
    is( $r->[5], 'Biography',         '600: $x last' );
    check_combined(
        '600', '600: $a+$c+$x',
        a => 'Moses',
        c => '(Biblical leader)',
        x => 'Biography'
    )
}

{
    # render: 600 ## $a Bible $k Selections $l English
    my $r = _decorate(
        '600', 'postfix',
        a => 'Bible',
        k => 'Selections',
        l => 'English'
    );
    is( $r->[1], 'Bible. ',      '600: $a before $k' );
    is( $r->[3], 'Selections. ', '600: $k before $l' );
    is( $r->[5], 'English',      '600: $l last' );
    check_combined(
        '600', '600: $a+$k+$l',
        a => 'Bible',
        k => 'Selections',
        l => 'English'
    )
}

# ===== 800 =====
{
    # render: 800 ## $a Shakespeare, William $t Works $v v. 1
    my $r = _decorate(
        '800', 'postfix',
        a => 'Shakespeare, William',
        t => 'Works',
        v => 'v. 1'
    );
    is( $r->[1], 'Shakespeare, William. ', '800: $a before $t' );
    is( $r->[3], 'Works ;',                '800: $t before $v' );
    is( $r->[5], 'v. 1',                   '800: $v last' );
    check_combined(
        '800', '800: $a+$t+$v',
        a => 'Shakespeare, William',
        t => 'Works',
        v => 'v. 1'
    )
}

{
    # render: 800 ## $a Shakespeare, William $d 1564-1616 $t Works $v v. 1
    my $r = _decorate(
        '800', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        t => 'Works',
        v => 'v. 1'
    );
    is( $r->[1], 'Shakespeare, William, ', '800: $a before $d' );
    is( $r->[3], '1564-1616. ',            '800: $d before $t (key t fires)' );
    is( $r->[5], 'Works ;',                '800: $t before $v' );
    is( $r->[7], 'v. 1',                   '800: $v last' );
    check_combined(
        '800', '800: $a+$d+$t+$v',
        a => 'Shakespeare, William',
        d => '1564-1616',
        t => 'Works',
        v => 'v. 1'
    )
}

{
# render: 700 ## $a Tolkien, J. R. R. $q John Roland Reuel $d 1892-1973 $t Lord of the rings $n 2 $p Two towers
# Actual §5.5 example (Tolkien): $t Lord of the rings. $n 2, $p Two towers.
# $n -> '. ' and $p -> ', ' per the LoC/PCC spec (aligned 2026-08-31).
# NOTE: we keep the inverted name in $a (no $a/$h split).
    my $r = _decorate(
        '700', 'postfix',
        a => 'Tolkien, J. R. R.',
        q => 'John Roland Reuel',
        d => '1892-1973',
        t => 'Lord of the rings',
        n => '2',
        p => 'Two towers'
    );
    is( $r->[1], 'Tolkien, J. R. R.', '700 Tolkien: $a unchanged' );
    is(
        $r->[3],
        '(John Roland Reuel), ',
        '700 Tolkien: $q wrapped + ", " for $d'
    );
    is( $r->[5], '1892-1973. ', '700 Tolkien: $d gets ". " for $t' );
    is(
        $r->[7],
        'Lord of the rings. ',
        '700 Tolkien: $t gets ". " for $n (spec)'
    );
    is( $r->[9],  '2, ',        '700 Tolkien: $n gets ", " for $p (spec)' );
    is( $r->[11], 'Two towers', '700 Tolkien: $p last' );
    check_combined(
        '700', '700 Tolkien: $a+$q+$d+$t+$n+$p',
        a => 'Tolkien, J. R. R.',
        q => 'John Roland Reuel',
        d => '1892-1973',
        t => 'Lord of the rings',
        n => '2',
        p => 'Two towers'
    )
}

# ===== Title-portion subfields (700/800 with $t) =====
{
   # render: 700 ## $a Beethoven, Ludwig van $d 1770-1827 $t Sonatas $o arranged
    my $r = _decorate(
        '700', 'postfix',
        a => 'Beethoven, Ludwig van',
        d => '1770-1827',
        t => 'Sonatas',
        o => 'arranged'
    );
    is( $r->[1], 'Beethoven, Ludwig van, ', '700: $a before $d' );
    is( $r->[3], '1770-1827. ',             '700: $d before $t' );
    is( $r->[5], 'Sonatas; ',               '700: $t before $o' );
    is( $r->[7], 'arranged',                '700: $o last' );
    check_combined(
        '700', '700: $a+$d+$t+$o',
        a => 'Beethoven, L',
        d => '1770-1827',
        t => 'Sonatas',
        o => 'arranged'
    )
}

{
    # render: 700 ## $a Shakespeare, William $d 1564-1616 $t Works $s 1978
    my $r = _decorate(
        '700', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        t => 'Works',
        s => '1978'
    );
    is( $r->[1], 'Shakespeare, William, ', '700: $a before $d' );
    is( $r->[3], '1564-1616. ',            '700: $d before $t' );
    is( $r->[5], 'Works. ',                '700: $t before $s' );
    is( $r->[7], '1978',                   '700: $s last' );
    check_combined(
        '700', '700: $a+$d+$t+$s',
        a => 'Shakespeare, W',
        d => '1564-1616',
        t => 'Works',
        s => '1978'
    )
}

{
    # render: 700 ## $a Beethoven, Ludwig van $d 1770-1827 $t Sonatas $m piano
    my $r = _decorate(
        '700', 'postfix',
        a => 'Beethoven, Ludwig van',
        d => '1770-1827',
        t => 'Sonatas',
        m => 'piano'
    );
    is( $r->[1], 'Beethoven, Ludwig van, ', '700: $a before $d' );
    is( $r->[3], '1770-1827. ',             '700: $d before $t' );
    is( $r->[5], 'Sonatas, ',               '700: $t before $m' );
    is( $r->[7], 'piano',                   '700: $m last' );
    check_combined(
        '700', '700: $a+$d+$t+$m',
        a => 'Beethoven, L',
        d => '1770-1827',
        t => 'Sonatas',
        m => 'piano'
    )
}

{
    # render: 700 ## $a Beethoven, Ludwig van $d 1770-1827 $t Sonatas $r E major
    my $r = _decorate(
        '700', 'postfix',
        a => 'Beethoven, Ludwig van',
        d => '1770-1827',
        t => 'Sonatas',
        r => 'E major'
    );
    is( $r->[1], 'Beethoven, Ludwig van, ', '700: $a before $d' );
    is( $r->[3], '1770-1827. ',             '700: $d before $t' );
    is( $r->[5], 'Sonatas, ',               '700: $t before $r' );
    is( $r->[7], 'E major',                 '700: $r last' );
    check_combined(
        '700', '700: $a+$d+$t+$r',
        a => 'Beethoven, L',
        d => '1770-1827',
        t => 'Sonatas',
        r => 'E major'
    )
}

{
    # render: 700 ## $a Shakespeare, William $d 1564-1616 $t Works $f 1978
    my $r = _decorate(
        '700', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        t => 'Works',
        f => '1978'
    );
    is( $r->[1], 'Shakespeare, William, ', '700: $a before $d' );
    is( $r->[3], '1564-1616. ',            '700: $d before $t' );
    is( $r->[5], 'Works. ',                '700: $t before $f' );
    is( $r->[7], '1978',                   '700: $f last' );
    check_combined(
        '700', '700: $a+$d+$t+$f',
        a => 'Shakespeare, W',
        d => '1564-1616',
        t => 'Works',
        f => '1978'
    )
}

{
    # render: 700 ## $a Shakespeare, William $d 1564-1616 $t Works $l German
    my $r = _decorate(
        '700', 'postfix',
        a => 'Shakespeare, William',
        d => '1564-1616',
        t => 'Works',
        l => 'German'
    );
    is( $r->[1], 'Shakespeare, William, ', '700: $a before $d' );
    is( $r->[3], '1564-1616. ',            '700: $d before $t' );
    is( $r->[5], 'Works. ',                '700: $t before $l' );
    is( $r->[7], 'German',                 '700: $l last' );
    check_combined(
        '700', '700: $a+$d+$t+$l',
        a => 'Shakespeare, W',
        d => '1564-1616',
        t => 'Works',
        l => 'German'
    )
}

done_testing();
