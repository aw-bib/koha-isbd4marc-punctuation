#!/usr/bin/perl
#
# Tests for _decorate_field with 490 rules.
#
# ISBD punctuation for 490 (Series Statement):
#   $a : $b / $c ; $d . $n , $p ; $v , $x = $r = $t = $y
#   $3 gets ': ' appended via post
#   $l wrapped in (...)

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::RULES->{490};
ok( defined $rules, '490 rules loaded' );

# --- Test 1: $a alone ---
{
    # render: 490 1# $a Bulletin
    my $field = make_field( '490', '1', ' ', a => 'Bulletin' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( scalar @result, 2,          '490: $a alone returns 2 elements' );
    is( $result[1],      'Bulletin', '490: $a alone is unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Bulletin', '490 prefix: $a alone unchanged' );

    is( join('', @result[1]), join('', @result_pr[1]), '490: combined string identical' );
}

# --- Test 2: $a followed by $c (Example 1 from doc) ---
# Doc: Current: 490 1# $a Bulletin / U.S. Department of Labor, Bureau of Labor Statistics
# Doc: Future: 490 1# $a Bulletin $c U.S. Department of Labor, Bureau of Labor Statistics
{
    # render: 490 1# $a Bulletin $c U.S. Department of Labor, Bureau of Labor Statistics
    my $field = make_field( '490', '1', ' ',
        a => 'Bulletin',
        c => 'U.S. Department of Labor, Bureau of Labor Statistics',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Bulletin / ',                                         '490 ex1: $a gets " / " for $c' );
    is( $result[3], 'U.S. Department of Labor, Bureau of Labor Statistics', '490 ex1: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Bulletin',                                           '490 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' / U.S. Department of Labor, Bureau of Labor Statistics', '490 ex1 prefix: $c gets " / " prepended' );

    is( join('', @result[1,3]), join('', @result_pr[1,3]), '490 ex1: combined string identical' );
}

# --- Test 3: $3 with $a and $v (Example 2 from doc) ---
# Doc: Current: 490 1# $3 v. 9-<10>: $a MPCHT art and anthropological monographs ; $v no. 35
# Doc: Future: 490 1# $3 v. 9-<10> $a MPCHT art and anthropological monographs $v no. 35
{
    # render: 490 1# $3 v. 9-<10> $a MPCHT art and anthropological monographs $v no. 35
    my $field = make_field( '490', '1', ' ',
        '3' => 'v. 9-<10>',
        a   => 'MPCHT art and anthropological monographs',
        v   => 'no. 35',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'v. 9-<10>: ',                              '490 ex2: $3 gets ": " appended via post' );
    is( $result[3], 'MPCHT art and anthropological monographs ; ', '490 ex2: $a gets " ; " for $v' );
    is( $result[5], 'no. 35',                                   '490 ex2: $v (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'v. 9-<10>: ',                                '490 ex2 prefix: $3 gets ": " via post' );
    is( $result_pr[3], 'MPCHT art and anthropological monographs',    '490 ex2 prefix: $a unchanged' );
    is( $result_pr[5], ' ; no. 35',                                   '490 ex2 prefix: $v gets " ; " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490 ex2: combined string identical' );
}

# --- Test 4: $a followed by $b followed by $v (Example 3 from doc) ---
# Doc: Current: 490 1# $a Detroit area study, 1971 : social problems and social change in Detroit ; $v no. 19
# Doc: Future: 490 1# $a Detroit area study, 1971 $b social problems and social change in Detroit $v no. 19
{
    # render: 490 1# $a Detroit area study, 1971 $b social problems and social change in Detroit $v no. 19
    my $field = make_field( '490', '1', ' ',
        a => 'Detroit area study, 1971',
        b => 'social problems and social change in Detroit',
        v => 'no. 19',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Detroit area study, 1971 : ',                       '490 ex3: $a gets " : " for $b' );
    is( $result[3], 'social problems and social change in Detroit ; ',    '490 ex3: $b gets " ; " for $v' );
    is( $result[5], 'no. 19',                                             '490 ex3: $v (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Detroit area study, 1971',                         '490 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ' : social problems and social change in Detroit',   '490 ex3 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' ; no. 19',                                         '490 ex3 prefix: $v gets " ; " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490 ex3: combined string identical' );
}

# --- Test 5: $3 with $a and $c (Example 4 from doc) ---
# Doc: Current: 490 1# $3 1972/73-1975-76: $a Research report / National Education Association Research
# Doc: Future: 490 1# $3 1972/73-1975-76 $a Research report $c National Education Association Research
{
    # render: 490 1# $3 1972/73-1975-76 $a Research report $c National Education Association Research
    my $field = make_field( '490', '1', ' ',
        '3' => '1972/73-1975-76',
        a   => 'Research report',
        c   => 'National Education Association Research',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], '1972/73-1975-76: ',                '490 ex4: $3 gets ": " via post' );
    is( $result[3], 'Research report / ',                '490 ex4: $a gets " / " for $c' );
    is( $result[5], 'National Education Association Research', '490 ex4: $c (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], '1972/73-1975-76: ',                  '490 ex4 prefix: $3 gets ": " via post' );
    is( $result_pr[3], 'Research report',                    '490 ex4 prefix: $a unchanged' );
    is( $result_pr[5], ' / National Education Association Research', '490 ex4 prefix: $c gets " / " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490 ex4: combined string identical' );
}

# --- Test 6: $a with $v and $x (Example 6 from doc) ---
# Doc: Current: 490 1# $a Annual census of manufactures = $a Recensement des manufactures, $x 0315-5587
# Doc: Future: 490 1# $a Annual census of manufactures $r Recensement des manufactures $x 0315-5587
{
    # render: 490 1# $a Annual census of manufactures $r Recensement des manufactures $x 0315-5587
    my $field = make_field( '490', '1', ' ',
        a => 'Annual census of manufactures',
        r => 'Recensement des manufactures',
        x => '0315-5587',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Annual census of manufactures = ',    '490 ex6: $a gets " = " for $r' );
    is( $result[3], 'Recensement des manufactures, ',      '490 ex6: $r gets ", " for $x' );
    is( $result[5], '0315-5587',                           '490 ex6: $x (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Annual census of manufactures',     '490 ex6 prefix: $a unchanged' );
    is( $result_pr[3], ' = Recensement des manufactures',   '490 ex6 prefix: $r gets " = " prepended' );
    is( $result_pr[5], ', 0315-5587',                       '490 ex6 prefix: $x gets ", " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490 ex6: combined string identical' );
}

# --- Test 7: $a + $n + $p + $v + $r (Example 7 from doc, abbreviated) ---
# Doc: Current: 490 1# $a Papers and documents... Series C, Bibliographies ; $v no. 3 = $a Travaux...
# Doc: Future: 490 1# $a Papers and documents... $n Series C $p Bibliographies $v no. 3 $r Travaux...
{
    # render: 490 1# $a Papers and documents of the I.C.I. $n Series C $p Bibliographies $v no. 3 $r Travaux et documents de l'I.C.I.
    my $field = make_field( '490', '1', ' ',
        a => 'Papers and documents of the I.C.I.',
        n => 'Series C',
        p => 'Bibliographies',
        v => 'no. 3',
        r => 'Travaux et documents de l\'I.C.I.',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Papers and documents of the I.C.I.. ',        '490 ex7: $a gets ". " for $n' );
    is( $result[3], 'Series C, ',                                  '490 ex7: $n gets ", " for $p' );
    is( $result[5], 'Bibliographies ; ',                           '490 ex7: $p gets " ; " for $v' );
    is( $result[7], 'no. 3 = ',                                    '490 ex7: $v gets " = " for $r' );
    is( $result[9], 'Travaux et documents de l\'I.C.I.',           '490 ex7: $r (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Papers and documents of the I.C.I.',        '490 ex7 prefix: $a unchanged' );
    is( $result_pr[3], '. Series C',                                '490 ex7 prefix: $n gets ". " prepended' );
    is( $result_pr[5], ', Bibliographies',     '490 ex7 prefix: $p gets ", " prepended' );
    is( $result_pr[7], ' ; no. 3',             '490 ex7 prefix: $v gets " ; " prepended' );
    is( $result_pr[9], ' = Travaux et documents de l\'I.C.I.', '490 ex7 prefix: $r gets " = " prepended' );

    is( join('', @result[1,3,5,7,9]), join('', @result_pr[1,3,5,7,9]), '490 ex7: combined string identical' );
}

# --- Test 8: $a + $v + $y (Example 8 from doc) ---
# Doc: Current: 490 1# $a Forschungen zur Geschichte Vorarlbergs ; $v 6. Bd. = der ganzen Reihe 13 Bd.
# Doc: Future: 490 1# $a Forschungen zur Geschichte Vorarlbergs $v 6. Bd. $y der ganzen Reihe 13 Bd.
{
    # render: 490 1# $a Forschungen zur Geschichte Vorarlbergs $v 6. Bd. $y der ganzen Reihe 13 Bd.
    my $field = make_field( '490', '1', ' ',
        a => 'Forschungen zur Geschichte Vorarlbergs',
        v => '6. Bd.',
        y => 'der ganzen Reihe 13 Bd.',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Forschungen zur Geschichte Vorarlbergs ; ', '490 ex8: $a gets " ; " for $v' );
    is( $result[3], '6. Bd. = ',                                 '490 ex8: $v gets " = " for $y' );
    is( $result[5], 'der ganzen Reihe 13 Bd.',                    '490 ex8: $y (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Forschungen zur Geschichte Vorarlbergs',   '490 ex8 prefix: $a unchanged' );
    is( $result_pr[3], ' ; 6. Bd.',                                '490 ex8 prefix: $v gets " ; " prepended' );
    is( $result_pr[5], ' = der ganzen Reihe 13 Bd.',               '490 ex8 prefix: $y gets " = " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490 ex8: combined string identical' );
}

# --- Test 9: $a + $x + $v + $n + $p + $x + $v (Example 9 from doc, abbreviated) ---
# Doc: Future: 490 1# $a Lund studies in geography $x 1400-1144 $v 101 $n Ser. B $p Human geography $x 0076-1478 $v 48
{
    # render: 490 1# $a Lund studies in geography $x 1400-1144 $v 101 $n Ser. B $p Human geography $x 0076-1478 $v 48
    my $field = make_field( '490', '1', ' ',
        a => 'Lund studies in geography',
        x => '1400-1144',
        v => '101',
        n => 'Ser. B',
        p => 'Human geography',
        x => '0076-1478',
        v => '48',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Lund studies in geography, ', '490 ex9: $a gets ", " for $x' );
    is( $result[3], '1400-1144 ; ',                '490 ex9: $x gets " ; " for $v' );
    is( $result[5], '101. ',                       '490 ex9: first $v gets ". " for $n' );
    is( $result[7], 'Ser. B, ',                    '490 ex9: $n gets ", " for $p' );
    is( $result[9], 'Human geography, ',           '490 ex9: $p gets ", " for $x' );
    is( $result[11], '0076-1478 ; ',               '490 ex9: second $x gets " ; " for $v' );
    is( $result[13], '48',                         '490 ex9: second $v (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Lund studies in geography',   '490 ex9 prefix: $a unchanged' );
    is( $result_pr[3], ', 1400-1144',                  '490 ex9 prefix: $x gets ", " prepended' );
    is( $result_pr[5], ' ; 101',                       '490 ex9 prefix: $v gets " ; " prepended' );
    is( $result_pr[7], '. Ser. B',                     '490 ex9 prefix: $n gets ". " prepended' );
    is( $result_pr[9], ', Human geography',            '490 ex9 prefix: $p gets ", " prepended' );
    is( $result_pr[11], ', 0076-1478',                 '490 ex9 prefix: second $x gets ", " prepended' );
    is( $result_pr[13], ' ; 48',                       '490 ex9 prefix: second $v gets " ; " prepended' );

    is( join('', @result[1,3,5,7,9,11,13]), join('', @result_pr[1,3,5,7,9,11,13]), '490 ex9: combined string identical' );
}

# --- Test 10: $l wrapped in parentheses ---
{
    # render: 490 1# $a Bulletin $l HE 20.1234
    my $field = make_field( '490', '1', ' ',
        a => 'Bulletin',
        l => 'HE 20.1234',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Bulletin',       '490: $a unchanged' );
    is( $result[3], '(HE 20.1234)',   '490: $l wrapped in parentheses' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Bulletin',     '490 prefix: $a unchanged' );
    is( $result_pr[3], '(HE 20.1234)', '490 prefix: $l wrapped in parentheses' );

    is( join('', @result[1,3]), join('', @result_pr[1,3]), '490: combined string identical' );
}

# --- Test 11: $d (subsequent statement of responsibility) ---
{
    # render: 490 1# $a Monograph series $c Institute for Research $d compiled by John Smith
    my $field = make_field( '490', '1', ' ',
        a => 'Monograph series',
        c => 'Institute for Research',
        d => 'compiled by John Smith',
    );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'postfix' );
    is( $result[1], 'Monograph series / ',        '490: $a gets " / " for $c' );
    is( $result[3], 'Institute for Research ; ',  '490: $c gets " ; " for $d' );
    is( $result[5], 'compiled by John Smith',      '490: $d (last) unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $rules, 'prefix' );
    is( $result_pr[1], 'Monograph series',          '490 prefix: $a unchanged' );
    is( $result_pr[3], ' / Institute for Research', '490 prefix: $c gets " / " prepended' );
    is( $result_pr[5], ' ; compiled by John Smith', '490 prefix: $d gets " ; " prepended' );

    is( join('', @result[1,3,5]), join('', @result_pr[1,3,5]), '490: combined string identical' );
}

done_testing();
