# PROVENANCE:
#   [doc §4.35]   -> drawn verbatim from the reference doc
#   (no token)    -> constructed
#
# This file covers the §4.35 Bibliographic Linking Entry Fields
# (760, 762, 765, 767, 770, 772, 773, 774, 775, 776, 777, 780, 785, 786, 787).
# ALL of these share ONE identical rule table, so 760 is the canonical
# block and the other 14 tags `use_rules => '760'`.
#
# FIELD CHEAT-SHEET (§4.35, identical for every 76x/78x tag):
#   Content subfields -> PRECEDING '. ' (the period lands on the PREVIOUS
#     subfield in postfix): $b $c $d $g $h $k $m $n $p $s $t $1
#   $i (relationship info, R) -> trailing ': ' via the shared
#     _decorate_display_text_pre cb_pre (the display-text mechanism).
#   N/A (no change, no pchrs key): $a, $e/$f (775 only), $j (786 only),
#     $o, $q, $r, $u, $v, $w, $x, $y, $z.
#
# NOTE on $a: the table marks $a "N/A" (no change), but when a keyed
#   subfield FOLLOWS it (e.g. $t), the '. ' still lands on $a in postfix
#   mode (like 580/5xx). N/A here means "$a itself introduces no punct";
#   the preceding-period ownership is handled by the following subfield's
#   key.
#
# Embedded-field ($j) examples from the doc are NOT tested: that is an
# alternative encoding where $1/$j embed whole fields; $j is N/A to us
# (786 only, no change) and we do not process the embedded technique.

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

# --- all 15 tags are defined, canonical + aliases ---
my @tags = qw(760 761 762 765 767 770 772 773 774 775 776 777 780 785 786 787);
for my $t (@tags) {
    ok( defined $R->{$t}, "$t rules defined" );
}
is_deeply( $R->{760}{pchrs},
    {
        b => '. ',
        c => '. ',
        d => '. ',
        g => '. ',
        h => '. ',
        k => '. ',
        m => '. ',
        n => '. ',
        p => '. ',
        s => '. ',
        t => '. ',
        '1' => '. ',
    },
    '760 canonical pchrs: all content subfields get preceding ". "'
);
is( $R->{760}{cb_pre},
    'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
    '760 $i display-text wired to the shared callback string'
);
for my $t (qw(761 762 765 767 770 772 773 774 775 776 777 780 785 786 787)) {
    is( $R->{$t}{use_rules}, '760', "$t aliases 760 (identical rule table)" );
}

# =====================================================================
# 775 ex 1 (doc §4.35) — trailing-field N/A ($e) stops the chain
# =====================================================================
# Doc: Current: 775 0# $a Mellor, Alec. $t Strange masonic stories $e eng
{
    # render: [doc §4.35] 775 0# $a Mellor, Alec $t Strange masonic stories $e eng
    my $field = make_field( '775', '0', '#', a => 'Mellor, Alec', t => 'Strange masonic stories', e => 'eng' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{775}, 'postfix' );
    is( $result[1],  'Mellor, Alec. ',       '775 ex1 postfix: $a gets ". " (from following $t)' );
    is( $result[3],  'Strange masonic stories', '775 ex1 postfix: $t unchanged (no keyed sf after)' );
    is( $result[5],  'eng',                  '775 ex1 postfix: $e (N/A, last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{775}, 'prefix' );
    is( $result_pr[1], 'Mellor, Alec',       '775 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '. Strange masonic stories', '775 ex1 prefix: $t gets ". " prepended' );
    is( $result_pr[5], 'eng',                '775 ex1 prefix: $e unchanged' );

    check_combined( \@result, \@result_pr, '775 ex1: combined string identical' );
}

# =====================================================================
# 776 ex 2 (doc §4.35) — $i display-text + end-of-title '.' + N/A passthrough
# =====================================================================
# Doc: Current: 776 08 $i Print version: $a McConnell, John H. $t How to
#   design, implement, and interpret an employee survey. $d New York :
#   AMACOM, c2003 $z 0814407099 $w (DLC)##2002153914# $w (OCoLC)51020412
{
    # render: [doc §4.35] 776 08 $i Print version $a McConnell, John H $t How to design, implement, and interpret an employee survey $d New York : AMACOM, c2003 $z 0814407099 $w (DLC)##2002153914# $w (OCoLC)51020412
    my $field = make_field( '776', '0', '8', i => 'Print version', a => 'McConnell, John H', t => 'How to design, implement, and interpret an employee survey', d => 'New York : AMACOM, c2003', z => '0814407099', w => '(DLC)##2002153914#', w => '(OCoLC)51020412' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{776}, 'postfix' );
    is( $result[1],  'Print version: ',     '776 ex2 postfix: $i gets ": " (display text)' );
    is( $result[3],  'McConnell, John H. ',  '776 ex2 postfix: $a gets ". " (from following $t)' );
    is( $result[5],  'How to design, implement, and interpret an employee survey. ', '776 ex2 postfix: $t gets ". " (from following $d)' );
    is( $result[7],  'New York : AMACOM, c2003', '776 ex2 postfix: $d unchanged (no keyed sf after)' );
    is( $result[9],  '0814407099',           '776 ex2 postfix: $z (N/A) unchanged' );
    is( $result[11], '(DLC)##2002153914#',   '776 ex2 postfix: $w (N/A) unchanged' );
    is( $result[13], '(OCoLC)51020412',      '776 ex2 postfix: 2nd $w (N/A) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{776}, 'prefix' );
    is( $result_pr[1], 'Print version: ',    '776 ex2 prefix: $i gets ": " (display text, mode-independent)' );
    is( $result_pr[3], 'McConnell, John H',  '776 ex2 prefix: $a unchanged' );
    is( $result_pr[5], '. How to design, implement, and interpret an employee survey', '776 ex2 prefix: $t gets ". " prepended' );
    is( $result_pr[7], '. New York : AMACOM, c2003', '776 ex2 prefix: $d gets ". " prepended' );
    is( $result_pr[9], '0814407099',         '776 ex2 prefix: $z (N/A) unchanged' );
    is( $result_pr[11], '(DLC)##2002153914#', '776 ex2 prefix: $w (N/A) unchanged' );
    is( $result_pr[13], '(OCoLC)51020412',   '776 ex2 prefix: 2nd $w (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '776 ex2: combined string identical' );
}

# =====================================================================
# 780 ex 3 (doc §4.35) — title follows corporate $a
# =====================================================================
# Doc: Current: 780 07 $a British Columbia. Ministry of Provincial Secretary
#   and Government Services. $t Annual report $x 0226-0883 $w (DLC)###80649039#
#   $w (OCoLC)6270433
{
    # render: [doc §4.35] 780 07 $a British Columbia. Ministry of Provincial Secretary and Government Services $t Annual report $x 0226-0883 $w (DLC)###80649039# $w (OCoLC)6270433
    my $field = make_field( '780', '0', '7', a => 'British Columbia. Ministry of Provincial Secretary and Government Services', t => 'Annual report', x => '0226-0883', w => '(DLC)###80649039#', w => '(OCoLC)6270433' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{780}, 'postfix' );
    is( $result[1], 'British Columbia. Ministry of Provincial Secretary and Government Services. ', '780 ex3 postfix: $a gets ". " (from following $t)' );
    is( $result[3], 'Annual report',       '780 ex3 postfix: $t unchanged (no keyed sf after)' );
    is( $result[5], '0226-0883',           '780 ex3 postfix: $x (N/A) unchanged' );
    is( $result[7], '(DLC)###80649039#',   '780 ex3 postfix: $w (N/A) unchanged' );
    is( $result[9], '(OCoLC)6270433',      '780 ex3 postfix: 2nd $w (N/A) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{780}, 'prefix' );
    is( $result_pr[1], 'British Columbia. Ministry of Provincial Secretary and Government Services', '780 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '. Annual report',  '780 ex3 prefix: $t gets ". " prepended' );
    is( $result_pr[5], '0226-0883',        '780 ex3 prefix: $x (N/A) unchanged' );
    is( $result_pr[7], '(DLC)###80649039#', '780 ex3 prefix: $w (N/A) unchanged' );
    is( $result_pr[9], '(OCoLC)6270433',   '780 ex3 prefix: 2nd $w (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '780 ex3: combined string identical' );
}

# =====================================================================
# 760 constructed — $a alone (no keyed follow): fully N/A, unchanged
# =====================================================================
{
    my $field = make_field( '760', ' ', ' ', a => 'Zentralblatt' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{760}, 'postfix' );
    is( $result[1], 'Zentralblatt', '760 $a-alone postfix: unchanged (no keyed sf after)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{760}, 'prefix' );
    is( $result_pr[1], 'Zentralblatt', '760 $a-alone prefix: unchanged' );

    check_combined( \@result, \@result_pr, '760 $a-alone: combined string identical' );
}

# =====================================================================
# 787 constructed — $i (display text) directly followed by a keyed $t
# (colon-skip: the '. ' must NOT stack after the $i colon)
# =====================================================================
{
    # render: 787 ## $i Related entry $t A title $w (OCoLC)123
    my $field = make_field( '787', ' ', ' ', i => 'Related entry', t => 'A title', w => '(OCoLC)123' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{787}, 'postfix' );
    is( $result[1], 'Related entry: ', '787 colon-skip postfix: $i gets ": " and NO stacked ". " (ends in colon)' );
    is( $result[3], 'A title',        '787 colon-skip postfix: $t unchanged (". " suppressed after colon)' );
    is( $result[5], '(OCoLC)123',     '787 colon-skip postfix: $w (N/A) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{787}, 'prefix' );
    is( $result_pr[1], 'Related entry: ', '787 colon-skip prefix: $i gets ": " and NO stacked ". "' );
    is( $result_pr[3], 'A title',        '787 colon-skip prefix: $t unchanged (". " suppressed after colon)' );
    is( $result_pr[5], '(OCoLC)123',     '787 colon-skip prefix: $w (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '787 colon-skip: combined string identical' );
}

# =====================================================================
# 760 constructed — uniform title + edition + $1 (linking data): chain of
# keyed content subfields
# =====================================================================
{
    # render: 760 ## $s Nova acta Leopoldina $b Neue Folge $d Halle : Herder, 1932 $1 77010$aSupplement
    my $field = make_field( '760', ' ', ' ', s => 'Nova acta Leopoldina', b => 'Neue Folge', d => 'Halle : Herder, 1932', '1' => '77010$aSupplement' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{760}, 'postfix' );
    is( $result[1], 'Nova acta Leopoldina. ', '760 chain postfix: $s gets ". " (from following $b)' );
    is( $result[3], 'Neue Folge. ',           '760 chain postfix: $b gets ". " (from following $d)' );
    is( $result[5], 'Halle : Herder, 1932. ', '760 chain postfix: $d gets ". " (from following $1)' );
    is( $result[7], '77010$aSupplement',      '760 chain postfix: $1 (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{760}, 'prefix' );
    is( $result_pr[1], 'Nova acta Leopoldina', '760 chain prefix: $s unchanged' );
    is( $result_pr[3], '. Neue Folge',         '760 chain prefix: $b gets ". " prepended' );
    is( $result_pr[5], '. Halle : Herder, 1932', '760 chain prefix: $d gets ". " prepended' );
    is( $result_pr[7], '. 77010$aSupplement',  '760 chain prefix: $1 gets ". " prepended' );

    check_combined( \@result, \@result_pr, '760 chain: combined string identical' );
}

# =====================================================================
# The remaining aliases (761/762/765/767/770/772/773/774/777/785/786):
# representative constructed data per tag — all share the identical §4.35
# table, so each just exercises the content-subfield '. ' + $i ':' rules.
# =====================================================================

# 761 Subseries Entry
{
    # render: 761 ## $a Hauptserie. Abt. A $t Monographien
    my $field = make_field( '761', ' ', ' ', a => 'Hauptserie. Abt. A', t => 'Monographien' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{761}, 'postfix' );
    is( $r[1], 'Hauptserie. Abt. A. ', '761 postfix: $a gets ". " (from following $t)' );
    is( $r[3], 'Monographien', '761 postfix: $t (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{761}, 'prefix' );
    is( $rp[1], 'Hauptserie. Abt. A', '761 prefix: $a unchanged' );
    is( $rp[3], '. Monographien', '761 prefix: $t gets ". " prepended' );
    check_combined( \@r, \@rp, '761: combined string identical' );
}

# 762 Subseries Entry
{
    # render: 762 ## $a Hauptserie $b Neue Folge $d Berlin : Springer, 1990
    my $field = make_field( '762', ' ', ' ', a => 'Hauptserie', b => 'Neue Folge', d => 'Berlin : Springer, 1990' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{762}, 'postfix' );
    is( $r[1], 'Hauptserie. ', '762 postfix: $a gets ". " (from following $b)' );
    is( $r[3], 'Neue Folge. ', '762 postfix: $b gets ". " (from following $d)' );
    is( $r[5], 'Berlin : Springer, 1990', '762 postfix: $d (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{762}, 'prefix' );
    is( $rp[1], 'Hauptserie', '762 prefix: $a unchanged' );
    is( $rp[3], '. Neue Folge', '762 prefix: $b gets ". " prepended' );
    is( $rp[5], '. Berlin : Springer, 1990', '762 prefix: $d gets ". " prepended' );
    check_combined( \@r, \@rp, '762: combined string identical' );
}

# 765 Original Language Entry
{
    # render: 765 ## $i Also issued in English $t The original text
    my $field = make_field( '765', ' ', ' ', i => 'Also issued in English', t => 'The original text' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{765}, 'postfix' );
    is( $r[1], 'Also issued in English: ', '765 postfix: $i gets ": " (display text)' );
    is( $r[3], 'The original text', '765 postfix: $t (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{765}, 'prefix' );
    is( $rp[1], 'Also issued in English: ', '765 prefix: $i gets ": " (display text)' );
    is( $rp[3], 'The original text', '765 prefix: $t unchanged' );
    check_combined( \@r, \@rp, '765: combined string identical' );
}

# 767 Translation Entry
{
    # render: 767 ## $a Tokarczuk, Olga $t Flights $g English
    my $field = make_field( '767', ' ', ' ', a => 'Tokarczuk, Olga', t => 'Flights', g => 'English' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{767}, 'postfix' );
    is( $r[1], 'Tokarczuk, Olga. ', '767 postfix: $a gets ". " (from following $t)' );
    is( $r[3], 'Flights. ', '767 postfix: $t gets ". " (from following $g)' );
    is( $r[5], 'English', '767 postfix: $g (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{767}, 'prefix' );
    is( $rp[1], 'Tokarczuk, Olga', '767 prefix: $a unchanged' );
    is( $rp[3], '. Flights', '767 prefix: $t gets ". " prepended' );
    is( $rp[5], '. English', '767 prefix: $g gets ". " prepended' );
    check_combined( \@r, \@rp, '767: combined string identical' );
}

# 770 Supplement/Special Issue Entry
{
    # render: 770 ## $i Supplement to $t The Times Literary Supplement
    my $field = make_field( '770', ' ', ' ', i => 'Supplement to', t => 'The Times Literary Supplement' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{770}, 'postfix' );
    is( $r[1], 'Supplement to: ', '770 postfix: $i gets ": " (display text)' );
    is( $r[3], 'The Times Literary Supplement', '770 postfix: $t (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{770}, 'prefix' );
    is( $rp[1], 'Supplement to: ', '770 prefix: $i gets ": " (display text)' );
    is( $rp[3], 'The Times Literary Supplement', '770 prefix: $t unchanged' );
    check_combined( \@r, \@rp, '770: combined string identical' );
}

# 772 Supplement Parent Entry
{
    # render: 772 1# $i Parent of $t Annual report $d Dublin : Stationery Office
    my $field = make_field( '772', '1', '#', i => 'Parent of', t => 'Annual report', d => 'Dublin : Stationery Office' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{772}, 'postfix' );
    is( $r[1], 'Parent of: ', '772 postfix: $i gets ": " (display text)' );
    is( $r[3], 'Annual report. ', '772 postfix: $t gets ". " (from following $d)' );
    is( $r[5], 'Dublin : Stationery Office', '772 postfix: $d (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{772}, 'prefix' );
    is( $rp[1], 'Parent of: ', '772 prefix: $i gets ": " (display text)' );
    is( $rp[3], 'Annual report', '772 prefix: $t unchanged (the ". " lands on the following $d)' );
    is( $rp[5], '. Dublin : Stationery Office', '772 prefix: $d gets ". " prepended' );
    check_combined( \@r, \@rp, '772: combined string identical' );
}

# 773 Host Item Entry
{
    # render: 773 0# $t Journal of Applied Physics $g v. 42, no. 3 $p 2011
    my $field = make_field( '773', '0', '#', t => 'Journal of Applied Physics', g => 'v. 42, no. 3', p => '2011' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{773}, 'postfix' );
    is( $r[1], 'Journal of Applied Physics. ', '773 postfix: $t gets ". " (from following $g)' );
    is( $r[3], 'v. 42, no. 3. ', '773 postfix: $g gets ". " (from following $p)' );
    is( $r[5], '2011', '773 postfix: $p (last) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{773}, 'prefix' );
    is( $rp[1], 'Journal of Applied Physics', '773 prefix: $t unchanged' );
    is( $rp[3], '. v. 42, no. 3', '773 prefix: $g gets ". " prepended' );
    is( $rp[5], '. 2011', '773 prefix: $p gets ". " prepended' );
    check_combined( \@r, \@rp, '773: combined string identical' );
}

# 774 Constituent Unit Entry
{
    # render: 774 ## $a Hollingurst, Alan $t The sparrow $w (OCoLC)9876
    my $field = make_field( '774', ' ', ' ', a => 'Hollingurst, Alan', t => 'The sparrow', w => '(OCoLC)9876' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{774}, 'postfix' );
    is( $r[1], 'Hollingurst, Alan. ', '774 postfix: $a gets ". " (from following $t)' );
    is( $r[3], 'The sparrow', '774 postfix: $t unchanged (N/A $w after)' );
    is( $r[5], '(OCoLC)9876', '774 postfix: $w (N/A) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{774}, 'prefix' );
    is( $rp[1], 'Hollingurst, Alan', '774 prefix: $a unchanged' );
    is( $rp[3], '. The sparrow', '774 prefix: $t gets ". " prepended' );
    is( $rp[5], '(OCoLC)9876', '774 prefix: $w (N/A) unchanged' );
    check_combined( \@r, \@rp, '774: combined string identical' );
}

# 777 Issued With Entry
{
    # render: 777 ## $t The Standard $x 1234-5678
    my $field = make_field( '777', ' ', ' ', t => 'The Standard', x => '1234-5678' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{777}, 'postfix' );
    is( $r[1], 'The Standard', '777 postfix: $t unchanged (N/A $x after)' );
    is( $r[3], '1234-5678', '777 postfix: $x (N/A) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{777}, 'prefix' );
    is( $rp[1], 'The Standard', '777 prefix: $t unchanged' );
    is( $rp[3], '1234-5678', '777 prefix: $x (N/A) unchanged' );
    check_combined( \@r, \@rp, '777: combined string identical' );
}

# 785 Succeeding Entry
{
    # render: 785 08 $a Chemical Industry Association $t Abstracts $x 0001-6160
    my $field = make_field( '785', '0', '8', a => 'Chemical Industry Association', t => 'Abstracts', x => '0001-6160' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{785}, 'postfix' );
    is( $r[1], 'Chemical Industry Association. ', '785 postfix: $a gets ". " (from following $t)' );
    is( $r[3], 'Abstracts', '785 postfix: $t unchanged (N/A $x after)' );
    is( $r[5], '0001-6160', '785 postfix: $x (N/A) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{785}, 'prefix' );
    is( $rp[1], 'Chemical Industry Association', '785 prefix: $a unchanged' );
    is( $rp[3], '. Abstracts', '785 prefix: $t gets ". " prepended' );
    is( $rp[5], '0001-6160', '785 prefix: $x (N/A) unchanged' );
    check_combined( \@r, \@rp, '785: combined string identical' );
}

# 786 Data Source Entry ($j period of content is N/A — contributes NO punct)
{
    # render: 786 ## $t Census of population $s Preliminary figures $j 1980 $w (OCoLC)7654
    my $field = make_field( '786', ' ', ' ', t => 'Census of population', s => 'Preliminary figures', j => '1980', w => '(OCoLC)7654' );
    my @r = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{786}, 'postfix' );
    is( $r[1], 'Census of population. ', '786 postfix: $t gets ". " (from following keyed $s)' );
    is( $r[3], 'Preliminary figures', '786 postfix: $s unchanged (following $j is N/A)' );
    is( $r[5], '1980', '786 postfix: $j (N/A) unchanged' );
    is( $r[7], '(OCoLC)7654', '786 postfix: $w (N/A) unchanged' );
    my @rp = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{786}, 'prefix' );
    is( $rp[1], 'Census of population', '786 prefix: $t unchanged' );
    is( $rp[3], '. Preliminary figures', '786 prefix: $s gets ". " prepended' );
    is( $rp[5], '1980', '786 prefix: $j (N/A) unchanged' );
    is( $rp[7], '(OCoLC)7654', '786 prefix: $w (N/A) unchanged' );
    check_combined( \@r, \@rp, '786: combined string identical' );
}

done_testing();
