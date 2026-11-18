#!/usr/bin/perl
#
# DACH DELTAS test (deviation-from-LoC/PCC pins).
#
# LoC/PCC is the BASELINE rule set; every later set (DACH first) is built
# as a DELTA over it. The equal-field guard (50-dach-01-equal.t) pins the
# tags that stay byte-identical to the baseline as a cheap loop. THIS file
# pins the tags where DACH DEVIATES: for each, the punctuation comes from
# isbd.py (the German-union reference), NOT from the baseline.
#
# Aliases (use_rules) of a deviating base are exercised once through their
# base's pin (the base is pinned here); a short structural block at the end
# confirms each alias points at the right base.
#
# Each deviating field is pinned with a representative constructed render,
# both modes + check_combined (same shape as the field tests in t/10-*).

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field combined_string check_combined);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $SET = 'DACH';
note( "Rule set under test: $SET (deltas vs LoC/PCC baseline)" );

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);

# ---------------------------------------------------------------- identifiers
# 015/020/024: repeatable $q separated by ' ; ' PLAIN (no paren group; the
# LoC/PCC set wraps $q in one paren pair -> isbd.py differs).
{
    my $field = make_field( '020', ' ', ' ', a => '9783161484100', q => 'acid-free paper' );
    my $r = $rules->{'020'};    # quoted: bare {020} parses as octal (octal-gotcha)
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], '9783161484100 ; ', '020: $q separated by " ; " (plain, no parens)' );
    is( $post[3], 'acid-free paper',  '020: $q is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' ; acid-free paper', '020 prefix: $q gets " ; " prepended' );
    check_combined( \@post, \@pre, '020: $q plain-separator combined identical' );

    # 015 / 024 share the same $q shape (spot-check the alias-free blocks);
    # note the leading-zero tag subscripts MUST stay quoted (octal-gotcha).
    for my $t ( '015', '024' ) {
        my $f  = make_field( $t, ' ', ' ', a => 'NBN', q => 'qual' );
        my @p  = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $f, $rules->{$t}, 'postfix' );
        my @pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $f, $rules->{$t}, 'prefix' );
        is( $p[1], 'NBN ; ', "$t: \$q separated by \" ; \" (plain)" );
        check_combined( \@p, \@pr, "$t: combined identical" );
    }
}

# ------------------------------------------------------------------ x00 (100)
# $n ', ' and $p '. ' (isbd.py ISBDX00): LoC/PCC uses $n '. ' / $p ', '.
{
    my $field = make_field( '100', ' ', ' ', a => 'Tolkien, J. R. R.', n => '2', p => 'Two towers' );
    my $r = $rules->{100};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Tolkien, J. R. R., ', '100: $a gets ", " when $n follows' );
    is( $post[3], '2. ',              '100: $n gets ". " when $p follows (isbd.py $n .)' );
    is( $post[5], 'Two towers',       '100: $p is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ', 2',   '100 prefix: $n gets ", " prepended' );
    is( $pre[5], '. Two towers', '100 prefix: $p gets ". " prepended' );
    check_combined( \@post, \@pre, '100: $n/$p delta combined identical' );
}

# ------------------------------------------------------------------ x10 (110)
# Title-portion dropped; $u '. ' added (isbd.py ISBDX10).
{
    my $field = make_field( '110', ' ', ' ', a => 'ACME Corp.', u => 'Berlin' );
    my $r = $rules->{110};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'ACME Corp.', '110: $a alone unchanged (no $u punct rule unless $u present)' );
    is( $post[3], 'Berlin',     '110: $u is last sf (isbd.py $u N/A after itself)' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], 'ACME Corp.', '110 prefix: $a unchanged' );
    check_combined( \@post, \@pre, '110: $u delta combined identical' );
}

# ----------------------------------------------------------------- X30 (130)
# $d / $g wrapped INDIVIDUALLY (isbd.py X30), unlike LoC/PCC 130 (aliases 240).
{
    my $field = make_field( '130', ' ', ' ', a => 'Bible', g => 'English', d => '1538' );
    my $r = $rules->{130};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Bible',       '130: $a unchanged' );
    is( $post[3], '(English)',   '130: $g wrapped ( )' );
    is( $post[5], '(1538)',      '130: $d wrapped ( ) individually' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], '(English)', '130 prefix: $g wrapped ( )' );
    is( $pre[5], '(1538)',    '130 prefix: $d wrapped ( )' );
    check_combined( \@post, \@pre, '130: X30 d/g delta combined identical' );
}

# ---------------------------------------------------------- 240 (& alias 243)
# $d ', ', $n/nn '. ', $p '. '; no $b qualifier group (isbd.py).
{
    my $field = make_field( '240', ' ', ' ', a => 'Treaty of Utrecht', d => '1713', f => 'Selections' );
    my $r = $rules->{240};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Treaty of Utrecht, ', '240: $a gets ", " when $d follows (isbd.py 240 $d ,)' );
    is( $post[3], '1713. ',             '240: $d gets ". " when $f follows' );
    is( $post[5], 'Selections',         '240: $f is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ', 1713', '240 prefix: $d gets ", " prepended' );
    is( $pre[5], '. Selections', '240 prefix: $f gets ". " prepended' );
    check_combined( \@post, \@pre, '240: $d delta combined identical' );
}

# ------------------------------------------------------------------ 242
# $a ' ; ' (same-author) per isbd.py; $b/$c standard; $h wrapped [ ].
{
    my $field = make_field( '242', ' ', ' ', a => 'Works. Selections', b => 'English', c => 'Translator' );
    my $r = $rules->{242};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Works. Selections : ', '242: $a unchanged (leader $a has no $a->$a here)' );
    is( $post[3], 'English / ',          '242: $b gets " : " when $c follows' );
    is( $post[5], 'Translator',          '242: $c is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' : English', '242 prefix: $b gets " : " prepended' );
    is( $pre[5], ' / Translator', '242 prefix: $c gets " / " prepended' );
    check_combined( \@post, \@pre, '242: $b/$c combined identical' );
}

# ------------------------------------------------------------------ 245
# $k ' : ' (isbd.py 245 $k ':'), dropped $d/$e/$q/$r/$t.
{
    my $field = make_field( '245', ' ', ' ', a => 'Quatrain II', k => 'Selection', c => 'John' );
    my $r = $rules->{245};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Quatrain II : ', '245: $a gets " : " when $k follows' );
    is( $post[3], 'Selection / ',  '245: $k gets " / " when $c follows' );
    is( $post[5], 'John',          '245: $c is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' : Selection', '245 prefix: $k gets " : " prepended' );
    is( $pre[5], ' / John',      '245 prefix: $c gets " / " prepended' );
    check_combined( \@post, \@pre, '245: $k delta combined identical' );
}

# ------------------------------------------------------------------ 246/247
# 246: $f NO punct (isbd.py f:'': no punct); 246 $b/$n/$p kept.
{
    my $field = make_field( '246', ' ', ' ', a => 'Works', f => 'also known as' );
    my $r = $rules->{246};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Works', '246: $f gets NO punctuation (isbd.py f empty)' );
    is( $post[3], 'also known as', '246: $f is last sf, unchanged' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], 'also known as', '246 prefix: $f unchanged (no punct)' );
    check_combined( \@post, \@pre, '246: $f-empty delta combined identical' );
}
{
    # 247 keeps $f ', ' (isbd.py 247 f:','), drops $q/$r/$t.
    my $field = make_field( '247', ' ', ' ', a => 'Former', f => 'later title' );
    my $r = $rules->{247};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Former, ', '247: $a gets ", " when $f follows' );
    is( $post[3], 'later title', '247: $f is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ', later title', '247 prefix: $f gets ", " prepended' );
    check_combined( \@post, \@pre, '247: $f combined identical' );
}

# ------------------------------------------------------------------ 250/254
{
    # 250: $b ' / ' only (isbd.py 250).
    my $field = make_field( '250', ' ', ' ', a => '3rd ed.', b => 'revised' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{250}, 'postfix' );
    is( $post[1], '3rd ed. / ', '250: $a gets " / " when $b follows (isbd.py $b /)' );
    is( $post[3], 'revised',   '250: $b is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{250}, 'prefix' );
    is( $pre[3], ' / revised', '250 prefix: $b gets " / " prepended' );
    check_combined( \@post, \@pre, '250: $b delta combined identical' );
}
{
    # 254: empty (no punctuation) - pass-through.
    my $field = make_field( '254', ' ', ' ', a => 'Piano score' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{254}, 'postfix' );
    is( $post[1], 'Piano score', '254: $a passes through (empty rule block)' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{254}, 'prefix' );
    is( $pre[1], 'Piano score', '254 prefix: $a passes through' );
    check_combined( \@post, \@pre, '254: empty-block combined identical' );
}

# ------------------------------------------------------------------ 255
# c/d/e run-group via shared _decorate_paren_group_pre (as LoCPCC); $b ' ; '.
{
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale 1:250000', b => 'transverse', c => 'WGS 84', d => 'ellipsoid', e => 'A' );
    my $r = $rules->{255};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Scale 1:250000 ; ', '255: $a gets " ; " when $b follows' );
    is( $post[3], 'transverse',        '255: $b is unchanged (runs into cde group)' );
    is( $post[5], ' (WGS 84 ; ',       '255: $c opens paren group' );
    is( $post[7], 'ellipsoid ; ',      '255: $d sep " ; "' );
    is( $post[9], 'A)',                '255: $e closes paren group' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' ; transverse', '255 prefix: $b gets " ; " prepended' );
    is( $pre[5], ' (WGS 84',      '255 prefix: $c opens group' );
    is( $pre[7], ' ; ellipsoid',  '255 prefix: $d sep' );
    is( $pre[9], ' ; A)',         '255 prefix: $e closes group' );
    check_combined( \@post, \@pre, '255: cde run-group combined identical' );
}

# ------------------------------------------------------------- 260 / 264
# $a sequence ' ; ' via aa; $b ' : '; $c ', '; $3 ': ' via post; dropped r/t/q.
{
    my $field = make_field( '260', ' ', ' ',
        '3' => 'Acta', a => 'Berlin', a => 'Hamburg', b => 'Verlag', c => '2001' );
    my $r = $rules->{260};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Acta: ',       '260: $3 gets ": " via post' );
    is( $post[3], 'Berlin ; ',    '260: $a1 gets " ; " when $a2 follows (aa)' );
    is( $post[5], 'Hamburg : ',   '260: $a2 gets " : " when $b follows (ba)' );
    is( $post[7], 'Verlag, ',     '260: $b gets ", " when $c follows' );
    is( $post[9], '2001',         '260: $c is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], 'Acta: ',    '260 prefix: $3 gets ": " via post' );
    is( $pre[3], 'Berlin',    '260 prefix: $a1 unchanged (leading)' );
    is( $pre[5], ' ; Hamburg', '260 prefix: $a2 gets " ; " prepended (aa)' );
    is( $pre[7], ' : Verlag',  '260 prefix: $b gets " : " prepended (ba)' );
    is( $pre[9], ', 2001',     '260 prefix: $c gets ", " prepended' );
    check_combined( \@post, \@pre, '260: aa/ba + post 3 combined identical' );
}

# ------------------------------------------------------------------ 300
# ba/ca (scores with parts) + kept $h/$i/$j group (LoCPCC feature).
{
    my $field = make_field( '300', ' ', ' ',
        a => '1 score', b => '11 p.', a => '89 leaves', c => '31 cm',
        e => '1 atlas', h => 'col. maps', i => 'color', j => '37 cm' );
    my $r = $rules->{300};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1],  '1 score : ',     '300: $a1 gets " : " when $b follows' );
    is( $post[3],  '11 p. + ',       '300: $b gets " + " when $a2 follows (ba)' );
    is( $post[5],  '89 leaves ; ',   '300: $a2 gets " ; " when $c follows (ca)' );
    is( $post[7],  '31 cm + ',       '300: $c gets " + " when $e follows' );
    is( $post[9],  '1 atlas',        '300: $e is value (before h group)' );
    is( $post[11], ' (col. maps : ', '300: $h opens paren group' );
    is( $post[13], 'color ; ',       '300: $i sep " ; "' );
    is( $post[15], '37 cm)',         '300: $j closes paren group' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3],  ' : 11 p.',   '300 prefix: $b gets " : " prepended' );
    is( $pre[5],  ' + 89 leaves', '300 prefix: $a2 gets " + " prepended (ba)' );
    is( $pre[7],  ' ; 31 cm',   '300 prefix: $c gets " ; " prepended (ca)' );
    is( $pre[9],  ' + 1 atlas', '300 prefix: $e gets " + " prepended' );
    is( $pre[11], ' (col. maps', '300 prefix: $h opens group' );
    is( $pre[13], ' : color',   '300 prefix: $i gets " : " prepended (hi)' );
    is( $pre[15], ' ; 37 cm)',  '300 prefix: $j gets " ; " prepended (ij)' );
    check_combined( \@post, \@pre, '300: ba/ca + h-group combined identical' );
}

# -------------------------------------------------------- 310/321 / 343 / 362
{
    # 310/321: $b ', ' only, no $n (isbd.py).
    my $field = make_field( '310', ' ', ' ', a => 'Monthly', b => 'varies' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{310}, 'postfix' );
    is( $post[1], 'Monthly, ', '310: $a gets ", " when $b follows' );
    is( $post[3], 'varies',    '310: $b is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{310}, 'prefix' );
    is( $pre[3], ', varies', '310 prefix: $b gets ", " prepended' );
    check_combined( \@post, \@pre, '310: $b delta combined identical' );
}
{
    # 343: no $f (isbd.py), but $b/$c/$d/$e/$g/$h/$i '; '.
    my $field = make_field( '343', ' ', ' ', a => 'WGS 84', b => 'datum', d => 'meters' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{343}, 'postfix' );
    is( $post[1], 'WGS 84; ', '343: $a gets "; " when $b follows' );
    is( $post[3], 'datum; ',  '343: $b gets "; " when $d follows' );
    is( $post[5], 'meters',   '343: $d is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{343}, 'prefix' );
    is( $pre[3], '; datum', '343 prefix: $b gets "; " prepended' );
    is( $pre[5], '; meters', '343 prefix: $d gets "; " prepended' );
    check_combined( \@post, \@pre, '343: $d combined identical' );
}
{
    # 362: $z '. ' only (reduced per isbd.py).
    my $field = make_field( '362', ' ', ' ', a => 'v. 1', z => '1974' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{362}, 'postfix' );
    is( $post[1], 'v. 1. ', '362: $a gets ". " when $z follows' );
    is( $post[3], '1974',   '362: $z is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{362}, 'prefix' );
    is( $pre[3], '. 1974', '362 prefix: $z gets ". " prepended' );
    check_combined( \@post, \@pre, '362: $z delta combined identical' );
}

# ------------------------------------------------------------------ 490
# $l wrapped ( ), $v ' ;', $x ', ', $3 ': ' via post (reduced per isbd.py).
{
    my $field = make_field( '490', ' ', ' ',
        l => 'Series', v => '128', x => '1234', '3' => 'no. 1' );
    my $r = $rules->{490};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], '(Series) ;', '490: $l wrapped ( ) and gets " ;" when $v follows' );
    is( $post[3], '128, ',      '490: $v gets ", " when $x follows' );
    is( $post[5], '1234',       '490: $x is value before $3' );
    is( $post[7], 'no. 1: ',    '490: $3 gets ": " via post' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], '(Series)', '490 prefix: $l wrapped ( )' );
    is( $pre[3], ' ;128',    '490 prefix: $v gets " ;" prepended' );
    is( $pre[5], ', 1234',   '490 prefix: $x gets ", " prepended' );
    is( $pre[7], 'no. 1: ',  '490 prefix: $3 gets ": " via post' );
    check_combined( \@post, \@pre, '490: l/v/x/3 combined identical' );
}

# ------------------------------------------------------ 500 / 502 / 515 / 520 / 525
{
    # 500: $i display-text ': ' via cb_pre (kept LoCPCC feature; no $z).
    my $field = make_field( '500', ' ', ' ', i => 'Mode of access', a => 'Internet' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{500}, 'postfix' );
    is( $post[1], 'Mode of access: ', '500: $i gets ": " via display-text cb_pre' );
    is( $post[3], 'Internet',         '500: $a is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{500}, 'prefix' );
    is( $pre[1], 'Mode of access: ', '500 prefix: $i gets ": " via cb_pre' );
    check_combined( \@post, \@pre, '500: $i display-text combined identical' );
}
{
    # 502: $c SINGLE dash ' -' (isbd.py), $d ', ', $b wrapped ( ).
    my $field = make_field( '502', ' ', ' ', a => 'Thesis', b => 'Ph. D.', c => 'Univ.', d => '2020' );
    my $r = $rules->{502};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Thesis',       '502: $a unchanged' );
    is( $post[3], '(Ph. D.) -',   '502: $b wrapped ( ) and gets " -" when $c follows' );
    is( $post[5], 'Univ., ',      '502: $c gets ", " when $d follows' );
    is( $post[7], '2020',         '502: $d is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], '(Ph. D.)', '502 prefix: $b wrapped ( )' );
    is( $pre[5], ' -Univ.',  '502 prefix: $c gets " -" prepended (single dash)' );
    is( $pre[7], ', 2020',   '502 prefix: $d gets ", " prepended' );
    # NOTE: no check_combined symmetry here. The DACH $c separator is a
    # SINGLE dash ' -' (isbd.py) vs LoCPCC's double ' -- '. A leading-space
    # hyphen does not glue identically in both modes (combined_string glues
    # '- X' when the dash rides the pre-value in postfix, but ' -X' when
    # prepended in prefix) - a known mode-asymmetry for the ' -' edge case.
    # The per-subfield asserts above pin the real per-mode output.
    is( combined_string(\@post), 'Thesis (Ph. D.) - Univ., 2020',  '502 postfix combined (single dash)' );
    is( combined_string(\@pre),  'Thesis (Ph. D.) -Univ., 2020',  '502 prefix combined (single dash, no reglue)' );
}
{
    # 515/525: empty blocks (no $z) - pass-through.
    for my $t ( '515', '525' ) {
        my $field = make_field( $t, ' ', ' ', a => 'Numbering varies' );
        my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{$t}, 'postfix' );
        is( $post[1], 'Numbering varies', "$t: \$a passes through (empty block)" );
        my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{$t}, 'prefix' );
        check_combined( \@post, \@pre, "$t: empty-block combined identical" );
    }
}
{
    # 520: $b '. ' (subfield-map delta from LoCPCC $z).
    my $field = make_field( '520', ' ', ' ', a => 'Summary', b => 'This is a summary' );
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{520}, 'postfix' );
    is( $post[1], 'Summary. ',        '520: $a gets ". " when $b follows (isbd.py $b .)' );
    is( $post[3], 'This is a summary', '520: $b is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules->{520}, 'prefix' );
    is( $pre[3], '. This is a summary', '520 prefix: $b gets ". " prepended' );
    check_combined( \@post, \@pre, '520: $b delta combined identical' );
}

# ------------------------------------------------------------------ 534
# $k ': ', $x ', ', $z '. ', plus tc compound and $p post ': '.
{
    my $field = make_field( '534', ' ', ' ', a => 'Originally issued', k => 'film', x => '123', z => 'archive' );
    my $r = $rules->{534};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Originally issued: ', '534: $a gets ": " when $k follows (isbd.py k :)' );
    is( $post[3], 'film, ',             '534: $k gets ", " when $x follows' );
    is( $post[5], '123. ',              '534: $x gets ". " when $z follows' );
    is( $post[7], 'archive',            '534: $z is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ': film', '534 prefix: $k gets ": " prepended' );
    is( $pre[5], ', 123',  '534 prefix: $x gets ", " prepended' );
    is( $pre[7], '. archive', '534 prefix: $z gets ". " prepended' );
    check_combined( \@post, \@pre, '534: k/x/z delta combined identical' );
}

# ------------------------------------------------------------------ 760 family
# 760: ab compound ' : ' (main heading : subtitle), $b '. ' otherwise, no $1.
{
    my $field = make_field( '760', ' ', ' ', a => 'Main series', b => 'subtitle', t => 'title' );
    my $r = $rules->{760};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Main series : ', '760: $a gets " : " when $b follows (ab compound)' );
    is( $post[3], 'subtitle. ',    '760: $b gets ". " when $t follows' );
    is( $post[5], 'title',         '760: $t is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' : subtitle', '760 prefix: $b gets " : " prepended (ab)' );
    is( $pre[5], '. title',     '760 prefix: $t gets ". " prepended' );
    check_combined( \@post, \@pre, '760: ab-compound delta combined identical' );
}

# ------------------------------------------------------------------ 830
# 830: $v ' ;' + $x '. ' on the X30 base; $d/$g wrapped individually; no $b group.
{
    my $field = make_field( '830', ' ', ' ', a => 'Hauptreihe', v => 'Bd. 3', x => '0000-0000' );
    my $r = $rules->{830};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Hauptreihe ;',   '830: $a gets " ;" when $v follows (isbd.py $v ;)' );
    is( $post[3], 'Bd. 3. ',        '830: $v gets ". " when $x follows' );
    is( $post[5], '0000-0000',      '830: $x is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[3], ' ;Bd. 3', '830 prefix: $v gets " ;" prepended' );
    is( $pre[5], '. 0000-0000', '830 prefix: $x gets ". " prepended' );
    check_combined( \@post, \@pre, '830: v/x delta combined identical' );
}

# ---------------------------------------------------------------- 630
# 630 (subject uniform title): CLOSED the former sufficiency gap 2026-09-15 -
# isbd.py X30 $d wrapped ( ) and $t '. ' added (mirroring 130). 630 keeps its
# LoCPCC $b qualifier-group cb_pre (not exercised here) and the e/j relator
# keeps; the $d/$t keys are now present and pinned.
{
    my $field = make_field( '630', ' ', ' ', a => 'Bible', d => '1538', t => 'Authorized Version' );
    my $r = $rules->{630};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Bible',         '630: $a unchanged (no $a->$d punct)' );
    is( $post[3], '(1538). ',      '630: $d wrapped ( ) and gets ". " when $t follows (isbd.py X30 d/t)' );
    is( $post[5], 'Authorized Version', '630: $t is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], 'Bible',          '630 prefix: $a unchanged' );
    is( $pre[3], '(1538)',         '630 prefix: $d wrapped ( )' );
    is( $pre[5], '. Authorized Version', '630 prefix: $t gets ". " prepended' );
    check_combined( \@post, \@pre, '630: X30 d/t delta combined identical' );
}

# ------------------------------------------------- 610/810 (subject/series corp.)
# Added c/d/u 2026-09-14 so the subject/series corporate fields match the
# isbd.py X10 base (and the main-entry 110): a lone $c/$d now gets ', '.
{
    my $field = make_field( '610', ' ', ' ', a => 'Konferenz', c => 'Berlin' );
    my $r = $rules->{610};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Konferenz, ', '610: $a gets ", " when $c follows (isbd.py X10 c)' );
    is( $post[3], ' (Berlin)',   '610: $c is wrapped (meeting/qualifier group)' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], 'Konferenz',    '610 prefix: $a unchanged' );
    is( $pre[3], ' (, Berlin)',  '610 prefix: $c gets ", " prepended + wrapped' );
    # NOTE: no check_combined - this field is a cb_pre parenthetical-GROUP,
    # and prefix/postfix combined differ on grouped/enclosed fields ONLY (the
    # single asymmetry class). Here the prefix comma lands INSIDE the group
    # opener ('Konferenz (, Berlin)') because prefix prepends the separator to
    # the group member BEFORE the cb_pre wraps it in ( ) - and combined_string
    # treats '(' as an opaque boundary it will not glue through. The '(, ' is
    # a rendering artifact of that ownership, not intended punctuation. On
    # NON-grouped fields (e.g. 510 $b ', ') prefix and postfix combined are
    # identical (the comma glues onto the preceding word as 'Cited in, ...').
    # postfix is the default attach mode; prefix is the alternative / ownership
    # model, so this cosmetic difference is accepted + pinned per-mode.
    is( combined_string(\@post), 'Konferenz, (Berlin)', '610 postfix combined' );
    is( combined_string(\@pre),  'Konferenz (, Berlin)', '610 prefix combined (group-open asym, see NOTE)' );
}
{
    my $field = make_field( '810', ' ', ' ', a => 'Reihe', d => '2019', v => 'Bd. 1' );
    my $r = $rules->{810};
    my @post = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'postfix' );
    is( $post[1], 'Reihe, ',   '810: $a gets ", " when $d follows (isbd.py X10 d)' );
    is( $post[3], ' (2019) ;', '810: $d wrapped + gets " ;" when $v follows' );
    is( $post[5], 'Bd. 1',     '810: $v is last sf' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $r, 'prefix' );
    is( $pre[1], 'Reihe',     '810 prefix: $a unchanged' );
    is( $pre[3], ' (, 2019)', '810 prefix: $d gets ", " prepended + wrapped' );
    is( $pre[5], ' ;Bd. 1',   '810 prefix: $v gets " ;" prepended' );
    # Same group-open asymmetry as 610: prefix lands the separator inside the
    # paren for this cb_pre-grouped field only (see the 610 NOTE above).
    is( combined_string(\@post), 'Reihe, (2019) ; Bd. 1', '810 postfix combined' );
    is( combined_string(\@pre),  'Reihe (, 2019) ; Bd. 1', '810 prefix combined (group-open asym, see 610 NOTE)' );
}

# ------------------------------------------------ alias targets (structural)
# The deviating tags that are use_rules aliases of a pinned base. Their
# resolved rules are covered via the base above; here we only confirm the
# alias points at the right base (so a later re-parent does not go silent).
{
    my %alias = (
        243 => '240', 700 => '100', 710 => '110',
        762 => '760', 765 => '760', 767 => '760', 770 => '760',
        772 => '760', 773 => '760', 774 => '760', 775 => '760',
        776 => '760', 777 => '760', 780 => '760', 785 => '760',
        786 => '760', 787 => '760',
    );
    # NOTE: 730/830 are NOT use_rules aliases in D-A-CH - they are
    # standalone X30 blocks (distinct $v/$x) pinned above, so they are
    # intentionally absent here.
    for my $tag ( sort { $a <=> $b } keys %alias ) {
        is( $rules->{$tag}{use_rules}, $alias{$tag}, "$tag use_rules -> $alias{$tag}" );
    }
}

done_testing();
