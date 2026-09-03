#
# Tests for Field 300 - Physical Description
# Derived from isbdmarc2016.pdf Current/Future examples.
#
# Simple approach: pchrs for $b ( : ), $c ( ; ), $e ( + ), $a ( + for second+),
# and $h wrapped in parentheses.
# Known gaps: $h/$i/$j accompanying material grouping, $i/$j punctuation.

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

my $rules_300 = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{300};
ok( defined $rules_300, '300 rules loaded' );

# --- Example 1: $a + $c (simple book) ---
# Doc: Future:  300 ## $a 149 pages $c 23 cm
# Doc: Current: 300 ## $a 149 pages ; $c 23 cm.
{
    # render: 300 ## $a 149 pages $c 23 cm
    my $field = make_field(
        '300', '#', '#',
        a => '149 pages',
        c => '23 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '149 pages ; ',
        '300 ex1 postfix: $a gets " ; " when $c follows' );
    is( $result[3], '23 cm', '300 ex1 postfix: $c (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '149 pages', '300 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' ; 23 cm',  '300 ex1 prefix: $c gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '300 ex1: combined string identical' );
}

# --- Example 2: $a + $c (score) ---
# Doc: Future:  300 ## $a 1 score (16 pages) $c 29 cm
# Doc: Current: 300 ## $a 1 score (16 pages) ; $c 29 cm.
{
    # render: 300 ## $a 1 score (16 pages) $c 29 cm
    my $field = make_field(
        '300', '#', '#',
        a => '1 score (16 pages)',
        c => '29 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is(
        $result[1],
        '1 score (16 pages) ; ',
        '300 ex2 postfix: $a gets " ; " when $c follows'
    );
    is( $result[3], '29 cm', '300 ex2 postfix: $c (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '1 score (16 pages)', '300 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ' ; 29 cm', '300 ex2 prefix: $c gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '300 ex2: combined string identical' );
}

# --- Example 3: $a + $b + $c (audio disc) ---
# Doc: Future:  300 ## $a 1 audio disc (20 min.) $b analog, 33 1/3 rpm, stereo $c 12 in.
# Doc: Current: 300 ## $a 1 audio disc (20 min.) : $b analog, 33 1/3 rpm, stereo ; $c 12 in.
{
    # render: 300 ## $a 1 audio disc (20 min.) $b analog, 33 1/3 rpm, stereo $c 12 in.
    my $field = make_field(
        '300', '#', '#',
        a => '1 audio disc (20 min.)',
        b => 'analog, 33 1/3 rpm, stereo',
        c => '12 in.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is(
        $result[1],
        '1 audio disc (20 min.) : ',
        '300 ex3 postfix: $a gets " : " when $b follows'
    );
    is(
        $result[3],
        'analog, 33 1/3 rpm, stereo ; ',
        '300 ex3 postfix: $b gets " ; " when $c follows'
    );
    is( $result[5], '12 in.', '300 ex3 postfix: $c (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is(
        $result_pr[1],
        '1 audio disc (20 min.)',
        '300 ex3 prefix: $a unchanged'
    );
    is(
        $result_pr[3],
        ' : analog, 33 1/3 rpm, stereo',
        '300 ex3 prefix: $b gets " : " prepended'
    );
    is( $result_pr[5], ' ; 12 in.', '300 ex3 prefix: $c gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '300 ex3: combined string identical' );
}

# --- Example 4: $a + $c + $a + $c (scores with parts) ---
# Doc: Future:  300 ## $a 1 score (30 pages) $c 20 cm $a 16 parts $c 32 cm
# Doc: Current: 300 ## $a 1 score (30 pages) ; $c 20 cm. + $a 16 parts ; $c 32 cm.
{
    # render: 300 ## $a 1 score (30 pages) $c 20 cm $a 16 parts $c 32 cm
    my $field = make_field(
        '300', '#', '#',
        a => '1 score (30 pages)',
        c => '20 cm',
        a => '16 parts',
        c => '32 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is(
        $result[1],
        '1 score (30 pages) ; ',
        '300 ex4 postfix: first $a gets " ; " when $c follows'
    );
    is( $result[3], '20 cm + ',
        '300 ex4 postfix: $c gets " + " when another $a follows' );
    is( $result[5], '16 parts ; ',
        '300 ex4 postfix: second $a gets " ; " when $c follows' );
    is( $result[7], '32 cm', '300 ex4 postfix: second $c (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is(
        $result_pr[1],
        '1 score (30 pages)',
        '300 ex4 prefix: first $a unchanged'
    );
    is( $result_pr[3], ' ; 20 cm', '300 ex4 prefix: $c gets " ; " prepended' );
    is( $result_pr[5], ' + 16 parts',
        '300 ex4 prefix: second $a gets " + " prepended' );
    is( $result_pr[7], ' ; 32 cm',
        '300 ex4 prefix: second $c gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '300 ex4: combined string identical' );
}

# --- Example 5: $a + $b + $c (print) ---
# Doc: Future:  300 ## $a 1 print $b lithograph, black and white $c image 33 x 41 cm, on sheet 46 x 57 cm
# Doc: Current: 300 ## $a 1 print : $b lithograph, black and white ; $c image 33 x 41 cm., on sheet 46 x 57 cm.
{
    # render: 300 ## $a 1 print $b lithograph, black and white $c image 33 x 41 cm, on sheet 46 x 57 cm
    my $field = make_field(
        '300', '#', '#',
        a => '1 print',
        b => 'lithograph, black and white',
        c => 'image 33 x 41 cm, on sheet 46 x 57 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '1 print : ',
        '300 ex5 postfix: $a gets " : " when $b follows' );
    is(
        $result[3],
        'lithograph, black and white ; ',
        '300 ex5 postfix: $b gets " ; " when $c follows'
    );
    is(
        $result[5],
        'image 33 x 41 cm, on sheet 46 x 57 cm',
        '300 ex5 postfix: $c (last) unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '1 print', '300 ex5 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' : lithograph, black and white',
        '300 ex5 prefix: $b gets " : " prepended'
    );
    is(
        $result_pr[5],
        ' ; image 33 x 41 cm, on sheet 46 x 57 cm',
        '300 ex5 prefix: $c gets " ; " prepended'
    );

    check_combined( \@result, \@result_pr, '300 ex5: combined string identical' );
}

# --- Example 6: $a + $b + $c + $e + $h/$i/$j (accompanying material) ---
# Doc: Future:  300 ## $a 271 pages $b ill. $c 21 cm $e 1 atlas $h 37 pages, 19 leaves $i color maps $j 37 cm
# Doc: Current: 300 ## $a 271 pages : $b ill. ; $c 21 cm + $e 1 atlas (37 pages, 19 leaves : color maps ; 37 cm)
# $h/$i/$j are grouped in ONE paren pair anchored on $h (see
# _decorate_300_pre); separators via compound pchrs hi/ij.
{
    # render: 300 ## $a 271 pages $b ill. $c 21 cm $e 1 atlas $h 37 pages, 19 leaves $i color maps $j 37 cm
    my $field = make_field(
        '300', '#', '#',
        a => '271 pages',
        b => 'ill.',
        c => '21 cm',
        e => '1 atlas',
        h => '37 pages, 19 leaves',
        i => 'color maps',
        j => '37 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '271 pages : ',
        '300 ex6 postfix: $a gets " : " when $b follows' );
    is( $result[3], 'ill. ; ',
        '300 ex6 postfix: $b gets " ; " when $c follows' );
    is( $result[5], '21 cm + ',
        '300 ex6 postfix: $c gets " + " when $e follows' );
    is( $result[7], '1 atlas',
        '300 ex6 postfix: $e (no punct when $h follows)' );
    is(
        $result[9],
        ' (37 pages, 19 leaves : ',
        '300 ex6 postfix: $h opens the group ( + " : " when $i follows)'
    );
    is( $result[11], 'color maps ; ',
        '300 ex6 postfix: $i gets " ; " when $j follows' );
    is( $result[13], '37 cm)',
        '300 ex6 postfix: $j (last) closes the group' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '271 pages', '300 ex6 prefix: $a unchanged' );
    is( $result_pr[3], ' : ill.',   '300 ex6 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' ; 21 cm',  '300 ex6 prefix: $c gets " ; " prepended' );
    is( $result_pr[7], ' + 1 atlas',
        '300 ex6 prefix: $e gets " + " prepended' );
    is(
        $result_pr[9],
        ' (37 pages, 19 leaves',
        '300 ex6 prefix: $h opens the group (no sep yet)'
    );
    is( $result_pr[11], ' : color maps',
        '300 ex6 prefix: $i gets " : " prepended' );
    is( $result_pr[13], ' ; 37 cm)',
        '300 ex6 prefix: $j gets " ; " prepended and closes the group' );

    check_combined( \@result, \@result_pr, '300 ex6: combined string identical' );
}

# --- Edge case: $a alone ---
{
    # render: 300 ## $a 95 linear ft.
    my $field = make_field( '300', '#', '#', a => '95 linear ft.', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '95 linear ft.', '300 edge $a alone postfix: unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '95 linear ft.', '300 edge $a alone prefix: unchanged' );

    check_combined( \@result, \@result_pr, '300 edge $a alone: combined string identical' );
}

# --- Edge case: $a + $b only (no $c) ---
{
    # render: 300 ## $a volumes $b illustrations (some color)
    my $field = make_field(
        '300', '#', '#',
        a => 'volumes',
        b => 'illustrations (some color)',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], 'volumes : ', '300 edge $a+$b postfix: $a gets " : "' );
    is(
        $result[3],
        'illustrations (some color)',
        '300 edge $a+$b postfix: $b (last) unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], 'volumes', '300 edge $a+$b prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' : illustrations (some color)',
        '300 edge $a+$b prefix: $b gets " : " prepended'
    );

    check_combined( \@result, \@result_pr, '300 edge $a+$b: combined string identical' );
}

# --- Edge case: $a + $e (accompanying material only, no $b/$c) ---
{
    # render: 300 ## $a 1 computer disk $e reference manual
    my $field = make_field(
        '300', '#', '#',
        a => '1 computer disk',
        e => 'reference manual',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is(
        $result[1],
        '1 computer disk + ',
        '300 edge $a+$e postfix: $a gets " + " when $e follows'
    );
    is(
        $result[3],
        'reference manual',
        '300 edge $a+$e postfix: $e (last) unchanged'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is(
        $result_pr[1],
        '1 computer disk',
        '300 edge $a+$e prefix: $a unchanged'
    );
    is(
        $result_pr[3],
        ' + reference manual',
        '300 edge $a+$e prefix: $e gets " + " prepended'
    );

    check_combined( \@result, \@result_pr, '300 edge $a+$e: combined string identical' );
}

# --- Edge case: $h alone (data from $3-poems example) ---
{
    # render: 300 ## $h 37 pages
    my $field = make_field( '300', '#', '#', h => '37 pages', );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '(37 pages)', '300 edge $h alone postfix: wrapped in ()' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '(37 pages)',
        '300 edge $h alone prefix: wrapped in ()' );

    check_combined( \@result, \@result_pr, '300 edge $h alone: combined string identical' );
}

# --- Edge case: $a + $h (no $e in between -- rare but possible) ---
# $h is preceded by $a, so the group opener gets a leading space:
# $a 5 boxes + $h -> own paren, preceded content -> " (24 linear ft.)"
{
    # render: 300 ## $a 5 boxes $h 24 linear ft.
    my $field = make_field(
        '300', '#', '#',
        a => '5 boxes',
        h => '24 linear ft.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '5 boxes',
        '300 edge $a+$h postfix: $a unchanged ($h not in pchrs)' );
    is(
        $result[3],
        ' (24 linear ft.)',
        '300 edge $a+$h postfix: $h wrapped in () with leading space'
    );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '5 boxes', '300 edge $a+$h prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' (24 linear ft.)',
        '300 edge $a+$h prefix: $h wrapped in () with leading space'
    );

    check_combined( \@result, \@result_pr, '300 edge $a+$h: combined string identical' );
}

# --- Edge case: $e + $h + $j (extent + dimensions, no $i) ---
# $i absent: the group is $h; $j via the COMPOUND hj key -> " ; "
# render: 300 ## $a 1 atlas $e 1 map $h 20 x 30 cm $j 45 cm
{
    # render: 300 ## $a 1 atlas $e 1 map $h 20 x 30 cm $j 45 cm
    my $field = make_field(
        '300', '#', '#',
        a => '1 atlas',
        e => '1 map',
        h => '20 x 30 cm',
        j => '45 cm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '1 atlas + ',
        '300 edge $e+$h+$j postfix: $a gets " + " when $e follows' );
    is(
        $result[3],
        '1 map',
        '300 edge $e+$h+$j postfix: $e (no punct when $h follows)'
    );
    is(
        $result[5],
        ' (20 x 30 cm ; ',
        '300 edge $e+$h+$j postfix: $h opens group + " ; " when $j follows (hj)'
    );
    is( $result[7], '45 cm)',
        '300 edge $e+$h+$j postfix: $j (last) closes the group' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '1 atlas', '300 edge $e+$h+$j prefix: $a unchanged' );
    is( $result_pr[3], ' + 1 map',
        '300 edge $e+$h+$j prefix: $e gets " + " prepended' );
    is(
        $result_pr[5],
        ' (20 x 30 cm',
        '300 edge $e+$h+$j prefix: $h opens group (no sep yet)'
    );
    is(
        $result_pr[7],
        ' ; 45 cm)',
        '300 edge $e+$h+$j prefix: $j gets " ; " prepended and closes'
    );

    check_combined( \@result, \@result_pr,
        '300 edge $e+$h+$j: combined string identical' );
}

# --- Edge case: lone $i / $j (no preceding $h) is a documented gap ---
# Per agreement (Option A): a run may only open at $h, so a lone $i/$j gets
# NO parentheses (the group callback skips it). However the compound pchrs
# key ij (and hj) still fires on an adjacent $i/$j in the engine's step 4,
# inserting a bare " ; " with no parens. There is no real-world test case
# for this yet (the spec example always has $h) — accepted provisionally.
# A lone $j with NO adjacent $i/$j is genuinely untouched.
{
    # render: 300 ## $a 1 videocassette $i color $j 1/2 in.
    my $field = make_field(
        '300', '#', '#',
        a => '1 videocassette',
        i => 'color',
        j => '1/2 in.',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '1 videocassette',
        '300 edge lone $i postfix: $a unchanged (i/j not in pchrs)' );
    is( $result[3], 'color ; ',
        '300 edge lone $i postfix: lone $i gets no parens; bare " ; " leaks from ij (Option A)' );
    is( $result[5], '1/2 in.',
        '300 edge lone $i postfix: $j (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '1 videocassette',
        '300 edge lone $i prefix: $a unchanged' );
    is( $result_pr[3], 'color',
        '300 edge lone $i prefix: lone $i gets no parens' );
    is( $result_pr[5], ' ; 1/2 in.',
        '300 edge lone $i prefix: lone $j gets bare " ; " prepended (Option A)' );

    check_combined( \@result, \@result_pr,
        '300 edge lone $i: combined string identical' );
}

# --- Edge case: lone $j only (no $h, no $i) is genuinely untouched ---
{
    # render: 300 ## $a 1 filmstrip $j 35 mm
    my $field = make_field(
        '300', '#', '#',
        a => '1 filmstrip',
        j => '35 mm',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is( $result[1], '1 filmstrip',
        '300 edge lone $j postfix: $a unchanged' );
    is( $result[3], '35 mm',
        '300 edge lone $j postfix: lone $j untouched (no parens, no separator)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is( $result_pr[1], '1 filmstrip',
        '300 edge lone $j prefix: $a unchanged' );
    is( $result_pr[3], '35 mm',
        '300 edge lone $j prefix: lone $j untouched (no parens, no separator)' );

    check_combined( \@result, \@result_pr,
        '300 edge lone $j: combined string identical' );
}

# --- Edge case: $a directly followed by another $a (scores with parts, adjacent) ---
# This would be: $a 1 score (30 p.) $a 16 parts
# First $a gets " + " because next sf is $a
{
    # render: 300 ## $a 1 score (30 p.) $a 16 parts
    my $field = make_field(
        '300', '#', '#',
        a => '1 score (30 p.)',
        a => '16 parts',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'postfix' );
    is(
        $result[1],
        '1 score (30 p.) + ',
        '300 edge $a+$a postfix: first $a gets " + "'
    );
    is( $result[3], '16 parts',
        '300 edge $a+$a postfix: second $a (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules_300, 'prefix' );
    is(
        $result_pr[1],
        '1 score (30 p.)',
        '300 edge $a+$a prefix: first $a unchanged'
    );
    is( $result_pr[3], ' + 16 parts',
        '300 edge $a+$a prefix: second $a gets " + " prepended' );

    check_combined( \@result, \@result_pr, '300 edge $a+$a: combined string identical' );
}

done_testing();
