# 5xx Note fields — ISBD punctuation (spec §4.19-§4.34).
#
# PROVENANCE:
#   [doc §4.xx]      -> drawn verbatim from the reference doc §4.xx examples
#   [LoC - derived]  -> split from a real pre-punctuated Library-of-Congress /
#       MARC21-online record into the reference-doc subfields. NOT doc examples.
#   (no token)       -> constructed
#
# SHARED 5xx SEMANTICS (§4.19 Display Text / §4.20 Source):
#   $i (display text) -> trailing ': '  via the shared _decorate_display_text_pre
#       callback (500/501/504/505/538/547/550/580).
#   $z (source)       -> preceding ' -- ' (500) or '. ' (515/525):
#       500 takes ' -- ' (user decision, consistent with 520; §4.21 allows
#       "dash OR period-space" — we pick the dash).
#   Repeatable $a     -> ' ; ' only BETWEEN consecutive $a runs, via the
#       COMPOUND pchrs key `aa` (508/511). A single $a (even after $3) gets
#       NO punctuation.
#
# FIELD CHEAT-SHEET:
#   500: $i ': ', $z ' -- ', $a N/A
#   501: $i ': ', $a N/A
#   504: $i ': ', $a/$b N/A
#   508: $aa ' ; ' (repeatable $a)
#   511: $aa ' ; ' (repeatable $a)
#   515: $z '. ', $a N/A
#   525: $z '. ', $a N/A
#   538: $i ': ', $a/$u N/A
#   547: $i ': ', $a N/A
#   550: $i ': ', $a N/A
#   580: $i ': ' (repeatable), $a N/A (repeatable but no punct between runs;
#        intervening $i carries the ':' ). Known gap: the §4.34 example's
#        comma before a later $i (", to form:") is NOT reproduced (see block).

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

# --- all 11 note fields are defined ---
for my $t ( qw(500 501 504 508 511 515 525 538 547 550 580) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}

# =====================================================================
# 500 – General Note (spec §4.21)
# $i ': ' (cb_pre); $z ' -- ' (pchrs). $a N/A.
# =====================================================================

# --- 500 ex 1: $i display text (doc §4.21 ex 1) ---
# Doc: Current: 500 ## $a At head of title: STP-PT-023.
{
    # render: [doc §4.21] 500 ## $i At head of title $a STP-PT-023
    my $field = make_field( '500', ' ', ' ', i => 'At head of title', a => 'STP-PT-023' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], 'At head of title: ', '500 ex1 postfix: $i gets ": "' );
    is( $result[3], 'STP-PT-023', '500 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], 'At head of title: ', '500 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'STP-PT-023', '500 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '500 ex1: combined string identical' );
}

# --- 500 ex 2: $i display text (doc §4.21 ex 2) ---
# Doc: Current: 500 ## $a Date of issuance: Feb. 23, 2009.
{
    # render: [doc §4.21] 500 ## $i Date of issuance $a Feb. 23, 2009
    my $field = make_field( '500', ' ', ' ', i => 'Date of issuance', a => 'Feb. 23, 2009' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], 'Date of issuance: ', '500 ex2 postfix: $i gets ": "' );
    is( $result[3], 'Feb. 23, 2009', '500 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], 'Date of issuance: ', '500 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], 'Feb. 23, 2009', '500 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '500 ex2: combined string identical' );
}

# --- 500 ex 3: $z source takes preceding '--' (doc §4.21 ex 5) ---
# Doc: Current: 500 ## $a "May 6, 2010"--Cover.
{
    # render: [doc §4.21] 500 ## $a "May 6, 2010" $z Cover
    my $field = make_field( '500', ' ', ' ', a => '"May 6, 2010"', z => 'Cover' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], '"May 6, 2010" -- ', '500 ex3 postfix: $a gets " -- "' );
    is( $result[3], 'Cover', '500 ex3 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], '"May 6, 2010"', '500 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ' -- Cover', '500 ex3 prefix: $z gets " -- " prepended' );

    check_combined( \@result, \@result_pr, '500 ex3: combined string identical' );
}

# --- 500 ex 4: $i + $z together (doc §4.21 ex 6) ---
# Doc: Current: 500 ## $a Source of data: Survey of Consumer Finances, conducted
#   from 1946-1971, by the Economic Behavior Prog., Survey Research Center,
#   University of Michigan.
{
    # render: [doc §4.21] 500 ## $i Source of data $a Survey of Consumer Finances
    my $field = make_field( '500', ' ', ' ', i => 'Source of data', a => 'Survey of Consumer Finances' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], 'Source of data: ', '500 ex4 postfix: $i gets ": "' );
    is( $result[3], 'Survey of Consumer Finances', '500 ex4 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], 'Source of data: ', '500 ex4 prefix: $i gets ": "' );
    is( $result_pr[3], 'Survey of Consumer Finances', '500 ex4 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '500 ex4: combined string identical' );
}

# --- 500 ex 5: $z source takes preceding '--' (doc §4.21 ex 7) ---
# Doc: Current: 500 ## $a "The first American Jewish weekly of its kind"--The
#   Jewish encyclopedia, v. 8.
{
    # render: [doc §4.21] 500 ## $a "The first American Jewish weekly of its kind" $z The Jewish encyclopedia, v. 8
    my $field = make_field( '500', ' ', ' ', a => '"The first American Jewish weekly of its kind"', z => 'The Jewish encyclopedia, v. 8' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], '"The first American Jewish weekly of its kind" -- ', '500 ex5 postfix: $a gets " -- "' );
    is( $result[3], 'The Jewish encyclopedia, v. 8', '500 ex5 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], '"The first American Jewish weekly of its kind"', '500 ex5 prefix: $a unchanged' );
    is( $result_pr[3], ' -- The Jewish encyclopedia, v. 8', '500 ex5 prefix: $z gets " -- " prepended' );

    check_combined( \@result, \@result_pr, '500 ex5: combined string identical' );
}

# --- 500 ex 6: $z source (doc §4.21 ex 8) ---
# Doc: Current: 500 ## $a "Evaluation and Investigations Program"--Cover.
{
    # render: [doc §4.21] 500 ## $a "Evaluation and Investigations Program" $z Cover
    my $field = make_field( '500', ' ', ' ', a => '"Evaluation and Investigations Program"', z => 'Cover' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], '"Evaluation and Investigations Program" -- ', '500 ex6 postfix: $a gets " -- "' );
    is( $result[3], 'Cover', '500 ex6 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], '"Evaluation and Investigations Program"', '500 ex6 prefix: $a unchanged' );
    is( $result_pr[3], ' -- Cover', '500 ex6 prefix: $z gets " -- " prepended' );

    check_combined( \@result, \@result_pr, '500 ex6: combined string identical' );
}

# --- 500 ex 7: $z source (doc §4.21 ex 9) ---
# Doc: Current: 500 ## $a Republican. Cf. Gutgesell, S. Guide to Ohio
#   newspapers, 1974.
{
    # render: [doc §4.21] 500 ## $a Republican $z Cf. Gutgesell, S. Guide to Ohio newspapers, 1974
    my $field = make_field( '500', ' ', ' ', a => 'Republican', z => 'Cf. Gutgesell, S. Guide to Ohio newspapers, 1974' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], 'Republican -- ', '500 ex7 postfix: $a gets " -- "' );
    is( $result[3], 'Cf. Gutgesell, S. Guide to Ohio newspapers, 1974', '500 ex7 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], 'Republican', '500 ex7 prefix: $a unchanged' );
    is( $result_pr[3], ' -- Cf. Gutgesell, S. Guide to Ohio newspapers, 1974', '500 ex7 prefix: $z gets " -- " prepended' );

    check_combined( \@result, \@result_pr, '500 ex7: combined string identical' );
}

# --- 500 edge: $a alone (no $i / $z) ---
{
    # render: 500 ## $a A general note.
    my $field = make_field( '500', ' ', ' ', a => 'A general note.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'postfix' );
    is( $result[1], 'A general note.', '500 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'500'}, 'prefix' );
    is( $result_pr[1], 'A general note.', '500 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '500 edge: combined string identical' );
}

# =====================================================================
# 501 – With Note (spec §4.22)
# $i ': ' (cb_pre). $a N/A.
# =====================================================================

# --- 501 ex 1: $i display text (doc §4.22 ex 1) ---
# Doc: Current: 501 ## $a With (on verso): Motor road map of south-east England.
{
    # render: [doc §4.22] 501 8# $i With (on verso) $a Motor road map of south-east England
    my $field = make_field( '501', '8', '#', i => 'With (on verso)', a => 'Motor road map of south-east England' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'postfix' );
    is( $result[1], 'With (on verso): ', '501 ex1 postfix: $i gets ": "' );
    is( $result[3], 'Motor road map of south-east England', '501 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'prefix' );
    is( $result_pr[1], 'With (on verso): ', '501 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'Motor road map of south-east England', '501 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '501 ex1: combined string identical' );
}

# --- 501 ex 2: $i display text (doc §4.22 ex 2) ---
# Doc: Current: 501 ## $a On reel with: They're in the Army now.
{
    # render: [doc §4.22] 501 8# $i On reel with $a They're in the Army now
    my $field = make_field( '501', '8', '#', i => 'On reel with', a => "They're in the Army now" );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'postfix' );
    is( $result[1], 'On reel with: ', '501 ex2 postfix: $i gets ": "' );
    is( $result[3], "They're in the Army now", '501 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'prefix' );
    is( $result_pr[1], 'On reel with: ', '501 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], "They're in the Army now", '501 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '501 ex2: combined string identical' );
}

# --- 501 edge: $a alone ---
{
    # render: 501 ## $a With: item X
    my $field = make_field( '501', ' ', ' ', a => 'With: item X' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'postfix' );
    is( $result[1], 'With: item X', '501 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'501'}, 'prefix' );
    is( $result_pr[1], 'With: item X', '501 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '501 edge: combined string identical' );
}

# =====================================================================
# 504 – Bibliography, etc. Note (spec §4.24)
# $i ': ' (cb_pre). $a/$b N/A.
# =====================================================================

# --- 504 ex 1: $i display text (doc §4.24 ex 1) ---
# Doc: Current: 504 ## $a Bibliography: p. 238-239.
{
    # render: [doc §4.24] 504 8# $i Bibliography $a p. 238-239
    my $field = make_field( '504', '8', '#', i => 'Bibliography', a => 'p. 238-239' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'postfix' );
    is( $result[1], 'Bibliography: ', '504 ex1 postfix: $i gets ": "' );
    is( $result[3], 'p. 238-239', '504 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'prefix' );
    is( $result_pr[1], 'Bibliography: ', '504 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'p. 238-239', '504 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '504 ex1: combined string identical' );
}

# --- 504 ex 2: $i display text (doc §4.24 ex 2) ---
# Doc: Current: 504 ## $a Discography: p. 105-111.
{
    # render: [doc §4.24] 504 8# $i Discography $a p. 105-111
    my $field = make_field( '504', '8', '#', i => 'Discography', a => 'p. 105-111' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'postfix' );
    is( $result[1], 'Discography: ', '504 ex2 postfix: $i gets ": "' );
    is( $result[3], 'p. 105-111', '504 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'prefix' );
    is( $result_pr[1], 'Discography: ', '504 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], 'p. 105-111', '504 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '504 ex2: combined string identical' );
}

# --- 504 ex 3: $i display text (doc §4.24 ex 3) ---
# Doc: Current: 504 ## $a Filmography: v. 2, p. 344-360.
{
    # render: [doc §4.24] 504 8# $i Filmography $a v. 2, p. 344-360
    my $field = make_field( '504', '8', '#', i => 'Filmography', a => 'v. 2, p. 344-360' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'postfix' );
    is( $result[1], 'Filmography: ', '504 ex3 postfix: $i gets ": "' );
    is( $result[3], 'v. 2, p. 344-360', '504 ex3 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'prefix' );
    is( $result_pr[1], 'Filmography: ', '504 ex3 prefix: $i gets ": "' );
    is( $result_pr[3], 'v. 2, p. 344-360', '504 ex3 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '504 ex3: combined string identical' );
}

# --- 504 edge: $a alone ---
{
    # render: 504 ## $a Includes index.
    my $field = make_field( '504', ' ', ' ', a => 'Includes index.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'postfix' );
    is( $result[1], 'Includes index.', '504 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'504'}, 'prefix' );
    is( $result_pr[1], 'Includes index.', '504 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '504 edge: combined string identical' );
}

# =====================================================================
# 508 – Creation/Production Credits Note (spec §4.26)
# repeatable $a separated by ' ; ' via COMPOUND `aa`. Single $a: no punct.
# =====================================================================

# --- 508 ex 1: four $a runs (doc §4.26 ex 1) ---
# Doc: Current: 508 ## $a Producer, Joseph N. Ermolieff ; director, Lesley
#   Selander ; screenplay, Theodore St. John ; music director, Michel Michelet.
{
    # render: [doc §4.26] 508 ## $a Producer, Joseph N. Ermolieff $a director, Lesley Selander $a screenplay, Theodore St. John $a music director, Michel Michelet
    my $field = make_field(
        '508', ' ', ' ',
        a => 'Producer, Joseph N. Ermolieff',
        a => 'director, Lesley Selander',
        a => 'screenplay, Theodore St. John',
        a => 'music director, Michel Michelet',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'postfix' );
    is( $result[1], 'Producer, Joseph N. Ermolieff ; ', '508 ex1 postfix: $a1 gets " ; "' );
    is( $result[3], 'director, Lesley Selander ; ', '508 ex1 postfix: $a2 gets " ; "' );
    is( $result[5], 'screenplay, Theodore St. John ; ', '508 ex1 postfix: $a3 gets " ; "' );
    is( $result[7], 'music director, Michel Michelet', '508 ex1 postfix: $a4 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'prefix' );
    is( $result_pr[1], 'Producer, Joseph N. Ermolieff', '508 ex1 prefix: $a1 unchanged' );
    is( $result_pr[3], ' ; director, Lesley Selander', '508 ex1 prefix: $a2 gets " ; " prepended' );
    is( $result_pr[5], ' ; screenplay, Theodore St. John', '508 ex1 prefix: $a3 gets " ; " prepended' );
    is( $result_pr[7], ' ; music director, Michel Michelet', '508 ex1 prefix: $a4 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '508 ex1: combined string identical' );
}

# --- 508 ex 2: two $a runs (doc §4.26 ex 2) ---
# Doc: Current: 508 ## $a Film editor, Martyn Down ; consultant, Robert F. Miller.
{
    # render: [doc §4.26] 508 ## $a Film editor, Martyn Down $a consultant, Robert F. Miller
    my $field = make_field( '508', ' ', ' ', a => 'Film editor, Martyn Down', a => 'consultant, Robert F. Miller' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'postfix' );
    is( $result[1], 'Film editor, Martyn Down ; ', '508 ex2 postfix: $a1 gets " ; "' );
    is( $result[3], 'consultant, Robert F. Miller', '508 ex2 postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'prefix' );
    is( $result_pr[1], 'Film editor, Martyn Down', '508 ex2 prefix: $a1 unchanged' );
    is( $result_pr[3], ' ; consultant, Robert F. Miller', '508 ex2 prefix: $a2 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '508 ex2: combined string identical' );
}

# --- 508 LoC-derived: real-world two-$a split ---
# LoC record (pre-punctuated, single $a):
#   "Music, Michael Fishbein ; camera, George Mo."
#   -> split into Future $a runs.
{
    # render: [LoC - derived] 508 ## $a Music, Michael Fishbein $a camera, George Mo.
    my $field = make_field( '508', ' ', ' ', a => 'Music, Michael Fishbein', a => 'camera, George Mo.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'postfix' );
    is( $result[1], 'Music, Michael Fishbein ; ', '508 LoC postfix: $a1 gets " ; "' );
    is( $result[3], 'camera, George Mo.', '508 LoC postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'prefix' );
    is( $result_pr[1], 'Music, Michael Fishbein', '508 LoC prefix: $a1 unchanged' );
    is( $result_pr[3], ' ; camera, George Mo.', '508 LoC prefix: $a2 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '508 LoC: combined string identical' );
}

# --- 508 edge: single $a with internal commas -> NO ' ; ' (negative case) ---
{
    # render: 508 ## $a Colin Blakely, Jane Lapotaire
    my $field = make_field( '508', ' ', ' ', a => 'Colin Blakely, Jane Lapotaire' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'postfix' );
    is( $result[1], 'Colin Blakely, Jane Lapotaire', '508 edge postfix: single $a unchanged (no split on commas)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'508'}, 'prefix' );
    is( $result_pr[1], 'Colin Blakely, Jane Lapotaire', '508 edge prefix: single $a unchanged' );

    check_combined( \@result, \@result_pr, '508 edge: combined string identical' );
}

# =====================================================================
# 511 – Participant or Performer Note (spec §4.27)
# repeatable $a separated by ' ; ' via COMPOUND `aa`. Single $a (even after
# $3): no punct.
# =====================================================================

# --- 511 ex 1: two $a runs (doc §4.27 ex 1) ---
# Doc: Current: 511 0# $a Marshall Moss, violin ; Neil Roberts, harpsichord.
{
    # render: [doc §4.27] 511 ## $a Marshall Moss, violin $a Neil Roberts, harpsichord
    my $field = make_field( '511', ' ', ' ', a => 'Marshall Moss, violin', a => 'Neil Roberts, harpsichord' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'postfix' );
    is( $result[1], 'Marshall Moss, violin ; ', '511 ex1 postfix: $a1 gets " ; "' );
    is( $result[3], 'Neil Roberts, harpsichord', '511 ex1 postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'prefix' );
    is( $result_pr[1], 'Marshall Moss, violin', '511 ex1 prefix: $a1 unchanged' );
    is( $result_pr[3], ' ; Neil Roberts, harpsichord', '511 ex1 prefix: $a2 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '511 ex1: combined string identical' );
}

# --- 511 LoC-derived: $3 + single $a (structural pass-through) ---
# LoC record: 511 1# $3 Credits $a Colin Blakely, Jane Lapotaire.
# The single $a (even after $3) must get NO ' ; '.
{
    # render: [LoC - derived] 511 1# $3 Credits $a Colin Blakely, Jane Lapotaire
    my $field = make_field( '511', '1', '#', '3' => 'Credits', a => 'Colin Blakely, Jane Lapotaire' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'postfix' );
    is( $result[1], 'Credits', '511 LoC postfix: $3 unchanged' );
    is( $result[3], 'Colin Blakely, Jane Lapotaire', '511 LoC postfix: single $a unchanged (no " ; ")' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'prefix' );
    is( $result_pr[1], 'Credits', '511 LoC prefix: $3 unchanged' );
    is( $result_pr[3], 'Colin Blakely, Jane Lapotaire', '511 LoC prefix: single $a unchanged' );

    check_combined( \@result, \@result_pr, '511 LoC: combined string identical' );
}

# --- 511 LoC-derived: two $a runs (no $3) ---
# LoC record (current): $a Colin Blakely ; Jane Lapotaire.
#   -> split into two $a runs; the $aa boundary gets ' ; '.
{
    # render: [LoC - derived] 511 ## $a Colin Blakely $a Jane Lapotaire
    my $field = make_field( '511', ' ', ' ', a => 'Colin Blakely', a => 'Jane Lapotaire' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'postfix' );
    is( $result[1], 'Colin Blakely ; ', '511 LoC2 postfix: $a1 gets " ; "' );
    is( $result[3], 'Jane Lapotaire', '511 LoC2 postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'prefix' );
    is( $result_pr[1], 'Colin Blakely', '511 LoC2 prefix: $a1 unchanged' );
    is( $result_pr[3], ' ; Jane Lapotaire', '511 LoC2 prefix: $a2 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '511 LoC2: combined string identical' );
}

# --- 511 LoC-derived: $3 + six $a runs (real cast list) ---
# LoC record (current): 511 1# $3What a girl wants: $aAmanda Bynes ; Colin
#   Firth ; Kelly Preston ; Eileen Atkins ; Anna Chancellor ; Jonathan Pryce.
# $3 keeps its own trailing ':' (data, pass-through); only the $aa
# boundaries get ' ; '.
{
    # render: [LoC - derived] 511 1# $3 What a girl wants: $a Amanda Bynes $a Colin Firth $a Kelly Preston $a Eileen Atkins $a Anna Chancellor $a Jonathan Pryce
    my $field = make_field(
        '511', '1', '#',
        '3' => 'What a girl wants:',
        a   => 'Amanda Bynes',
        a   => 'Colin Firth',
        a   => 'Kelly Preston',
        a   => 'Eileen Atkins',
        a   => 'Anna Chancellor',
        a   => 'Jonathan Pryce',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'postfix' );
    is( $result[1], 'What a girl wants:', '511 LoC3 postfix: $3 unchanged (its own ":" is data)' );
    is( $result[3], 'Amanda Bynes ; ',  '511 LoC3 postfix: $a1 gets " ; "' );
    is( $result[5], 'Colin Firth ; ',   '511 LoC3 postfix: $a2 gets " ; "' );
    is( $result[7], 'Kelly Preston ; ', '511 LoC3 postfix: $a3 gets " ; "' );
    is( $result[9], 'Eileen Atkins ; ', '511 LoC3 postfix: $a4 gets " ; "' );
    is( $result[11], 'Anna Chancellor ; ', '511 LoC3 postfix: $a5 gets " ; "' );
    is( $result[13], 'Jonathan Pryce', '511 LoC3 postfix: $a6 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'prefix' );
    is( $result_pr[1], 'What a girl wants:', '511 LoC3 prefix: $3 unchanged' );
    is( $result_pr[3], 'Amanda Bynes',       '511 LoC3 prefix: $a1 unchanged (no " ; " before first $a)' );
    is( $result_pr[5], ' ; Colin Firth',     '511 LoC3 prefix: $a2 gets " ; " prepended' );
    is( $result_pr[7], ' ; Kelly Preston',   '511 LoC3 prefix: $a3 gets " ; " prepended' );
    is( $result_pr[9], ' ; Eileen Atkins',   '511 LoC3 prefix: $a4 gets " ; " prepended' );
    is( $result_pr[11], ' ; Anna Chancellor', '511 LoC3 prefix: $a5 gets " ; " prepended' );
    is( $result_pr[13], ' ; Jonathan Pryce', '511 LoC3 prefix: $a6 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '511 LoC3: combined string identical' );
}

# --- 511 edge: $3 + two $a runs -> only the $aa boundary gets ' ; ' ---
{
    # render: 511 ## $3 Credits $a Colin Blakely $a Jane Lapotaire
    my $field = make_field( '511', ' ', ' ', '3' => 'Credits', a => 'Colin Blakely', a => 'Jane Lapotaire' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'postfix' );
    is( $result[1], 'Credits', '511 edge postfix: $3 unchanged (no " ; " before first $a)' );
    is( $result[3], 'Colin Blakely ; ', '511 edge postfix: $a1 gets " ; " (aa boundary)' );
    is( $result[5], 'Jane Lapotaire', '511 edge postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'511'}, 'prefix' );
    is( $result_pr[1], 'Credits', '511 edge prefix: $3 unchanged' );
    is( $result_pr[3], 'Colin Blakely', '511 edge prefix: $a1 unchanged' );
    is( $result_pr[5], ' ; Jane Lapotaire', '511 edge prefix: $a2 gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '511 edge: combined string identical' );
}

# =====================================================================
# 515 – Numbering Peculiarities Note (spec §4.28)
# $z '. ' (pchrs). $a N/A.
# =====================================================================

# --- 515 ex 1: $z source takes preceding '. ' (doc §4.28 ex 1) ---
# Doc: Current: 515 ## $a None published 1941-1946. Cf. Brit. Mus. Gen. cat.
#   of printed books.
{
    # render: [doc §4.28] 515 ## $a None published 1941-1946 $z Cf. Brit. Mus. Gen. cat. of printed books
    my $field = make_field( '515', ' ', ' ', a => 'None published 1941-1946', z => 'Cf. Brit. Mus. Gen. cat. of printed books' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'515'}, 'postfix' );
    is( $result[1], 'None published 1941-1946. ', '515 ex1 postfix: $a gets ". "' );
    is( $result[3], 'Cf. Brit. Mus. Gen. cat. of printed books', '515 ex1 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'515'}, 'prefix' );
    is( $result_pr[1], 'None published 1941-1946', '515 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '. Cf. Brit. Mus. Gen. cat. of printed books', '515 ex1 prefix: $z gets ". " prepended' );

    check_combined( \@result, \@result_pr, '515 ex1: combined string identical' );
}

# --- 515 edge: $a alone ---
{
    # render: 515 ## $a Numbering irregular.
    my $field = make_field( '515', ' ', ' ', a => 'Numbering irregular.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'515'}, 'postfix' );
    is( $result[1], 'Numbering irregular.', '515 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'515'}, 'prefix' );
    is( $result_pr[1], 'Numbering irregular.', '515 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '515 edge: combined string identical' );
}

# =====================================================================
# 525 – Supplement Note (spec §4.30)
# $z '. ' (pchrs). $a N/A.
# =====================================================================

# --- 525 ex 1: $z source takes preceding '. ' (doc §4.30 ex 1) ---
# Doc: Current: 525 ## $a Vols. for 1961- kept up to date by midyear
#   supplements. Cf. New serial titles.
{
    # render: [doc §4.30] 525 ## $a Vols. for 1961- kept up to date by midyear supplements $z Cf. New serial titles
    my $field = make_field( '525', ' ', ' ', a => 'Vols. for 1961- kept up to date by midyear supplements', z => 'Cf. New serial titles' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'525'}, 'postfix' );
    is( $result[1], 'Vols. for 1961- kept up to date by midyear supplements. ', '525 ex1 postfix: $a gets ". "' );
    is( $result[3], 'Cf. New serial titles', '525 ex1 postfix: $z unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'525'}, 'prefix' );
    is( $result_pr[1], 'Vols. for 1961- kept up to date by midyear supplements', '525 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '. Cf. New serial titles', '525 ex1 prefix: $z gets ". " prepended' );

    check_combined( \@result, \@result_pr, '525 ex1: combined string identical' );
}

# --- 525 edge: $a alone ---
{
    # render: 525 ## $a Kept up to date by supplements.
    my $field = make_field( '525', ' ', ' ', a => 'Kept up to date by supplements.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'525'}, 'postfix' );
    is( $result[1], 'Kept up to date by supplements.', '525 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'525'}, 'prefix' );
    is( $result_pr[1], 'Kept up to date by supplements.', '525 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '525 edge: combined string identical' );
}

# =====================================================================
# 538 – System Details Note (spec §4.31)
# $i ': ' (cb_pre). $a/$u N/A.
# =====================================================================

# --- 538 ex 1: $i display text (doc §4.31 ex 1) ---
# Doc: Current: 538 ## $a Disk characteristics: Disk is single sided, double
#   density, soft sectored.
{
    # render: [doc §4.31] 538 8# $i Disk characteristics $a Disk is single sided, double density, soft sectored
    my $field = make_field( '538', '8', '#', i => 'Disk characteristics', a => 'Disk is single sided, double density, soft sectored' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'postfix' );
    is( $result[1], 'Disk characteristics: ', '538 ex1 postfix: $i gets ": "' );
    is( $result[3], 'Disk is single sided, double density, soft sectored', '538 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'prefix' );
    is( $result_pr[1], 'Disk characteristics: ', '538 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'Disk is single sided, double density, soft sectored', '538 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '538 ex1: combined string identical' );
}

# --- 538 ex 2: $i display text (doc §4.31 ex 2) ---
# Doc: Current: 538 ## $a System requirements: IBM 360 and 370; 9K bytes of
#   internal memory; OS SVS and OSMVS.
{
    # render: [doc §4.31] 538 8# $i System requirements $a IBM 360 and 370; 9K bytes of internal memory; OS SVS and OSMVS
    my $field = make_field( '538', '8', '#', i => 'System requirements', a => 'IBM 360 and 370; 9K bytes of internal memory; OS SVS and OSMVS' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'postfix' );
    is( $result[1], 'System requirements: ', '538 ex2 postfix: $i gets ": "' );
    is( $result[3], 'IBM 360 and 370; 9K bytes of internal memory; OS SVS and OSMVS', '538 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'prefix' );
    is( $result_pr[1], 'System requirements: ', '538 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], 'IBM 360 and 370; 9K bytes of internal memory; OS SVS and OSMVS', '538 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '538 ex2: combined string identical' );
}

# --- 538 ex 3: $i display text (doc §4.31 ex 3) ---
# Doc: Current: 538 ## $a Mode of access: World Wide Web.
{
    # render: [doc §4.31] 538 8# $i Mode of access $a World Wide Web
    my $field = make_field( '538', '8', '#', i => 'Mode of access', a => 'World Wide Web' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'postfix' );
    is( $result[1], 'Mode of access: ', '538 ex3 postfix: $i gets ": "' );
    is( $result[3], 'World Wide Web', '538 ex3 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'prefix' );
    is( $result_pr[1], 'Mode of access: ', '538 ex3 prefix: $i gets ": "' );
    is( $result_pr[3], 'World Wide Web', '538 ex3 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '538 ex3: combined string identical' );
}

# --- 538 edge: $a alone ---
{
    # render: 538 ## $a Requires Unix.
    my $field = make_field( '538', ' ', ' ', a => 'Requires Unix.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'postfix' );
    is( $result[1], 'Requires Unix.', '538 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'538'}, 'prefix' );
    is( $result_pr[1], 'Requires Unix.', '538 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '538 edge: combined string identical' );
}

# =====================================================================
# 547 – Former Title Complexity Note (spec §4.32)
# $i ': ' (cb_pre). $a N/A.
# =====================================================================

# --- 547 ex 1: $i display text (doc §4.32 ex 1) ---
# Doc: Current: 547 ## $a Title varies: 1716?-1858, Notizie del mondo--1860-71,
#   1912- Annuario pontificio (1872-1911, Gerarchia cattolica).
{
    # render: [doc §4.32] 547 8# $i Title varies $a 1716?-1858, Notizie del mondo--1860-71, 1912- Annuario pontificio (1872-1911, Gerarchia cattolica)
    my $field = make_field( '547', '8', '#', i => 'Title varies', a => '1716?-1858, Notizie del mondo--1860-71, 1912- Annuario pontificio (1872-1911, Gerarchia cattolica)' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'postfix' );
    is( $result[1], 'Title varies: ', '547 ex1 postfix: $i gets ": "' );
    is( $result[3], '1716?-1858, Notizie del mondo--1860-71, 1912- Annuario pontificio (1872-1911, Gerarchia cattolica)', '547 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'prefix' );
    is( $result_pr[1], 'Title varies: ', '547 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], '1716?-1858, Notizie del mondo--1860-71, 1912- Annuario pontificio (1872-1911, Gerarchia cattolica)', '547 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '547 ex1: combined string identical' );
}

# --- 547 ex 2: $i display text (doc §4.32 ex 2) ---
# Doc: Current: 547 ## $a Edition varies: 1916, New York edition.
{
    # render: [doc §4.32] 547 8# $i Edition varies $a 1916, New York edition
    my $field = make_field( '547', '8', '#', i => 'Edition varies', a => '1916, New York edition' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'postfix' );
    is( $result[1], 'Edition varies: ', '547 ex2 postfix: $i gets ": "' );
    is( $result[3], '1916, New York edition', '547 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'prefix' );
    is( $result_pr[1], 'Edition varies: ', '547 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], '1916, New York edition', '547 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '547 ex2: combined string identical' );
}

# --- 547 edge: $a alone ---
{
    # render: 547 ## $a Title changed with issue 5.
    my $field = make_field( '547', ' ', ' ', a => 'Title changed with issue 5.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'postfix' );
    is( $result[1], 'Title changed with issue 5.', '547 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'547'}, 'prefix' );
    is( $result_pr[1], 'Title changed with issue 5.', '547 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '547 edge: combined string identical' );
}

# =====================================================================
# 550 – Issuing Body Note (spec §4.33)
# $i ': ' (cb_pre). $a N/A.
# =====================================================================

# --- 550 ex 1: $i display text (doc §4.33 ex 1) ---
# Doc: Current: 550 ## $a Issued with: Bureau de recherches géologiques et
#   minières, 1972-
{
    # render: [doc §4.33] 550 8# $i Issued with $a Bureau de recherches géologiques et minières, 1972-
    my $field = make_field( '550', '8', '#', i => 'Issued with', a => 'Bureau de recherches géologiques et minières, 1972-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'postfix' );
    is( $result[1], 'Issued with: ', '550 ex1 postfix: $i gets ": "' );
    is( $result[3], 'Bureau de recherches géologiques et minières, 1972-', '550 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'prefix' );
    is( $result_pr[1], 'Issued with: ', '550 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'Bureau de recherches géologiques et minières, 1972-', '550 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '550 ex1: combined string identical' );
}

# --- 550 ex 2: $i display text (doc §4.33 ex 2) ---
# Doc: Current: 550 ## $a Issued by: Anthropos-Institut, 1935-
{
    # render: [doc §4.33] 550 8# $i Issued by $a Anthropos-Institut, 1935-
    my $field = make_field( '550', '8', '#', i => 'Issued by', a => 'Anthropos-Institut, 1935-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'postfix' );
    is( $result[1], 'Issued by: ', '550 ex2 postfix: $i gets ": "' );
    is( $result[3], 'Anthropos-Institut, 1935-', '550 ex2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'prefix' );
    is( $result_pr[1], 'Issued by: ', '550 ex2 prefix: $i gets ": "' );
    is( $result_pr[3], 'Anthropos-Institut, 1935-', '550 ex2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '550 ex2: combined string identical' );
}

# --- 550 ex 3: $i display text (doc §4.33 ex 3) ---
# Doc: Current: 550 ## $a Vols. for 1972- issued with: Bureau de recherches
#   géologiques et minières.
{
    # render: [doc §4.33] 550 ## $i Vols. for 1972- issued with $a Bureau de recherches géologiques et minières
    my $field = make_field( '550', ' ', ' ', i => 'Vols. for 1972- issued with', a => 'Bureau de recherches géologiques et minières' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'postfix' );
    is( $result[1], 'Vols. for 1972- issued with: ', '550 ex3 postfix: $i gets ": "' );
    is( $result[3], 'Bureau de recherches géologiques et minières', '550 ex3 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'prefix' );
    is( $result_pr[1], 'Vols. for 1972- issued with: ', '550 ex3 prefix: $i gets ": "' );
    is( $result_pr[3], 'Bureau de recherches géologiques et minières', '550 ex3 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '550 ex3: combined string identical' );
}

# --- 550 edge: $a alone ---
{
    # render: 550 ## $a Issued by the Institute.
    my $field = make_field( '550', ' ', ' ', a => 'Issued by the Institute.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'postfix' );
    is( $result[1], 'Issued by the Institute.', '550 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'550'}, 'prefix' );
    is( $result_pr[1], 'Issued by the Institute.', '550 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '550 edge: combined string identical' );
}

# =====================================================================
# 580 – Linking Entry Complexity Note (spec §4.34)
# repeatable $i ': ' (cb_pre); $a repeatable but N/A (no punct between runs).
# KNOWN GAP (comma before a later $i): the §4.34 example's ", to form:" comma
# (e.g. "... (1977), to form: ...") is NOT reproduced by any rule — the comma
# belongs to neither the $a value nor the $i. Following K10plus we omit it;
# the rendered form is "... (1977) to form: ...". Status unclear; may need
# ISBD-expert review.
# =====================================================================

# --- 580 ex 1: single $i + single $a (doc §4.34 ex 1) ---
# Doc: Current: 580 ## $a Cumulates: Deutsche Bibliographie. Wöchentliches
#   Verzeichnis.
{
    # render: [doc §4.34] 580 8# $i Cumulates $a Deutsche Bibliographie. Wöchentliches Verzeichnis
    my $field = make_field( '580', '8', '#', i => 'Cumulates', a => 'Deutsche Bibliographie. Wöchentliches Verzeichnis' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Cumulates: ', '580 ex1 postfix: $i gets ": "' );
    is( $result[3], 'Deutsche Bibliographie. Wöchentliches Verzeichnis', '580 ex1 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Cumulates: ', '580 ex1 prefix: $i gets ": "' );
    is( $result_pr[3], 'Deutsche Bibliographie. Wöchentliches Verzeichnis', '580 ex1 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '580 ex1: combined string identical' );
}

# --- 580 ex 2: repeatable $i + repeatable $a (doc §4.34 ex 2) ---
# Doc: Current: 580 ## $a Merged with: Index chemicus (Philadelphia, Pa. :
#   1977), to form: Current abstracts of chemistry and index chemicus
#   (Philadelphia, Pa. : 1978).
# Note: the comma before "$i to form" ('(1977), to form') is NOT reproduced
# (see KNOWN GAP above) — both $i get ': '.
{
    # render: [doc §4.34] 580 8# $i Merged with $a Index chemicus (Philadelphia, Pa. : 1977) $i to form $a Current abstracts of chemistry and index chemicus (Philadelphia, Pa. : 1978)
    my $field = make_field(
        '580', '8', '#',
        i => 'Merged with',
        a => 'Index chemicus (Philadelphia, Pa. : 1977)',
        i => 'to form',
        a => 'Current abstracts of chemistry and index chemicus (Philadelphia, Pa. : 1978)',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Merged with: ', '580 ex2 postfix: $i1 gets ": "' );
    is( $result[3], 'Index chemicus (Philadelphia, Pa. : 1977)', '580 ex2 postfix: $a1 unchanged' );
    is( $result[5], 'to form: ', '580 ex2 postfix: $i2 gets ": "' );
    is( $result[7], 'Current abstracts of chemistry and index chemicus (Philadelphia, Pa. : 1978)', '580 ex2 postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Merged with: ', '580 ex2 prefix: $i1 gets ": "' );
    is( $result_pr[3], 'Index chemicus (Philadelphia, Pa. : 1977)', '580 ex2 prefix: $a1 unchanged' );
    is( $result_pr[5], 'to form: ', '580 ex2 prefix: $i2 gets ": "' );
    is( $result_pr[7], 'Current abstracts of chemistry and index chemicus (Philadelphia, Pa. : 1978)', '580 ex2 prefix: $a2 unchanged' );

    check_combined( \@result, \@result_pr, '580 ex2: combined string identical' );
}

# --- 580 ex 3: repeatable $i + repeatable $a (doc §4.34 ex 3) ---
# Doc: Current: 580 ## $a Continued by: Ionospheric predictions issued by the
#   laboratory under its later name: Institute for Telecommunication Sciences
#   and Aeronomy.
{
    # render: [doc §4.34] 580 8# $i Continued by $a Ionospheric predictions $i issued by the laboratory under its later name $a Institute for Telecommunication Sciences and Aeronomy
    my $field = make_field(
        '580', '8', '#',
        i => 'Continued by',
        a => 'Ionospheric predictions',
        i => 'issued by the laboratory under its later name',
        a => 'Institute for Telecommunication Sciences and Aeronomy',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Continued by: ', '580 ex3 postfix: $i1 gets ": "' );
    is( $result[3], 'Ionospheric predictions', '580 ex3 postfix: $a1 unchanged' );
    is( $result[5], 'issued by the laboratory under its later name: ', '580 ex3 postfix: $i2 gets ": "' );
    is( $result[7], 'Institute for Telecommunication Sciences and Aeronomy', '580 ex3 postfix: $a2 unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Continued by: ', '580 ex3 prefix: $i1 gets ": "' );
    is( $result_pr[3], 'Ionospheric predictions', '580 ex3 prefix: $a1 unchanged' );
    is( $result_pr[5], 'issued by the laboratory under its later name: ', '580 ex3 prefix: $i2 gets ": "' );
    is( $result_pr[7], 'Institute for Telecommunication Sciences and Aeronomy', '580 ex3 prefix: $a2 unchanged' );

    check_combined( \@result, \@result_pr, '580 ex3: combined string identical' );
}

# --- 580 LoC-derived: real relationship phrasing "Continued in 1982 by" ---
# LoC record (current): 580 ## $a Continued in 1982 by: U.S. exports. Schedule
#   E commodity groupings by world area and country.
#   -> split into $i (relationship, has colon) + $a (content).
{
    # render: [LoC - derived] 580 ## $i Continued in 1982 by $a U.S. exports. Schedule E commodity groupings by world area and country.
    my $field = make_field( '580', ' ', ' ', i => 'Continued in 1982 by', a => 'U.S. exports. Schedule E commodity groupings by world area and country.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Continued in 1982 by: ', '580 LoC postfix: $i gets ": "' );
    is( $result[3], 'U.S. exports. Schedule E commodity groupings by world area and country.', '580 LoC postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Continued in 1982 by: ', '580 LoC prefix: $i gets ": "' );
    is( $result_pr[3], 'U.S. exports. Schedule E commodity groupings by world area and country.', '580 LoC prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '580 LoC: combined string identical' );
}

# --- 580 LoC-derived: "Forms part of" (library-created collection) ---
# LoC record (current): 580 ## $a Forms part of: British Cartoon Prints
#   Collection (Library of Congress).
#   -> split into $i (relationship, has colon) + $a (content).
# Note: the sibling stubs WITHOUT a colon after the relationship phrase (e.g.
# "Forms part of the Frances Benjamin Johnston Collection.") are NOT $i-split
# (a faithful split would fabricate a colon the Current lacks) — they stay a
# single $a and are not tested here.
{
    # render: [LoC - derived] 580 ## $i Forms part of $a British Cartoon Prints Collection (Library of Congress).
    my $field = make_field( '580', ' ', ' ', i => 'Forms part of', a => 'British Cartoon Prints Collection (Library of Congress).' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Forms part of: ', '580 LoC2 postfix: $i gets ": "' );
    is( $result[3], 'British Cartoon Prints Collection (Library of Congress).', '580 LoC2 postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Forms part of: ', '580 LoC2 prefix: $i gets ": "' );
    is( $result_pr[3], 'British Cartoon Prints Collection (Library of Congress).', '580 LoC2 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '580 LoC2: combined string identical' );
}

# --- 580 edge: single $a alone (no $i) ---
{
    # render: 580 ## $a Continues: Titel X.
    my $field = make_field( '580', ' ', ' ', a => 'Continues: Titel X.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'postfix' );
    is( $result[1], 'Continues: Titel X.', '580 edge postfix: $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'580'}, 'prefix' );
    is( $result_pr[1], 'Continues: Titel X.', '580 edge prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '580 edge: combined string identical' );
}

done_testing();
