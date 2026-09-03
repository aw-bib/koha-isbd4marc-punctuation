# isbdmarc2016.pdf §5.6 (Subjects: 648, 650, 651) and §5.7 (Index Terms:
# 655, 656, 657, 658).
#
# PROVENANCE:
#   [doc §5.6]  -> drawn verbatim from the reference doc §5.6 examples
#   [doc §5.7]  -> drawn verbatim from the reference doc §5.7 examples
#   [LoC - derived] -> split from a real pre-punctuated Library-of-Congress
#       record (MARC21 online docs) into the reference-doc subfields; the
#       combined string matches the LoC record MODULO the known
#       subfield-concatenation spacing gap (see below). NOT doc examples.
#   (no token) -> constructed
#
# SUBJECT-PUNCTURATION CHEAT-SHEET (§5.6/§5.7):
#   650: $a N/A, $b '. ' (topical after geographic), $c/$d/$e/$h/$j ', ',
#        $g qualifier group '(...)' / ' : ' for multiple; $v/$x/$y/$z N/A
#   651: $a N/A, $e ', ', $g qualifier group; $v/$x/$y/$z N/A
#   655/656/657: $a N/A, $g qualifier group, $h ', '; $v/$x/$y/$z N/A
#   648/658: all-N/A -> explicit empty rule block (no-op)
#
# KNOWN GAP (2026-09-03, awaiting ISBD-expert ruling): a $g qualifier wraps
# as '(val)' with NO leading space, and N/A subdivisions ($v/$x/$y/$z) are
# concatenated with no space. The reference doc / LoC print 'Val (val)' and
# 'Val $z sub' WITH a space. This is the same subfield-concatenation spacing
# issue already seen in 020 ('9780060723804(acid-free paper)'). Not fixed here;
# the tests assert our deterministic spec output and note the divergence.

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

# --- 650 exists; 648/658 are explicit empty (no-op) rule blocks ---
ok( defined $R->{'650'},    '650 rules defined' );
ok( defined $R->{'651'},    '651 rules defined' );
ok( defined $R->{'655'},    '655 rules defined' );
ok( defined $R->{'656'},    '656 rules defined (use_rules => 655)' );
ok( defined $R->{'657'},    '657 rules defined (use_rules => 655)' );
ok( defined $R->{'648'},    '648 rules defined (explicit empty)' );
ok( defined $R->{'658'},    '658 rules defined (explicit empty)' );
is_deeply( $R->{'648'}, {}, '648 is an explicit empty rule block (N/A)' );
is_deeply( $R->{'658'}, {}, '658 is an explicit empty rule block (N/A)' );
is( $R->{'656'}{use_rules}, '655', '656 aliases 655' );
is( $R->{'657'}{use_rules}, '655', '657 aliases 655' );

# =====================================================================
# 650 – Topical Subject (spec §5.6)
# =====================================================================

# --- 650 ex 1: $g qualifier group (doc §5.6 ex 4: Equilibrium) ---
# Doc: Current: 650 #0 $a Equilibrium (Economics)
# Note: our output 'Equilibrium(Economics)' differs from the doc's
# 'Equilibrium (Economics)' only by the known qualifier leading-space gap.
{
    # render: [doc §5.6] 650 ## $a Equilibrium $g Economics
    my $field = make_field( '650', ' ', ' ', a => 'Equilibrium', g => 'Economics' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Equilibrium', '650 ex1 postfix: $a unchanged' );
    is( $result[3], '(Economics)', '650 ex1 postfix: $g wrapped in parens' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Equilibrium', '650 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '(Economics)', '650 ex1 prefix: $g wrapped in parens' );

    check_combined( \@result, \@result_pr, '650 ex1: combined string identical' );
}

# --- 650 ex 2: multiple $g -> (a : b) (doc-derived, repeatable qualifier) ---
{
    # render: [doc §5.6 - derived] 650 ## $a Foo $g Bar $g Baz
    my $field = make_field( '650', ' ', ' ', a => 'Foo', g => 'Bar', g => 'Baz' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Foo',   '650 ex2 postfix: $a unchanged' );
    is( $result[3], '(Bar',  '650 ex2 postfix: first $g opens paren' );
    is( $result[5], ' : Baz)', '650 ex2 postfix: second $g " : " + close paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Foo',       '650 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '(Bar',      '650 ex2 prefix: first $g opens paren' );
    is( $result_pr[5], ' : Baz)',   '650 ex2 prefix: second $g " : " + close paren' );

    check_combined( \@result, \@result_pr, '650 ex2: combined string identical' );
}

# --- 650 ex 3: inverted text $h + remaining text $j (doc §5.6 ex 1) ---
# Doc: Current: 650 #0 $a Animals, Mythical, in art.
{
    # render: [doc §5.6] 650 ## $a Animals $h Mythical $j in art
    my $field = make_field( '650', ' ', ' ', a => 'Animals', h => 'Mythical', j => 'in art' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Animals, ', '650 ex3 postfix: $a gets ", " before $h' );
    is( $result[3], 'Mythical, ', '650 ex3 postfix: $h gets ", " before $j' );
    is( $result[5], 'in art',    '650 ex3 postfix: $j final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Animals',    '650 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ', Mythical', '650 ex3 prefix: $h gets ", " prepended' );
    is( $result_pr[5], ', in art',   '650 ex3 prefix: $j gets ", " prepended' );

    check_combined( \@result, \@result_pr, '650 ex3: combined string identical' );
}

# --- 650 ex 4: $h + $c + $d (doc §5.6 ex 5: Fredericksburg) ---
# Doc: Current: 650 #0 $a Fredericksburg, Battle of, Fredericksburg, Va., 1862.
{
    # render: [doc §5.6] 650 ## $a Fredericksburg $h Battle of $c Fredericksburg, Va. $d 1862
    my $field = make_field(
        '650', ' ', ' ',
        a => 'Fredericksburg',
        h => 'Battle of',
        c => 'Fredericksburg, Va.',
        d => '1862',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Fredericksburg, ',        '650 ex4 postfix: $a ", " before $h' );
    is( $result[3], 'Battle of, ',             '650 ex4 postfix: $h ", " before $c' );
    is( $result[5], 'Fredericksburg, Va., ',   '650 ex4 postfix: $c ", " before $d' );
    is( $result[7], '1862',                    '650 ex4 postfix: $d final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Fredericksburg',          '650 ex4 prefix: $a unchanged' );
    is( $result_pr[3], ', Battle of',             '650 ex4 prefix: $h ", " prepended' );
    is( $result_pr[5], ', Fredericksburg, Va.',   '650 ex4 prefix: $c ", " prepended' );
    is( $result_pr[7], ', 1862',                  '650 ex4 prefix: $d ", " prepended' );

    check_combined( \@result, \@result_pr, '650 ex4: combined string identical' );
}

# --- 650 ex 5: $d then N/A $x then $h (doc §5.6 ex 7: Korean War) ---
# Doc: Current: 650 #0 $a Korean War, 1950-1953 $x Participation, American.
# NOTE: our combined 'Korean War, 1950-1953Participation, American' has NO
# space between $d and $x (N/A subdivision) — the known spacing gap.
{
    # render: [doc §5.6] 650 ## $a Korean War $d 1950-1953 $x Participation $h American
    my $field = make_field(
        '650', ' ', ' ',
        a => 'Korean War',
        d => '1950-1953',
        x => 'Participation',
        h => 'American',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Korean War, ',    '650 ex5 postfix: $a ", " before $d' );
    is( $result[3], '1950-1953',       '650 ex5 postfix: $d unchanged (no punct before N/A $x)' );
    is( $result[5], 'Participation, ', '650 ex5 postfix: $x gets ", " before $h' );
    is( $result[7], 'American',        '650 ex5 postfix: $h final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Korean War',      '650 ex5 prefix: $a unchanged' );
    is( $result_pr[3], ', 1950-1953',     '650 ex5 prefix: $d ", " prepended' );
    is( $result_pr[5], 'Participation',   '650 ex5 prefix: $x unchanged (N/A)' );
    is( $result_pr[7], ', American',      '650 ex5 prefix: $h ", " prepended' );

    check_combined( \@result, \@result_pr, '650 ex5: combined string identical' );
}

# --- 650 ex 6: $a keeps internal punctuation, $h gets ", " (doc §5.6 ex 2) ---
# Doc: Current: 650 #0 $a Associations, institutions, etc., Foreign.
{
    # render: [doc §5.6] 650 ## $a Associations, institutions, etc. $h Foreign
    my $field = make_field( '650', ' ', ' ', a => 'Associations, institutions, etc.', h => 'Foreign' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Associations, institutions, etc., ', '650 ex6 postfix: $a gets ", " before $h' );
    is( $result[3], 'Foreign',                            '650 ex6 postfix: $h final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Associations, institutions, etc.', '650 ex6 prefix: $a unchanged' );
    is( $result_pr[3], ', Foreign',                        '650 ex6 prefix: $h ", " prepended' );

    check_combined( \@result, \@result_pr, '650 ex6: combined string identical' );
}

# --- 650 ex 7: LoC-derived — qualifier baked in $a, split to $g ---
# LoC: 650 #0 $a BASIC (Computer program language).  ->  $a BASIC $g Computer program language
# NOTE: combined 'BASIC(Computer program language)' lacks the space before
# '( ' — the known qualifier leading-space gap.
{
    # render: [LoC - derived] 650 ## $a BASIC $g Computer program language
    my $field = make_field( '650', ' ', ' ', a => 'BASIC', g => 'Computer program language' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'BASIC',                  '650 ex7 postfix: $a unchanged' );
    is( $result[3], '(Computer program language)', '650 ex7 postfix: $g wrapped in parens' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'BASIC',              '650 ex7 prefix: $a unchanged' );
    is( $result_pr[3], '(Computer program language)', '650 ex7 prefix: $g wrapped in parens' );

    check_combined( \@result, \@result_pr, '650 ex7: combined string identical' );
}

# --- 650 ex 8: LoC-derived — Concertos (String orchestra) -> $g ---
{
    # render: [LoC - derived] 650 ## $a Concertos $g String orchestra
    my $field = make_field( '650', ' ', ' ', a => 'Concertos', g => 'String orchestra' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Concertos',         '650 ex8 postfix: $a unchanged' );
    is( $result[3], '(String orchestra)', '650 ex8 postfix: $g wrapped in parens' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Concertos',         '650 ex8 prefix: $a unchanged' );
    is( $result_pr[3], '(String orchestra)', '650 ex8 prefix: $g wrapped in parens' );

    check_combined( \@result, \@result_pr, '650 ex8: combined string identical' );
}

# --- 650 ex 9: LoC-derived — subdivision $v is N/A (pass-through) ---
# LoC: 650 #0 $a Flour industry $v Periodicals.
# NOTE: combined 'Flour industryPeriodicals' (no space) — N/A spacing gap.
{
    # render: [LoC - derived] 650 ## $a Flour industry $v Periodicals
    my $field = make_field( '650', ' ', ' ', a => 'Flour industry', v => 'Periodicals' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Flour industry', '650 ex9 postfix: $a unchanged' );
    is( $result[3], 'Periodicals',    '650 ex9 postfix: $v (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Flour industry', '650 ex9 prefix: $a unchanged' );
    is( $result_pr[3], 'Periodicals',    '650 ex9 prefix: $v (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '650 ex9: combined string identical' );
}

# --- 650 ex 10: LoC-derived — $z/$y subdivisions N/A (pass-through) ---
# LoC: 650 #0 $a Vocal music $z France $y 18th century.
# NOTE: combined 'Vocal musicFrance18th century' (no spaces) — N/A spacing gap.
{
    # render: [LoC - derived] 650 ## $a Vocal music $z France $y 18th century
    my $field = make_field( '650', ' ', ' ', a => 'Vocal music', z => 'France', y => '18th century' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'Vocal music', '650 ex10 postfix: $a unchanged' );
    is( $result[3], 'France',      '650 ex10 postfix: $z (N/A) unchanged' );
    is( $result[5], '18th century', '650 ex10 postfix: $y (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'Vocal music',  '650 ex10 prefix: $a unchanged' );
    is( $result_pr[3], 'France',       '650 ex10 prefix: $z (N/A) unchanged' );
    is( $result_pr[5], '18th century', '650 ex10 prefix: $y (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '650 ex10: combined string identical' );
}

# --- 650 ex 11: $b (topical term after geographic) -> '. ' (650 only) ---
{
    # render: 650 ## $a United States $b Periodicals
    my $field = make_field( '650', ' ', ' ', a => 'United States', b => 'Periodicals' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'postfix' );
    is( $result[1], 'United States. ', '650 ex11 postfix: $a gets ". " before $b' );
    is( $result[3], 'Periodicals',     '650 ex11 postfix: $b final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'650'}, 'prefix' );
    is( $result_pr[1], 'United States',  '650 ex11 prefix: $a unchanged' );
    is( $result_pr[3], '. Periodicals',  '650 ex11 prefix: $b gets ". " prepended' );

    check_combined( \@result, \@result_pr, '650 ex11: combined string identical' );
}

# =====================================================================
# 651 – Geographic Subject (spec §5.6)
# =====================================================================

# --- 651 ex 1: $e (relator) -> ', ' ---
{
    # render: 651 ## $a Germany $e creator
    my $field = make_field( '651', ' ', ' ', a => 'Germany', e => 'creator' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'651'}, 'postfix' );
    is( $result[1], 'Germany, ', '651 ex1 postfix: $a ", " before $e' );
    is( $result[3], 'creator',   '651 ex1 postfix: $e final unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'651'}, 'prefix' );
    is( $result_pr[1], 'Germany',   '651 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ', creator', '651 ex1 prefix: $e ", " prepended' );

    check_combined( \@result, \@result_pr, '651 ex1: combined string identical' );
}

# --- 651 ex 2: $g qualifier group (qualifier baked in $a in LoC) ---
{
    # render: [LoC - derived] 651 ## $a Montreal $g Quebec
    my $field = make_field( '651', ' ', ' ', a => 'Montreal', g => 'Quebec' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'651'}, 'postfix' );
    is( $result[1], 'Montreal',  '651 ex2 postfix: $a unchanged' );
    is( $result[3], '(Quebec)',  '651 ex2 postfix: $g wrapped in parens' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'651'}, 'prefix' );
    is( $result_pr[1], 'Montreal',  '651 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '(Quebec)',  '651 ex2 prefix: $g wrapped in parens' );

    check_combined( \@result, \@result_pr, '651 ex2: combined string identical' );
}

# =====================================================================
# 655 – Index Term – Genre/Form (spec §5.7)
# =====================================================================

# --- 655 ex 1: $g qualifier (doc §5.7 ex 1: Fantasy comedies) ---
# Doc: Current: 655 #7 $a Fantasy comedies (Motion pictures) $2 lcgft
# NOTE: our 'Fantasy comedies(Motion pictures)' lacks the space before '('.
{
    # render: [doc §5.7] 655 ## $a Fantasy comedies $g Motion pictures $2 lcgft
    my $field = make_field( '655', ' ', ' ', a => 'Fantasy comedies', g => 'Motion pictures', '2' => 'lcgft' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'postfix' );
    is( $result[1], 'Fantasy comedies',       '655 ex1 postfix: $a unchanged' );
    is( $result[3], '(Motion pictures)',      '655 ex1 postfix: $g wrapped in parens' );
    is( $result[5], 'lcgft',                  '655 ex1 postfix: $2 (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'prefix' );
    is( $result_pr[1], 'Fantasy comedies',    '655 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '(Motion pictures)',   '655 ex1 prefix: $g wrapped in parens' );
    is( $result_pr[5], 'lcgft',               '655 ex1 prefix: $2 (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '655 ex1: combined string identical' );
}

# --- 655 ex 2: $h inverted text (doc §5.7 ex: Poems) ---
# Doc: Current: 655 #7 $a Poems, English $y 19th century. $2 rbgenr
{
    # render: [doc §5.7] 655 ## $a Poems $h English $y 19th century $2 rbgenr
    my $field = make_field( '655', ' ', ' ', a => 'Poems', h => 'English', y => '19th century', '2' => 'rbgenr' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'postfix' );
    is( $result[1], 'Poems, ',       '655 ex2 postfix: $a ", " before $h' );
    is( $result[3], 'English',       '655 ex2 postfix: $h final unchanged' );
    is( $result[5], '19th century',  '655 ex2 postfix: $y (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'prefix' );
    is( $result_pr[1], 'Poems',        '655 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ', English',    '655 ex2 prefix: $h ", " prepended' );
    is( $result_pr[5], '19th century', '655 ex2 prefix: $y (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '655 ex2: combined string identical' );
}

# --- 655 ex 3: $g + N/A subdivisions (doc §5.7 ex: Signing patterns) ---
# Doc: Current: 655 #7 $a Signing patterns (Printing) $z Germany $y 18th century. $2 rbpri
{
    # render: [doc §5.7] 655 ## $a Signing patterns $g Printing $z Germany $y 18th century $2 rbpri
    my $field = make_field( '655', ' ', ' ',
        a => 'Signing patterns', g => 'Printing', z => 'Germany', y => '18th century', '2' => 'rbpri' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'postfix' );
    is( $result[1], 'Signing patterns', '655 ex3 postfix: $a unchanged' );
    is( $result[3], '(Printing)',       '655 ex3 postfix: $g wrapped in parens' );
    is( $result[5], 'Germany',          '655 ex3 postfix: $z (N/A) unchanged' );
    is( $result[7], '18th century',     '655 ex3 postfix: $y (N/A) unchanged' );
    is( $result[9], 'rbpri',            '655 ex3 postfix: $2 (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'655'}, 'prefix' );
    is( $result_pr[1], 'Signing patterns', '655 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '(Printing)',       '655 ex3 prefix: $g wrapped in parens' );
    is( $result_pr[5], 'Germany',          '655 ex3 prefix: $z (N/A) unchanged' );
    is( $result_pr[7], '18th century',     '655 ex3 prefix: $y (N/A) unchanged' );
    is( $result_pr[9], 'rbpri',            '655 ex3 prefix: $2 (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '655 ex3: combined string identical' );
}

# =====================================================================
# 656 / 657 – Index Term Occupation / Function (spec §5.7, alias to 655)
# =====================================================================

# --- 656 ex 1: LoC-derived — $k (Form) is N/A; $a alone ---
# LoC: 656 #7 $a Migrant laborers. $k School district case files.
{
    # render: [LoC - derived] 656 ## $a Migrant laborers $k School district case files
    my $field = make_field( '656', ' ', ' ', a => 'Migrant laborers', k => 'School district case files' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'656'}, 'postfix' );
    is( $result[1], 'Migrant laborers',         '656 ex1 postfix: $a unchanged' );
    is( $result[3], 'School district case files', '656 ex1 postfix: $k (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'656'}, 'prefix' );
    is( $result_pr[1], 'Migrant laborers',          '656 ex1 prefix: $a unchanged' );
    is( $result_pr[3], 'School district case files', '656 ex1 prefix: $k (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '656 ex1: combined string identical' );
}

# --- 656 ex 2: doc §5.7 ex (Plastic surgeons) — $g after N/A $z ---
# Doc: Current: 656 #7 $a Plastic surgeons $z Los Angeles (Calif.) $2 <thesaurus code>
{
    # render: [doc §5.7] 656 ## $a Plastic surgeons $z Los Angeles $g Calif.
    my $field = make_field( '656', ' ', ' ', a => 'Plastic surgeons', z => 'Los Angeles', g => 'Calif.' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'656'}, 'postfix' );
    is( $result[1], 'Plastic surgeons', '656 ex2 postfix: $a unchanged' );
    is( $result[3], 'Los Angeles',      '656 ex2 postfix: $z (N/A) unchanged' );
    is( $result[5], '(Calif.)',         '656 ex2 postfix: $g wrapped in parens' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'656'}, 'prefix' );
    is( $result_pr[1], 'Plastic surgeons', '656 ex2 prefix: $a unchanged' );
    is( $result_pr[3], 'Los Angeles',      '656 ex2 prefix: $z (N/A) unchanged' );
    is( $result_pr[5], '(Calif.)',         '656 ex2 prefix: $g wrapped in parens' );

    check_combined( \@result, \@result_pr, '656 ex2: combined string identical' );
}

# --- 657 ex 1: LoC-derived — only N/A subdivisions ---
# LoC: 657 #7 $a Personnel benefits management $x Industrial accidents $x Morbidity $x Vital statistics $z Love Canal, New York. $2 ...
{
    # render: [LoC - derived] 657 ## $a Personnel benefits management $x Industrial accidents $x Vital statistics $z Love Canal, New York.
    my $field = make_field( '657', ' ', ' ',
        a => 'Personnel benefits management',
        x => 'Industrial accidents',
        x => 'Vital statistics',
        z => 'Love Canal, New York.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'657'}, 'postfix' );
    is( $result[1], 'Personnel benefits management', '657 ex1 postfix: $a unchanged' );
    is( $result[3], 'Industrial accidents',          '657 ex1 postfix: $x (N/A) unchanged' );
    is( $result[5], 'Vital statistics',              '657 ex1 postfix: $x (N/A) unchanged' );
    is( $result[7], 'Love Canal, New York.',         '657 ex1 postfix: $z (N/A) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'657'}, 'prefix' );
    is( $result_pr[1], 'Personnel benefits management', '657 ex1 prefix: $a unchanged' );
    is( $result_pr[3], 'Industrial accidents',          '657 ex1 prefix: $x (N/A) unchanged' );
    is( $result_pr[5], 'Vital statistics',              '657 ex1 prefix: $x (N/A) unchanged' );
    is( $result_pr[7], 'Love Canal, New York.',         '657 ex1 prefix: $z (N/A) unchanged' );

    check_combined( \@result, \@result_pr, '657 ex1: combined string identical' );
}

# =====================================================================
# 648 / 658 – Chronological Term / Curriculum Objective: explicit EMPTY rules
# =====================================================================

# --- 648: $a only, N/A -> pass-through unchanged ---
{
    # render: 648 ## $a 1980-1990
    my $field = make_field( '648', ' ', ' ', a => '1980-1990' );
    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'648'}, 'postfix' );
    is( $result[1], '1980-1990', '648: $a passes through unchanged (N/A field)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'648'}, 'prefix' );
    is( $result_pr[1], '1980-1990', '648 prefix: $a passes through unchanged' );

    check_combined( \@result, \@result_pr, '648: combined string identical' );
}

# --- 658: all-N/A subfields pass through (LoC-derived values) ---
# LoC: 658 ## $a Reading objective 1 (fictional) $b understanding... $c NRPO2-1991 $d highly correlated. $2 ohco
{
    # render: [LoC - derived] 658 ## $a Reading objective 1 (fictional) $b understanding language $c NRPO2-1991 $d highly correlated.
    my $field = make_field( '658', ' ', ' ',
        a => 'Reading objective 1 (fictional)',
        b => 'understanding language',
        c => 'NRPO2-1991',
        d => 'highly correlated.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'658'}, 'postfix' );
    is( $result[1], 'Reading objective 1 (fictional)', '658 postfix: $a unchanged (N/A)' );
    is( $result[3], 'understanding language',          '658 postfix: $b unchanged (N/A)' );
    is( $result[5], 'NRPO2-1991',                      '658 postfix: $c unchanged (N/A)' );
    is( $result[7], 'highly correlated.',              '658 postfix: $d unchanged (N/A)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'658'}, 'prefix' );
    is( $result_pr[1], 'Reading objective 1 (fictional)', '658 prefix: $a unchanged (N/A)' );
    is( $result_pr[3], 'understanding language',          '658 prefix: $b unchanged (N/A)' );
    is( $result_pr[5], 'NRPO2-1991',                      '658 prefix: $c unchanged (N/A)' );
    is( $result_pr[7], 'highly correlated.',              '658 prefix: $d unchanged (N/A)' );

    check_combined( \@result, \@result_pr, '658: combined string identical' );
}

done_testing();
