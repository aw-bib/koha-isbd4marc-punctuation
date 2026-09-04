#!/usr/bin/perl
#
# PROVENANCE:
#   [doc §3.xx]            -> drawn verbatim from the reference doc §3.xx examples
#   [doc §3.xx - derived]  -> adapted/truncated from a §3.xx example
#   (no token)             -> constructed
#
# This file covers the note fields from the spec's §3.9-§3.25 "Extraction of
# Punctuation" series (a SEPARATE cohort from the §4.x notes in t/28).
# Phase 1 implements all except 533/534, which need the '.()' wrap+period
# pattern and are done separately in a follow-up task. 532 is K10plus-only
# (added to MARC in 2018, not in the LoC/PCC spec), all-N/A -> explicit
# empty block.
#
# FIELD CHEAT-SHEET (LoC/PCC §3.x):
#   506: $b/$c/$d/$e '; ', $f '. ', $u ': ', $a N/A
#   507: $b '; ', $a N/A
#   510: $b/$c/$x ', ', $a/$u N/A
#   513: $b '; ', $a N/A
#   526: $i ': ' (cb_pre display text), rest N/A
#   530: $b/$c/$d '; ', $a/$u N/A
#   532: all N/A (K10plus-only; explicit empty block)
#   535: $b/$c/$d '; ', $a/$g N/A
#   540: $b/$c/$d '; ', $u ': ', $a N/A
#   541: $a/$b/$c/$d/$e/$f/$h/$n '; ', $o N/A
#   544: $a/$b/$c/$e '; ', $d/$n N/A
#   546: $b '; ', $a N/A
#   555: $b/$c/$d '; ', $u '. ', $a N/A
#   562: $b/$c/$d/$e '; ', $a N/A
#   565: $b/$c/$d/$e '; ', $a N/A
#   584: $a/$b '. '
#
# KEY SEMANTICS (recap):
#   * A single pchrs key `X => P` fires whenever the FOLLOWING subfield is X
#     (incl. X->X for repeatable instances). In postfix the punct is APPENDED
#     to the current (preceding) sf; in prefix it is PREPENDED to the next sf.
#   * $3 (materials specified) is a leading control subfield and never takes a
#     following separator. Where $3 can precede a keyed subfield, the field
#     carries an explicit EMPTY compound key '3X' => '' that overrides the
#     single key (compound takes precedence; '' appends/prepends nothing). See
#     the LoCPCC.pm 541/544 comments.
#   * An N/A middle subfield still receives the appended punct when the
#     subfield AFTER it is keyed (e.g. 541 $o cubic feet; $n 12).

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

# --- all 16 phase-1 note fields are defined ---
for my $t ( qw(506 507 510 513 526 530 532 535 540 541 544 546 555 562 565 584) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}

# 532 is K10plus-only; confirm it's an explicit empty (name-only) block.
ok( !exists $R->{532}{pchrs}, '532 has no pchrs (all N/A)' );
ok( !exists $R->{532}{cb_pre}, '532 has no cb_pre (all N/A)' );

# =====================================================================
# 506 – Restrictions on Access Note (spec §3.9)
# $b/$c/$d/$e '; '; $f '. '; $u ': '. $a N/A.
# =====================================================================

# --- 506 ex 1 (doc §3.9) ---
# Doc: Current: 506 ## $a Restricted access; $c Written permission required; $b Donor.
{
    # render: [doc §3.9] 506 ## $a Restricted access $c Written permission required $b Donor
    my $field = make_field( '506', ' ', ' ', a => 'Restricted access', c => 'Written permission required', b => 'Donor' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'postfix' );
    is( $result[1], 'Restricted access; ', '506 ex1 postfix: $a gets "; "' );
    is( $result[3], 'Written permission required; ', '506 ex1 postfix: $c gets "; "' );
    is( $result[5], 'Donor', '506 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'prefix' );
    is( $result_pr[1], 'Restricted access', '506 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; Written permission required', '506 ex1 prefix: $c gets "; " prepended' );
    is( $result_pr[5], '; Donor', '506 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '506 ex1: combined string identical' );
}

# --- 506 ex 2 (doc §3.9) ---
# Doc: Current: 506 ## $a Classified under national security provisions; $b Department of Defense; $e Title 50, chapter 401, U.S.C.
{
    # render: [doc §3.9] 506 ## $a Classified under national security provisions $b Department of Defense $e Title 50, chapter 401, U.S.C
    my $field = make_field( '506', ' ', ' ', a => 'Classified under national security provisions', b => 'Department of Defense', e => 'Title 50, chapter 401, U.S.C' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'postfix' );
    is( $result[1], 'Classified under national security provisions; ', '506 ex2 postfix: $a gets "; "' );
    is( $result[3], 'Department of Defense; ', '506 ex2 postfix: $b gets "; "' );
    is( $result[5], 'Title 50, chapter 401, U.S.C', '506 ex2 postfix: $e unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'prefix' );
    is( $result_pr[1], 'Classified under national security provisions', '506 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '; Department of Defense', '506 ex2 prefix: $b gets "; " prepended' );
    is( $result_pr[5], '; Title 50, chapter 401, U.S.C', '506 ex2 prefix: $e gets "; " prepended' );

    check_combined( \@result, \@result_pr, '506 ex2: combined string identical' );
}

# --- 506 ex 3: $f '. ' + $2 passthrough (doc §3.9) ---
# Doc: Current: 506 ## $a Closed until January 1, 2068. $f No online access $2 star
{
    # render: [doc §3.9] 506 ## $a Closed until January 1, 2068 $f No online access $2 star
    my $field = make_field( '506', ' ', ' ', a => 'Closed until January 1, 2068', f => 'No online access', '2' => 'star' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'postfix' );
    is( $result[1], 'Closed until January 1, 2068. ', '506 ex3 postfix: $a gets ". "' );
    is( $result[3], 'No online access', '506 ex3 postfix: $f unchanged' );
    is( $result[5], 'star', '506 ex3 postfix: $2 (source code) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'prefix' );
    is( $result_pr[1], 'Closed until January 1, 2068', '506 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '. No online access', '506 ex3 prefix: $f gets ". " prepended' );
    is( $result_pr[5], 'star', '506 ex3 prefix: $2 unchanged' );

    check_combined( \@result, \@result_pr, '506 ex3: combined string identical' );
}

# --- 506 constructed: $u ': ' ---
{
    # render: 506 ## $a Available online $u http://example.com
    my $field = make_field( '506', ' ', ' ', a => 'Available online', u => 'http://example.com' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'postfix' );
    is( $result[1], 'Available online: ', '506 constructed: $a gets ": " for $u' );
    is( $result[3], 'http://example.com', '506 constructed: $u unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'506'}, 'prefix' );
    is( $result_pr[1], 'Available online', '506 constructed prefix: $a unchanged' );
    is( $result_pr[3], ': http://example.com', '506 constructed prefix: $u gets ": " prepended' );

    check_combined( \@result, \@result_pr, '506 constructed: combined string identical' );
}

# =====================================================================
# 507 – Scale Note for Graphic Material (spec §3.10)
# $b '; '. $a N/A.
# =====================================================================

# --- 507 ex 1 (doc §3.10) ---
# Doc: Current: 507 ## $a Scale 1:500,000; $b 1 in. equals 8 miles.
{
    # render: [doc §3.10] 507 ## $a Scale 1:500,000 $b 1 in. equals 8 miles
    my $field = make_field( '507', ' ', ' ', a => 'Scale 1:500,000', b => '1 in. equals 8 miles' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'507'}, 'postfix' );
    is( $result[1], 'Scale 1:500,000; ', '507 ex1 postfix: $a gets "; "' );
    is( $result[3], '1 in. equals 8 miles', '507 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'507'}, 'prefix' );
    is( $result_pr[1], 'Scale 1:500,000', '507 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; 1 in. equals 8 miles', '507 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '507 ex1: combined string identical' );
}

# --- 507 constructed: $a alone edge ---
{
    # render: 507 ## $a Scale 1:24,000
    my $field = make_field( '507', ' ', ' ', a => 'Scale 1:24,000' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'507'}, 'postfix' );
    is( $result[1], 'Scale 1:24,000', '507 constructed postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'507'}, 'prefix' );
    is( $result_pr[1], 'Scale 1:24,000', '507 constructed prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '507 constructed: combined string identical' );
}

# =====================================================================
# 510 – Citation References Note (spec §3.11)
# $b/$c/$x ', '. $a/$u N/A.
# =====================================================================

# --- 510 ex 1: $x then $b (doc §3.11) ---
# Doc: Current: 510 1# $a Index Medicus, $x 0019-3879, $b v1n1, 1984-
{
    # render: [doc §3.11] 510 1# $a Index Medicus $x 0019-3879 $b v1n1, 1984-
    my $field = make_field( '510', '1', '#', a => 'Index Medicus', x => '0019-3879', b => 'v1n1, 1984-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'postfix' );
    is( $result[1], 'Index Medicus, ', '510 ex1 postfix: $a gets ", " for $x' );
    is( $result[3], '0019-3879, ', '510 ex1 postfix: $x gets ", " for $b' );
    is( $result[5], 'v1n1, 1984-', '510 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'prefix' );
    is( $result_pr[1], 'Index Medicus', '510 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ', 0019-3879', '510 ex1 prefix: $x gets ", " prepended' );
    is( $result_pr[5], ', v1n1, 1984-', '510 ex1 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '510 ex1: combined string identical' );
}

# --- 510 ex 2: $c (doc §3.11) ---
# Doc: Current: 510 4# $a LC Treasure maps (2nd ed.), $c 13
{
    # render: [doc §3.11] 510 4# $a LC Treasure maps (2nd ed.) $c 13
    my $field = make_field( '510', '4', '#', a => 'LC Treasure maps (2nd ed.)', c => '13' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'postfix' );
    is( $result[1], 'LC Treasure maps (2nd ed.), ', '510 ex2 postfix: $a gets ", " for $c' );
    is( $result[3], '13', '510 ex2 postfix: $c unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'prefix' );
    is( $result_pr[1], 'LC Treasure maps (2nd ed.)', '510 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ', 13', '510 ex2 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '510 ex2: combined string identical' );
}

# --- 510 ex 3: $c (doc §3.11) ---
# Doc: Current: 510 4# $a Goff, $c A-970
{
    # render: [doc §3.11] 510 4# $a Goff $c A-970
    my $field = make_field( '510', '4', '#', a => 'Goff', c => 'A-970' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'postfix' );
    is( $result[1], 'Goff, ', '510 ex3 postfix: $a gets ", " for $c' );
    is( $result[3], 'A-970', '510 ex3 postfix: $c unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'510'}, 'prefix' );
    is( $result_pr[1], 'Goff', '510 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ', A-970', '510 ex3 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '510 ex3: combined string identical' );
}

# =====================================================================
# 513 – Type of Report and Period Covered Note (spec §3.12)
# $b '; '. $a N/A. (Spec table says "colon-space" but its example uses '; '.)
# =====================================================================

# --- 513 ex 1 (doc §3.12) ---
# Doc: Current: 513 ## $a Interim report; $b Jan.-July 1977.
{
    # render: [doc §3.12] 513 ## $a Interim report $b Jan.-July 1977
    my $field = make_field( '513', ' ', ' ', a => 'Interim report', b => 'Jan.-July 1977' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'513'}, 'postfix' );
    is( $result[1], 'Interim report; ', '513 ex1 postfix: $a gets "; "' );
    is( $result[3], 'Jan.-July 1977', '513 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'513'}, 'prefix' );
    is( $result_pr[1], 'Interim report', '513 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; Jan.-July 1977', '513 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '513 ex1: combined string identical' );
}

# =====================================================================
# 526 – Study Program Information Note (spec §3.13)
# $i ': ' via cb_pre (display text). Rest N/A.
# =====================================================================

# --- 526 ex 1 (doc §3.13) ---
# Doc: Current: 526 8# $i January 1999 selection for: $a Happy Valley Reading Club.
{
    # render: [doc §3.13] 526 8# $i January 1999 selection for $a Happy Valley Reading Club
    my $field = make_field( '526', '8', '#', i => 'January 1999 selection for', a => 'Happy Valley Reading Club' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'526'}, 'postfix' );
    is( $result[1], 'January 1999 selection for: ', '526 ex1 postfix: $i gets ": "' );
    is( $result[3], 'Happy Valley Reading Club', '526 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'526'}, 'prefix' );
    is( $result_pr[1], 'January 1999 selection for: ', '526 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'Happy Valley Reading Club', '526 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '526 ex1: combined string identical' );
}

# --- 526 constructed: N/A subfields pass through ---
{
    # render: 526 8# $i Reading level $a 3.2 $b Grade 3 $x nonpublic
    my $field = make_field( '526', '8', '#', i => 'Reading level', a => '3.2', b => 'Grade 3', x => 'nonpublic' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'526'}, 'postfix' );
    is( $result[1], 'Reading level: ', '526 constructed postfix: $i gets ": "' );
    is( $result[3], '3.2', '526 constructed postfix: $a unchanged' );
    is( $result[5], 'Grade 3', '526 constructed postfix: $b unchanged' );
    is( $result[7], 'nonpublic', '526 constructed postfix: $x unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'526'}, 'prefix' );
    is( $result_pr[1], 'Reading level: ', '526 constructed prefix: $i gets ": "' );
    is( $result_pr[3], '3.2', '526 constructed prefix: $a unchanged' );
    is( $result_pr[5], 'Grade 3', '526 constructed prefix: $b unchanged' );
    is( $result_pr[7], 'nonpublic', '526 constructed prefix: $x unchanged' );

    check_combined( \@result, \@result_pr, '526 constructed: combined string identical' );
}

# =====================================================================
# 530 – Additional Physical Form Available Note (spec §3.14)
# $b/$c/$d '; '. $a/$u N/A. $3 lead-in suppressed.
# =====================================================================

# --- 530 ex 1 (doc §3.14) ---
# Doc: Current: 530 ## $a Photoreproduced facsimile version; $b Published as Dudley, Cuthbert, ed., The Novel of Lord Ethelbert of Waxlot (Oxford University Press, 1973).
{
    # render: [doc §3.14] 530 ## $a Photoreproduced facsimile version $b Published as Dudley, Cuthbert, ed., The Novel of Lord Ethelbert of Waxlot (Oxford University Press, 1973)
    my $field = make_field( '530', ' ', ' ', a => 'Photoreproduced facsimile version', b => 'Published as Dudley, Cuthbert, ed., The Novel of Lord Ethelbert of Waxlot (Oxford University Press, 1973)' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'postfix' );
    is( $result[1], 'Photoreproduced facsimile version; ', '530 ex1 postfix: $a gets "; "' );
    is( $result[3], 'Published as Dudley, Cuthbert, ed., The Novel of Lord Ethelbert of Waxlot (Oxford University Press, 1973)', '530 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'prefix' );
    is( $result_pr[1], 'Photoreproduced facsimile version', '530 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; Published as Dudley, Cuthbert, ed., The Novel of Lord Ethelbert of Waxlot (Oxford University Press, 1973)', '530 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '530 ex1: combined string identical' );
}

# --- 530 ex 2: $b/$c/$d chain (doc §3.14, truncated DM-...) ---
# Doc: Current: 530 ## $a Available in microfilm as part of the Papers of Grover
#   P. Stover; $b Documentary Microfilms, 450 East 52nd St., New York, N.Y.
#   10006; $c Buyers must acquire entire film set; $d DM-...
{
    # render: [doc §3.14 - derived] 530 ## $a Available in microfilm as part of the Papers of Grover Stover $b Documentary Microfilms $c Buyers must acquire entire film set $d DM-1234
    my $field = make_field( '530', ' ', ' ', a => 'Available in microfilm as part of the Papers of Grover Stover', b => 'Documentary Microfilms', c => 'Buyers must acquire entire film set', d => 'DM-1234' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'postfix' );
    is( $result[1], 'Available in microfilm as part of the Papers of Grover Stover; ', '530 ex2 postfix: $a gets "; "' );
    is( $result[3], 'Documentary Microfilms; ', '530 ex2 postfix: $b gets "; "' );
    is( $result[5], 'Buyers must acquire entire film set; ', '530 ex2 postfix: $c gets "; "' );
    is( $result[7], 'DM-1234', '530 ex2 postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'prefix' );
    is( $result_pr[1], 'Available in microfilm as part of the Papers of Grover Stover', '530 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '; Documentary Microfilms', '530 ex2 prefix: $b gets "; " prepended' );
    is( $result_pr[5], '; Buyers must acquire entire film set', '530 ex2 prefix: $c gets "; " prepended' );
    is( $result_pr[7], '; DM-1234', '530 ex2 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '530 ex2: combined string identical' );
}

# --- 530 constructed: $3 lead-in suppressed ---
# Doc: Current: 530 ## $3 Original issue $a Photoreproduced facsimile version; $b Published... 
{
    # render: 530 ## $3 Original issue $a Photoreproduced facsimile version $b Published as Dudley
    my $field = make_field( '530', ' ', ' ', '3' => 'Original issue', a => 'Photoreproduced facsimile version', b => 'Published as Dudley' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'postfix' );
    is( $result[1], 'Original issue', '530 constructed postfix: $3 unchanged (no "; " — lead-in suppressed)' );
    is( $result[3], 'Photoreproduced facsimile version; ', '530 constructed postfix: $a gets "; " for $b' );
    is( $result[5], 'Published as Dudley', '530 constructed postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'530'}, 'prefix' );
    is( $result_pr[1], 'Original issue', '530 constructed prefix: $3 unchanged' );
    is( $result_pr[3], 'Photoreproduced facsimile version', '530 constructed prefix: $a unchanged' );
    is( $result_pr[5], '; Published as Dudley', '530 constructed prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '530 constructed: combined string identical' );
}

# =====================================================================
# 532 – Accessibility Note (all N/A; explicit empty block)
# =====================================================================

# --- 532 constructed: single free-text $a passes through ---
{
    # render: 532 ## $a No restrictions on access
    my $field = make_field( '532', ' ', ' ', a => 'No restrictions on access' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'532'}, 'postfix' );
    is( $result[1], 'No restrictions on access', '532 constructed postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'532'}, 'prefix' );
    is( $result_pr[1], 'No restrictions on access', '532 constructed prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '532 constructed: combined string identical' );
}

# =====================================================================
# 535 – Location of Originals/Duplicates Note (spec §3.17)
# $b/$c/$d '; '. $a/$g N/A. $3 lead-in suppressed.
# =====================================================================

# --- 535 ex 1: $3 + $a + $b (doc §3.17) ---
# Doc: Current: 535 2# $3 Harrison papers $a Western Reserve Historical Society; $b 10825 East Blvd., Cleveland, OH 44106
{
    # render: [doc §3.17] 535 2# $3 Harrison papers $a Western Reserve Historical Society $b 10825 East Blvd., Cleveland, OH 44106
    my $field = make_field( '535', '2', '#', '3' => 'Harrison papers', a => 'Western Reserve Historical Society', b => '10825 East Blvd., Cleveland, OH 44106' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'535'}, 'postfix' );
    is( $result[1], 'Harrison papers', '535 ex1 postfix: $3 unchanged' );
    is( $result[3], 'Western Reserve Historical Society; ', '535 ex1 postfix: $a gets "; "' );
    is( $result[5], '10825 East Blvd., Cleveland, OH 44106', '535 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'535'}, 'prefix' );
    is( $result_pr[1], 'Harrison papers', '535 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], 'Western Reserve Historical Society', '535 ex1 prefix: $a unchanged' );
    is( $result_pr[5], '; 10825 East Blvd., Cleveland, OH 44106', '535 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '535 ex1: combined string identical' );
}

# --- 535 ex 2: $b/$c/$d chain (doc §3.17) ---
# Doc: Current: 535 2# $3 German notebook $a Yale University Library, Department of Manuscripts and Archives; $b Box 1603A Yale Station, New Haven, CT 06520; $c USA; $d 203-436-4564
{
    # render: [doc §3.17] 535 2# $3 German notebook $a Yale University Library, Department of Manuscripts and Archives $b Box 1603A Yale Station, New Haven, CT 06520 $c USA $d 203-436-4564
    my $field = make_field( '535', '2', '#', '3' => 'German notebook', a => 'Yale University Library, Department of Manuscripts and Archives', b => 'Box 1603A Yale Station, New Haven, CT 06520', c => 'USA', d => '203-436-4564' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'535'}, 'postfix' );
    is( $result[1], 'German notebook', '535 ex2 postfix: $3 unchanged' );
    is( $result[3], 'Yale University Library, Department of Manuscripts and Archives; ', '535 ex2 postfix: $a gets "; "' );
    is( $result[5], 'Box 1603A Yale Station, New Haven, CT 06520; ', '535 ex2 postfix: $b gets "; "' );
    is( $result[7], 'USA; ', '535 ex2 postfix: $c gets "; "' );
    is( $result[9], '203-436-4564', '535 ex2 postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'535'}, 'prefix' );
    is( $result_pr[1], 'German notebook', '535 ex2 prefix: $3 unchanged' );
    is( $result_pr[3], 'Yale University Library, Department of Manuscripts and Archives', '535 ex2 prefix: $a unchanged' );
    is( $result_pr[5], '; Box 1603A Yale Station, New Haven, CT 06520', '535 ex2 prefix: $b gets "; " prepended' );
    is( $result_pr[7], '; USA', '535 ex2 prefix: $c gets "; " prepended' );
    is( $result_pr[9], '; 203-436-4564', '535 ex2 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '535 ex2: combined string identical' );
}


# =====================================================================
# 540 – Terms Governing Use and Reproduction Note (spec §3.18)
# $b/$c/$d '; ', $u ': '. $a N/A. $3 lead-in suppressed.
# =====================================================================

# --- 540 ex 1: $b/$c (doc §3.18) ---
# Doc: Current: 540 ## $3 Recorded radio programs $a There are copyright and contractual restrictions applying to the reproduction of most of these recordings; $b Department of Treasury; $c Treasury contracts 7-A130 through 39-A179.
{
    # render: [doc §3.18] 540 ## $3 Recorded radio programs $a There are copyright and contractual restrictions applying to the reproduction of most of these recordings $b Department of Treasury $c Treasury contracts 7-A130 through 39-A179
    my $field = make_field( '540', ' ', ' ', '3' => 'Recorded radio programs', a => 'There are copyright and contractual restrictions applying to the reproduction of most of these recordings', b => 'Department of Treasury', c => 'Treasury contracts 7-A130 through 39-A179' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'postfix' );
    is( $result[1], 'Recorded radio programs', '540 ex1 postfix: $3 unchanged (no "; ")' );
    is( $result[3], 'There are copyright and contractual restrictions applying to the reproduction of most of these recordings; ', '540 ex1 postfix: $a gets "; "' );
    is( $result[5], 'Department of Treasury; ', '540 ex1 postfix: $b gets "; "' );
    is( $result[7], 'Treasury contracts 7-A130 through 39-A179', '540 ex1 postfix: $c unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'prefix' );
    is( $result_pr[1], 'Recorded radio programs', '540 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], 'There are copyright and contractual restrictions applying to the reproduction of most of these recordings', '540 ex1 prefix: $a unchanged' );
    is( $result_pr[5], '; Department of Treasury', '540 ex1 prefix: $b gets "; " prepended' );
    is( $result_pr[7], '; Treasury contracts 7-A130 through 39-A179', '540 ex1 prefix: $c gets "; " prepended' );

    check_combined( \@result, \@result_pr, '540 ex1: combined string identical' );
}

# --- 540 ex 2: $d (doc §3.18) ---
# Doc: Current: 540 ## $3 Diaries $a Photocopying prohibited; $d Executor of estate.
{
    # render: [doc §3.18] 540 ## $3 Diaries $a Photocopying prohibited $d Executor of estate
    my $field = make_field( '540', ' ', ' ', '3' => 'Diaries', a => 'Photocopying prohibited', d => 'Executor of estate' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'postfix' );
    is( $result[1], 'Diaries', '540 ex2 postfix: $3 unchanged (no "; ")' );
    is( $result[3], 'Photocopying prohibited; ', '540 ex2 postfix: $a gets "; "' );
    is( $result[5], 'Executor of estate', '540 ex2 postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'prefix' );
    is( $result_pr[1], 'Diaries', '540 ex2 prefix: $3 unchanged' );
    is( $result_pr[3], 'Photocopying prohibited', '540 ex2 prefix: $a unchanged' );
    is( $result_pr[5], '; Executor of estate', '540 ex2 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '540 ex2: combined string identical' );
}

# --- 540 ex 3: $u (doc §3.18) ---
# Doc: Current: 540 ## $a Reproduction is restricted through October 2014. See Restrictions Statement for more information: $u http://lcweb.loc.gov/rr/print/res/273_brum.html
{
    # render: [doc §3.18] 540 ## $a Reproduction is restricted through October 2014. See Restrictions Statement for more information $u http://lcweb.loc.gov/rr/print/res/273_brum.html
    my $field = make_field( '540', ' ', ' ', a => 'Reproduction is restricted through October 2014. See Restrictions Statement for more information', u => 'http://lcweb.loc.gov/rr/print/res/273_brum.html' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'postfix' );
    is( $result[1], 'Reproduction is restricted through October 2014. See Restrictions Statement for more information: ', '540 ex3 postfix: $a gets ": " for $u' );
    is( $result[3], 'http://lcweb.loc.gov/rr/print/res/273_brum.html', '540 ex3 postfix: $u unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'540'}, 'prefix' );
    is( $result_pr[1], 'Reproduction is restricted through October 2014. See Restrictions Statement for more information', '540 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ': http://lcweb.loc.gov/rr/print/res/273_brum.html', '540 ex3 prefix: $u gets ": " prepended' );

    check_combined( \@result, \@result_pr, '540 ex3: combined string identical' );
}

# =====================================================================
# 541 – Immediate Source of Acquisition Note (spec §3.19)
# $a/$b/$c/$d/$e/$f/$h/$n '; '. $o N/A. $3 lead-in suppressed.
# =====================================================================

# --- 541 ex 1: $3 + $c/$d/$a (doc §3.19) ---
# Doc: Current: 541 ## $3 Ref print $c Copyright deposit--RNR; $d Received: 10/30/82; $a Copyright Collection.
{
    # render: [doc §3.19] 541 ## $3 Ref print $c Copyright deposit--RNR $d Received: 10/30/82 $a Copyright Collection
    my $field = make_field( '541', ' ', ' ', '3' => 'Ref print', c => 'Copyright deposit--RNR', d => 'Received: 10/30/82', a => 'Copyright Collection' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'postfix' );
    is( $result[1], 'Ref print', '541 ex1 postfix: $3 unchanged (no "; " — suppressed)' );
    is( $result[3], 'Copyright deposit--RNR; ', '541 ex1 postfix: $c gets "; "' );
    is( $result[5], 'Received: 10/30/82; ', '541 ex1 postfix: $d gets "; "' );
    is( $result[7], 'Copyright Collection', '541 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'prefix' );
    is( $result_pr[1], 'Ref print', '541 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], 'Copyright deposit--RNR', '541 ex1 prefix: $c unchanged (3c suppressed; punct moved to $d)' );
    is( $result_pr[5], '; Received: 10/30/82', '541 ex1 prefix: $d gets "; " prepended' );
    is( $result_pr[7], '; Copyright Collection', '541 ex1 prefix: $a gets "; " prepended' );

    check_combined( \@result, \@result_pr, '541 ex1: combined string identical' );
}

# --- 541 ex 2: repeatable $n + N/A $o + $3 (doc §3.19, long) ---
# Doc: Current: 541 0# $3 5 diaries $n 25 $o cubic feet; $a Merriwether, Stuart; $b 458 Yonkers Road, Poughkeepsie, NY 12601; $c Purchase at auction; $d 1981/09/24; $e 81-325; $f Jonathan P. Merriwether Estate; $h $7,850.
# (the literal $ in $h is written \$ in the render marker, plain $ in the value)
{
    # render: [doc §3.19] 541 0# $3 5 diaries $n 25 $o cubic feet $a Merriwether, Stuart $b 458 Yonkers Road, Poughkeepsie, NY 12601 $c Purchase at auction $d 1981/09/24 $e 81-325 $f Jonathan P. Merriwether Estate $h \$7,850
    my $field = make_field( '541', '0', '#', '3' => '5 diaries', n => '25', o => 'cubic feet', a => 'Merriwether, Stuart', b => '458 Yonkers Road, Poughkeepsie, NY 12601', c => 'Purchase at auction', d => '1981/09/24', e => '81-325', f => 'Jonathan P. Merriwether Estate', h => '$7,850' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'postfix' );
    is( $result[1], '5 diaries', '541 ex2 postfix: $3 unchanged (3n suppressed)' );
    is( $result[3], '25', '541 ex2 postfix: $n 1 unchanged (first content; no punct)' );
    is( $result[5], 'cubic feet; ', '541 ex2 postfix: $o gets "; " (next $a keyed)' );
    is( $result[7], 'Merriwether, Stuart; ', '541 ex2 postfix: $a gets "; "' );
    is( $result[9], '458 Yonkers Road, Poughkeepsie, NY 12601; ', '541 ex2 postfix: $b gets "; "' );
    is( $result[11], 'Purchase at auction; ', '541 ex2 postfix: $c gets "; "' );
    is( $result[13], '1981/09/24; ', '541 ex2 postfix: $d gets "; "' );
    is( $result[15], '81-325; ', '541 ex2 postfix: $e gets "; "' );
    is( $result[17], 'Jonathan P. Merriwether Estate; ', '541 ex2 postfix: $f gets "; "' );
    is( $result[19], '$7,850', '541 ex2 postfix: $h unchanged (literal $)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'prefix' );
    is( $result_pr[1], '5 diaries', '541 ex2 prefix: $3 unchanged' );
    is( $result_pr[3], '25', '541 ex2 prefix: $n 1 unchanged (empty pending from 3n)' );
    is( $result_pr[5], 'cubic feet', '541 ex2 prefix: $o unchanged (no pending — next $n not yet)' );
    is( $result_pr[7], '; Merriwether, Stuart', '541 ex2 prefix: $a gets "; " prepended' );
    is( $result_pr[9], '; 458 Yonkers Road, Poughkeepsie, NY 12601', '541 ex2 prefix: $b gets "; " prepended' );
    is( $result_pr[11], '; Purchase at auction', '541 ex2 prefix: $c gets "; " prepended' );
    is( $result_pr[13], '; 1981/09/24', '541 ex2 prefix: $d gets "; " prepended' );
    is( $result_pr[15], '; 81-325', '541 ex2 prefix: $e gets "; " prepended' );
    is( $result_pr[17], '; Jonathan P. Merriwether Estate', '541 ex2 prefix: $f gets "; " prepended' );
    is( $result_pr[19], '; $7,850', '541 ex2 prefix: $h gets "; " prepended (from $f)' );

    check_combined( \@result, \@result_pr, '541 ex2: combined string identical' );
}

# --- 541 constructed: repeatable $n/$o runs (doc §3.19 ex 3) ---
# Doc: Current: 541 ## $a Wisconsin Office of the Commissioner of Insurance; $e 81-141002; $c Records Center transfer; $n 54 $o cubic feet; $n 12 $o reels of computer tape; $d 1981/05/11.
{
    # render: [doc §3.19] 541 ## $a Wisconsin Office of the Commissioner of Insurance $e 81-141002 $c Records Center transfer $n 54 $o cubic feet $n 12 $o reels of computer tape $d 1981/05/11
    my $field = make_field( '541', ' ', ' ', a => 'Wisconsin Office of the Commissioner of Insurance', e => '81-141002', c => 'Records Center transfer', n => '54', o => 'cubic feet', n => '12', o => 'reels of computer tape', d => '1981/05/11' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'postfix' );
    is( $result[1], 'Wisconsin Office of the Commissioner of Insurance; ', '541 constructed postfix: $a gets "; " for $e' );
    is( $result[3], '81-141002; ', '541 constructed postfix: $e gets "; " for $c' );
    is( $result[5], 'Records Center transfer; ', '541 constructed postfix: $c gets "; " for first $n' );
    is( $result[7], '54', '541 constructed postfix: $n 1 unchanged ($o not keyed)' );
    is( $result[9], 'cubic feet; ', '541 constructed postfix: $o 1 gets "; " (next $n keyed)' );
    is( $result[11], '12', '541 constructed postfix: $n 2 unchanged ($o not keyed)' );
    is( $result[13], 'reels of computer tape; ', '541 constructed postfix: $o 2 gets "; " (next $d keyed)' );
    is( $result[15], '1981/05/11', '541 constructed postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'541'}, 'prefix' );
    is( $result_pr[1], 'Wisconsin Office of the Commissioner of Insurance', '541 constructed prefix: $a unchanged' );
    is( $result_pr[3], '; 81-141002', '541 constructed prefix: $e gets "; " prepended' );
    is( $result_pr[5], '; Records Center transfer', '541 constructed prefix: $c gets "; " prepended' );
    is( $result_pr[7], '; 54', '541 constructed prefix: $n 1 gets "; " prepended (from $c)' );
    is( $result_pr[9], 'cubic feet', '541 constructed prefix: $o 1 unchanged' );
    is( $result_pr[11], '; 12', '541 constructed prefix: $n 2 gets "; " prepended (from $o1->$n2)' );
    is( $result_pr[13], 'reels of computer tape', '541 constructed prefix: $o 2 unchanged' );
    is( $result_pr[15], '; 1981/05/11', '541 constructed prefix: $d gets "; " prepended (from $o2->$d)' );

    check_combined( \@result, \@result_pr, '541 constructed: combined string identical' );
}


# =====================================================================
# 544 – Location of Other Archival Materials Note (spec §3.20)
# $a/$b/$c/$e '; ', $d/$n N/A. $3 lead-in suppressed.
# =====================================================================

# --- 544 ex 1: $d/$e/$b/$c (doc §3.20) ---
# Doc: Current: 544 ## $d William Fords Provenance; $e Freen College; $b 727 Prologue Blvd., History City, MA $c USA.
{
    # render: [doc §3.20] 544 ## $d William Fords Provenance $e Freen College $b 727 Prologue Blvd., History City, MA $c USA
    my $field = make_field( '544', ' ', ' ', d => 'William Fords Provenance', e => 'Freen College', b => '727 Prologue Blvd., History City, MA', c => 'USA' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'544'}, 'postfix' );
    is( $result[1], 'William Fords Provenance; ', '544 ex1 postfix: $d gets "; " for $e' );
    is( $result[3], 'Freen College; ', '544 ex1 postfix: $e gets "; " for $b' );
    is( $result[5], '727 Prologue Blvd., History City, MA; ', '544 ex1 postfix: $b gets "; " for $c' );
    is( $result[7], 'USA', '544 ex1 postfix: $c unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'544'}, 'prefix' );
    is( $result_pr[1], 'William Fords Provenance', '544 ex1 prefix: $d unchanged' );
    is( $result_pr[3], '; Freen College', '544 ex1 prefix: $e gets "; " prepended' );
    is( $result_pr[5], '; 727 Prologue Blvd., History City, MA', '544 ex1 prefix: $b gets "; " prepended' );
    is( $result_pr[7], '; USA', '544 ex1 prefix: $c gets "; " prepended' );

    check_combined( \@result, \@result_pr, '544 ex1: combined string identical' );
}

# --- 544 ex 2: $d/$a/$b/$c/$e (doc §3.20 ex 3) ---
# Doc: Current: 544 ## $d Records of the Rhode Island Loan Office of the Bureau of Public Debt, 1776-1817; $a Newport Historical Society; $b 82 Touro Street, Newport, RI 02840; $c USA; $e Not transferred to the Second Bank of the United States at the time of its establishment, March 3, 1817.
{
    # render: [doc §3.20] 544 ## $d Records of the Rhode Island Loan Office of the Bureau of Public Debt, 1776-1817 $a Newport Historical Society $b 82 Touro Street, Newport, RI 02840 $c USA $e Not transferred to the Second Bank of the United States at the time of its establishment, March 3, 1817
    my $field = make_field( '544', ' ', ' ', d => 'Records of the Rhode Island Loan Office of the Bureau of Public Debt, 1776-1817', a => 'Newport Historical Society', b => '82 Touro Street, Newport, RI 02840', c => 'USA', e => 'Not transferred to the Second Bank of the United States at the time of its establishment, March 3, 1817' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'544'}, 'postfix' );
    is( $result[1], 'Records of the Rhode Island Loan Office of the Bureau of Public Debt, 1776-1817; ', '544 ex2 postfix: $d gets "; " for $a' );
    is( $result[3], 'Newport Historical Society; ', '544 ex2 postfix: $a gets "; " for $b' );
    is( $result[5], '82 Touro Street, Newport, RI 02840; ', '544 ex2 postfix: $b gets "; " for $c' );
    is( $result[7], 'USA; ', '544 ex2 postfix: $c gets "; " for $e' );
    is( $result[9], 'Not transferred to the Second Bank of the United States at the time of its establishment, March 3, 1817', '544 ex2 postfix: $e unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'544'}, 'prefix' );
    is( $result_pr[1], 'Records of the Rhode Island Loan Office of the Bureau of Public Debt, 1776-1817', '544 ex2 prefix: $d unchanged' );
    is( $result_pr[3], '; Newport Historical Society', '544 ex2 prefix: $a gets "; " prepended' );
    is( $result_pr[5], '; 82 Touro Street, Newport, RI 02840', '544 ex2 prefix: $b gets "; " prepended' );
    is( $result_pr[7], '; USA', '544 ex2 prefix: $c gets "; " prepended' );
    is( $result_pr[9], '; Not transferred to the Second Bank of the United States at the time of its establishment, March 3, 1817', '544 ex2 prefix: $e gets "; " prepended' );

    check_combined( \@result, \@result_pr, '544 ex2: combined string identical' );
}

# =====================================================================
# 546 – Language Note (spec §3.21)
# $b '; '. $a N/A. $3 lead-in suppressed.
# =====================================================================

# --- 546 ex 1: $3 + repeatable $b (doc §3.21) ---
# Doc: Current: 546 ## $3 John P. Harrington field notebooks $a Zuni; $b Pictograms; $b Phonetic alphabet.
{
    # render: [doc §3.21] 546 ## $3 John P. Harrington field notebooks $a Zuni $b Pictograms $b Phonetic alphabet
    my $field = make_field( '546', ' ', ' ', '3' => 'John P. Harrington field notebooks', a => 'Zuni', b => 'Pictograms', b => 'Phonetic alphabet' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'546'}, 'postfix' );
    is( $result[1], 'John P. Harrington field notebooks', '546 ex1 postfix: $3 unchanged' );
    is( $result[3], 'Zuni; ', '546 ex1 postfix: $a gets "; " for first $b' );
    is( $result[5], 'Pictograms; ', '546 ex1 postfix: $b 1 gets "; " (bb boundary)' );
    is( $result[7], 'Phonetic alphabet', '546 ex1 postfix: $b 2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'546'}, 'prefix' );
    is( $result_pr[1], 'John P. Harrington field notebooks', '546 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], 'Zuni', '546 ex1 prefix: $a unchanged' );
    is( $result_pr[5], '; Pictograms', '546 ex1 prefix: $b 1 gets "; " prepended' );
    is( $result_pr[7], '; Phonetic alphabet', '546 ex1 prefix: $b 2 gets "; " prepended' );

    check_combined( \@result, \@result_pr, '546 ex1: combined string identical' );
}

# --- 546 constructed: $3 directly before $b is suppressed ---
{
    # render: 546 ## $3 English notes $b Zuni $b Pictograms
    my $field = make_field( '546', ' ', ' ', '3' => 'English notes', b => 'Zuni', b => 'Pictograms' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'546'}, 'postfix' );
    is( $result[1], 'English notes', '546 constructed postfix: $3 unchanged (3b suppressed)' );
    is( $result[3], 'Zuni; ', '546 constructed postfix: $b 1 gets "; " (bb boundary)' );
    is( $result[5], 'Pictograms', '546 constructed postfix: $b 2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'546'}, 'prefix' );
    is( $result_pr[1], 'English notes', '546 constructed prefix: $3 unchanged' );
    is( $result_pr[3], 'Zuni', '546 constructed prefix: $b 1 unchanged' );
    is( $result_pr[5], '; Pictograms', '546 constructed prefix: $b 2 gets "; " prepended' );

    check_combined( \@result, \@result_pr, '546 constructed: combined string identical' );
}


# =====================================================================
# 555 – Cumulative Index/Finding Aids Note (spec §3.22)
# $b/$c/$d '; ', $u '. '. $a N/A. $3 lead-in suppressed.
# =====================================================================

# --- 555 ex 1: $u '. ' (doc §3.22) ---
# Doc: Current: 555 8# $a Finding aid available in the Manuscript Reading Room and on Internet. $u ...
{
    # render: [doc §3.22] 555 8# $a Finding aid available in the Manuscript Reading Room and on Internet $u http://example.org/findingaid
    my $field = make_field( '555', '8', '#', a => 'Finding aid available in the Manuscript Reading Room and on Internet', u => 'http://example.org/findingaid' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'555'}, 'postfix' );
    is( $result[1], 'Finding aid available in the Manuscript Reading Room and on Internet. ', '555 ex1 postfix: $a gets ". " for $u' );
    is( $result[3], 'http://example.org/findingaid', '555 ex1 postfix: $u unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'555'}, 'prefix' );
    is( $result_pr[1], 'Finding aid available in the Manuscript Reading Room and on Internet', '555 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '. http://example.org/findingaid', '555 ex1 prefix: $u gets ". " prepended' );

    check_combined( \@result, \@result_pr, '555 ex1: combined string identical' );
}

# --- 555 ex 2: $3 + $a + $b/$b/$d (doc §3.22 ex 3) ---
# Doc: Current: 555 0# $3 Claims settled under Treaty of Washington, May 8, 1871 $a Preliminary inventory prepared in 1962; $b Available in NARS central search room; $b NARS Publications Sales Branch; $d Ulibarri, George S. ...
{
    # render: [doc §3.22] 555 0# $3 Claims settled under Treaty of Washington, May 8, 1871 $a Preliminary inventory prepared in 1962 $b Available in NARS central search room $b NARS Publications Sales Branch $d Ulibarri, George S.
    my $field = make_field( '555', '0', '#', '3' => 'Claims settled under Treaty of Washington, May 8, 1871', a => 'Preliminary inventory prepared in 1962', b => 'Available in NARS central search room', b => 'NARS Publications Sales Branch', d => 'Ulibarri, George S.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'555'}, 'postfix' );
    is( $result[1], 'Claims settled under Treaty of Washington, May 8, 1871', '555 ex2 postfix: $3 unchanged (no "; ")' );
    is( $result[3], 'Preliminary inventory prepared in 1962; ', '555 ex2 postfix: $a gets "; " for $b' );
    is( $result[5], 'Available in NARS central search room; ', '555 ex2 postfix: $b 1 gets "; " (bb boundary)' );
    is( $result[7], 'NARS Publications Sales Branch; ', '555 ex2 postfix: $b 2 gets "; " for $d' );
    is( $result[9], 'Ulibarri, George S.', '555 ex2 postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'555'}, 'prefix' );
    is( $result_pr[1], 'Claims settled under Treaty of Washington, May 8, 1871', '555 ex2 prefix: $3 unchanged' );
    is( $result_pr[3], 'Preliminary inventory prepared in 1962', '555 ex2 prefix: $a unchanged' );
    is( $result_pr[5], '; Available in NARS central search room', '555 ex2 prefix: $b 1 gets "; " prepended' );
    is( $result_pr[7], '; NARS Publications Sales Branch', '555 ex2 prefix: $b 2 gets "; " prepended' );
    is( $result_pr[9], '; Ulibarri, George S.', '555 ex2 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '555 ex2: combined string identical' );
}

# =====================================================================
# 562 – Copy and Version Identification Note (spec §3.23)
# $b/$c/$d/$e '; '. $a N/A. $3 lead-in suppressed.
# =====================================================================

# --- 562 ex 1: $e then $b (doc §3.23) ---
# Doc: Current: 562 ## $e 3 copies kept; $b Labelled as president's desk copy, board of directors' working file copy, and public release copy.
{
    # render: [doc §3.23] 562 ## $e 3 copies kept $b Labelled as president's desk copy, board of directors' working file copy, and public release copy
    my $field = make_field( '562', ' ', ' ', e => '3 copies kept', b => 'Labelled as president\'s desk copy, board of directors\' working file copy, and public release copy' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'562'}, 'postfix' );
    is( $result[1], '3 copies kept; ', '562 ex1 postfix: $e gets "; " for $b' );
    is( $result[3], 'Labelled as president\'s desk copy, board of directors\' working file copy, and public release copy', '562 ex1 postfix: $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'562'}, 'prefix' );
    is( $result_pr[1], '3 copies kept', '562 ex1 prefix: $e unchanged' );
    is( $result_pr[3], '; Labelled as president\'s desk copy, board of directors\' working file copy, and public release copy', '562 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '562 ex1: combined string identical' );
}

# --- 562 ex 2: $b then $e (doc §3.23) ---
# Doc: Current: 562 ## $b Marked: "For internal circulation only"; $e 2 copies.
{
    # render: [doc §3.23] 562 ## $b Marked: "For internal circulation only" $e 2 copies
    my $field = make_field( '562', ' ', ' ', b => 'Marked: \"For internal circulation only\"', e => '2 copies' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'562'}, 'postfix' );
    is( $result[1], 'Marked: \"For internal circulation only\"; ', '562 ex2 postfix: $b gets "; " for $e' );
    is( $result[3], '2 copies', '562 ex2 postfix: $e unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'562'}, 'prefix' );
    is( $result_pr[1], 'Marked: \"For internal circulation only\"', '562 ex2 prefix: $b unchanged' );
    is( $result_pr[3], '; 2 copies', '562 ex2 prefix: $e gets "; " prepended' );

    check_combined( \@result, \@result_pr, '562 ex2: combined string identical' );
}


# =====================================================================
# 565 – Case File Characteristics Note (spec §3.24)
# $b/$c/$d/$e '; '. $a N/A. $3 lead-in suppressed.
# =====================================================================

# --- 565 ex 1: $3 + repeatable $b/$c/$d (doc §3.24, derived shorter) ---
# Doc: Current: 565 ## $3 Military petitioners files $a 11; $b name; $b address; $b date of birth; ... $c pensioners; $d Civil War (1861-65) veterans
{
    # render: [doc §3.24 - derived] 565 ## $3 Military petitioners files $a 11 $b name $b address $c pensioners $d Civil War (1861-65) veterans
    my $field = make_field( '565', ' ', ' ', '3' => 'Military petitioners files', a => '11', b => 'name', b => 'address', c => 'pensioners', d => 'Civil War (1861-65) veterans' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'565'}, 'postfix' );
    is( $result[1], 'Military petitioners files', '565 ex1 postfix: $3 unchanged (no "; ")' );
    is( $result[3], '11; ', '565 ex1 postfix: $a gets "; " for $b' );
    is( $result[5], 'name; ', '565 ex1 postfix: $b 1 gets "; " (bb boundary)' );
    is( $result[7], 'address; ', '565 ex1 postfix: $b 2 gets "; " for $c' );
    is( $result[9], 'pensioners; ', '565 ex1 postfix: $c gets "; " for $d' );
    is( $result[11], 'Civil War (1861-65) veterans', '565 ex1 postfix: $d unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'565'}, 'prefix' );
    is( $result_pr[1], 'Military petitioners files', '565 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], '11', '565 ex1 prefix: $a unchanged' );
    is( $result_pr[5], '; name', '565 ex1 prefix: $b 1 gets "; " prepended' );
    is( $result_pr[7], '; address', '565 ex1 prefix: $b 2 gets "; " prepended' );
    is( $result_pr[9], '; pensioners', '565 ex1 prefix: $c gets "; " prepended' );
    is( $result_pr[11], '; Civil War (1861-65) veterans', '565 ex1 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '565 ex1: combined string identical' );
}

# =====================================================================
# 584 – Accumulation and Frequency of Use Note (spec §3.25)
# $a/$b '. '. $3 lead-in suppressed.
# =====================================================================

# --- 584 ex 1: $3 + repeatable $a (doc §3.25) ---
# Doc: Current: 584 ## $3 General subject files $a 45 cu. ft. average annual accumulation 1970-1979. $a 5.4 cu. ft. average monthly accumulation, 1979-82. $a Current average monthly accumulation is 2 cu. ft.
{
    # render: [doc §3.25] 584 ## $3 General subject files $a 45 cu. ft. average annual accumulation 1970-1979 $a 5.4 cu. ft. average monthly accumulation, 1979-82 $a Current average monthly accumulation is 2 cu. ft.
    my $field = make_field( '584', ' ', ' ', '3' => 'General subject files', a => '45 cu. ft. average annual accumulation 1970-1979', a => '5.4 cu. ft. average monthly accumulation, 1979-82', a => 'Current average monthly accumulation is 2 cu. ft.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'584'}, 'postfix' );
    is( $result[1], 'General subject files', '584 ex1 postfix: $3 unchanged (3a suppressed)' );
    is( $result[3], '45 cu. ft. average annual accumulation 1970-1979. ', '584 ex1 postfix: $a 1 gets ". " (aa boundary)' );
    is( $result[5], '5.4 cu. ft. average monthly accumulation, 1979-82. ', '584 ex1 postfix: $a 2 gets ". " (aa boundary)' );
    is( $result[7], 'Current average monthly accumulation is 2 cu. ft.', '584 ex1 postfix: $a 3 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'584'}, 'prefix' );
    is( $result_pr[1], 'General subject files', '584 ex1 prefix: $3 unchanged' );
    is( $result_pr[3], '45 cu. ft. average annual accumulation 1970-1979', '584 ex1 prefix: $a 1 unchanged (empty pending from 3a)' );
    is( $result_pr[5], '. 5.4 cu. ft. average monthly accumulation, 1979-82', '584 ex1 prefix: $a 2 gets ". " prepended' );
    is( $result_pr[7], '. Current average monthly accumulation is 2 cu. ft.', '584 ex1 prefix: $a 3 gets ". " prepended' );

    check_combined( \@result, \@result_pr, '584 ex1: combined string identical' );
}

# --- 584 ex 2: repeatable $b (doc §3.25 ex 2) ---
# Doc: Current: 584 ## $b An average of 15 reference requests per month, with peak demand during June and December. $b Total reference requests for 1984: 179.
{
    # render: [doc §3.25] 584 ## $b An average of 15 reference requests per month, with peak demand during June and December $b Total reference requests for 1984: 179
    my $field = make_field( '584', ' ', ' ', b => 'An average of 15 reference requests per month, with peak demand during June and December', b => 'Total reference requests for 1984: 179' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'584'}, 'postfix' );
    is( $result[1], 'An average of 15 reference requests per month, with peak demand during June and December. ', '584 ex2 postfix: $b 1 gets ". " (bb boundary)' );
    is( $result[3], 'Total reference requests for 1984: 179', '584 ex2 postfix: $b 2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'584'}, 'prefix' );
    is( $result_pr[1], 'An average of 15 reference requests per month, with peak demand during June and December', '584 ex2 prefix: $b 1 unchanged' );
    is( $result_pr[3], '. Total reference requests for 1984: 179', '584 ex2 prefix: $b 2 gets ". " prepended' );

    check_combined( \@result, \@result_pr, '584 ex2: combined string identical' );
}

done_testing();
