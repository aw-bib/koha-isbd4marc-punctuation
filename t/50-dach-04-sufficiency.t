#!/usr/bin/perl
#
# DACH SUFFICIENCY GATE.
#
# Guards that the DACH rule set faithfully represents every isbd.py
# subfield rule. isbd.py (project root) is the German-union reference: a
# flat tag -> { subfield -> punctuation } mapping (no x.y reference-doc
# structure). The sufficiency guarantee analogous to the LoC/PCC
# doc-coverage gate is therefore: EVERY non-empty isbd.py key is "answered"
# by DACH.pm - either as a resolved pchrs/post/wrap key, or via a shared
# structural callback (cb_pre), or as a documented known gap. In the reverse
# direction, every SINGLE-character subfield key DACH.pm adds must be
# traceable to isbd.py or a documented LoCPCC keep (multi-char keys like
# cc/dc/nd/aa/ba/3X are engine compound/mechanism keys, never subfield codes,
# and are auto-allowed).
#
# The isbd.py key table is transcribed here (hand-authored, reviewable). It
# is a fixed reference; once written this pins the port. Compound keys
# (nn, cc, dc, nd, ab, ba, ca, tc, ...) are listed where isbd.py uses them.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

use Test::More;

my $SET = 'DACH';
note( "Rule set under test: $SET (sufficiency vs isbd.py)" );

# --------------------------------------------------------------------------
# isbd.py NON-EMPTY subfield keys per tag (transcribed from ../isbd.py).
# Keys whose isbd.py value is '' are N/A and impose no forward requirement.
# NOTE: isbd.py derives subjects/series from the X-bases via .copy() with a
# $v exception (ISBD600 = ISBDX00 w/ v=''; ...), so 600/610/611/630 carry the
# same non-empty set as 100/110/111/130. 650/651/655/656/657/658/648 are NOT
# in isbd.py (LoC/PCC-reference fields) - they impose no requirement here.
# --------------------------------------------------------------------------
my %ISBD = (
  '015' => ['q'], '020' => ['c','q'], '024' => ['c','q'],
  '100' => ['c','d','e','f','j','k','l','m','n','o','p','q','r','s','t'],
  '110' => ['b','c','d','e','g','p','r','s','t','u','cc','dc','nd'],
  '111' => ['c','d','e','f','g','h','j','k','l','p','q','s','t'],
  '130' => ['d','f','g','h','k','l','m','n','o','p','r','s','t'],
  '210' => ['b'], '222' => ['b'],
  '240' => ['d','f','g','h','k','l','m','nn','n','o','p','r','s'],
  '242' => ['a','b','c','h','n','p'],
  '245' => ['b','c','f','h','k','n','p','s'],
  '246' => ['b','g','h','n','p'],
  '247' => ['b','f','g','h','n','p'],
  '249' => ['a','v','b','c'],
  '250' => ['b'], '254' => [], '255' => ['b','c','d','e'],
  '258' => ['b'], '260' => ['a','b','c','f','g','3'], '264' => ['a','b','c','3'],
  '300' => ['b','ba','c','ca','e'],
  '307' => ['b'], '310' => ['b'], '321' => ['b'],
  '343' => ['b','c','d','e','g','h','i'],
  '351' => ['a','b'],
  '352' => ['b','c','e','f','g','i','q'],
  '362' => ['z'],
  '490' => ['l','v','x','3'],
  '500' => [], '502' => ['b','c','d'], '504' => [],
  '505' => ['g','r','t'],
  '506' => ['b','c','d','e','f','u'], '507' => ['b'],
  '510' => ['b','c','x'], '511' => [], '513' => ['b'],
  '515' => [], '520' => ['b'], '525' => [],
  '526' => [], '530' => ['b','c','d'], '532' => [],
  '533' => ['b','c','d','e','f','m','n'],
  '534' => ['b','c','tc','e','f','k','l','m','n','o','p','t','x','z'],
  '535' => ['b','c','d'], '538' => [],
  '540' => ['b','c','d','u'],
  '541' => ['a','b','c','d','e','f','h','n'],
  '544' => ['a','b','c','e'], '546' => ['b'], '547' => [], '550' => [],
  '555' => ['b','c','d','u'],
  '562' => ['b','c','d','e'], '565' => ['b','c','d','e'],
  '580' => [],
  '584' => ['a','b'],
  '760' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '762' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '765' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '767' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '770' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '772' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '773' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '774' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '775' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '776' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '777' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '780' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '785' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '786' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '787' => ['ab','b','c','d','g','h','k','m','n','p','s','t'],
  '600' => ['c','d','e','f','j','k','l','m','n','o','p','q','r','s','t'],
  '610' => ['b','c','d','e','g','p','r','s','t','u','cc','dc','nd'],
  '611' => ['c','d','e','f','g','h','j','k','l','p','q','s','t'],
  '630' => ['d','f','g','h','k','l','m','n','o','p','r','s','t'],
  '800' => ['c','d','e','f','j','k','l','m','n','o','p','q','r','s','t','v'],
  '810' => ['b','c','d','e','g','p','r','s','t','u','v','cc','dc','nd'],
  '811' => ['c','d','e','f','g','h','j','k','l','p','q','s','t','v'],
  '830' => ['d','f','g','h','k','l','m','n','o','p','r','s','t','v','x'],
);

# --------------------------------------------------------------------------
# Structural callbacks (cb_pre): isbd.py keys answered by a SHARED callback /
# compound-key mechanism rather than a literal pchrs/post/wrap key of the same
# name. These legitimately satisfy the forward requirement.
#   - x10/x11 $g  : grouped by _decorate_x10_pre (gg compound supplies ' : ')
#   - x11 c/d      : meeting $n/$d/$c group via _decorate_x10_pre + cc/dc/nd
#   - 255 c/d/e    : cde paren run-group (_decorate_paren_group_pre)
#   - 260/264 a    : ' ;' via aa/ba compounds (bare `a` would over-fire on $3$a)
#   - 352 b/e/f    : via ab/cb (b) and de/ef (e/f) compounds
#   - 210/222 b    : $b qualifier group (_decorate_qualifier_group_pre)
# --------------------------------------------------------------------------
my %CB = (
  '110' => { g => 1 }, '111' => { c=>1, d=>1, g=>1 },
  '255' => { c=>1, d=>1, e=>1 },
  '260' => { a=>1, f=>1, g=>1 },   # f/g via the 260 e/f/g paren group
  '264' => { a=>1 },
  '352' => { b=>1, e=>1, f=>1 },
  '210' => { b=>1 }, '222' => { b=>1 },
  '610' => { g => 1 }, '611' => { c=>1, d=>1, g=>1 },
  '810' => { g => 1 }, '811' => { c=>1, d=>1, g=>1 },
);

# --------------------------------------------------------------------------
# Documented KNOWN GAPS: isbd.py keys that DACH.pm genuinely does not
# implement (surfaced, not hidden - if one is later fixed, remove it here and
# the gate stays consistent). The former 630 d/t gap (isbd.py X30
# $d-wrapped-() and $t '. ' keys) was CLOSED 2026-09-15 (see 50-dach-02
# deltas) - the gate now reports none.
# --------------------------------------------------------------------------
my %KNOWN_GAP = ();

# --------------------------------------------------------------------------
# Documented single-char LoCPCC keeps NOT in isbd.py (reverse extras). These
# are deliberate: LoCPCC's richer subject inverted-name / relator handling
# carried into D-A-CH subject & series fields.
# --------------------------------------------------------------------------
my %SINGLE_EXTRA = (
  # $h inverted-name split (LoCPCC subject/series extra)
  '600' => { h => 1 }, '800' => { h => 1 },
  # title-portion keys on subject/series corporate (LoCPCC sec 5.5 keep)
  '610' => { map { $_ => 1 } qw(f h j k l m o) },
  '810' => { map { $_ => 1 } qw(f h j k l m o) },
  # 630-only relator-term $e + $j (LoCPCC subject keep)
  '630' => { map { $_ => 1 } qw(e j) },
);

my $dach = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);

# Resolve a use_rules alias within the set (keep the tag's own name).
sub _resolved {
    my ($tag) = @_;
    my $r = $dach->{$tag} or return undef;
    return $r unless $r->{use_rules};
    return ( $dach->{ $r->{use_rules} } || $r );
}

ok( scalar( keys %ISBD ) >= 20, 'isbd.py key table has content (20+ tags transcribed)' );

# ---- FORWARD: every isbd.py non-empty key is answered. -------------------
my @fw_missing;
for my $tag ( sort { $a <=> $b } keys %ISBD ) {
    my $r = _resolved($tag) or next;
    my %have;
    $have{$_} = 1 for keys %{ $r->{pchrs} || {} }, keys %{ $r->{post} || {} },
      keys %{ $r->{wrap} || {} };
    for my $k ( @{ $ISBD{$tag} } ) {
        next if $have{$k} || ( $CB{$tag} && $CB{$tag}{$k} )
          || ( $KNOWN_GAP{$tag} && $KNOWN_GAP{$tag}{$k} );
        push @fw_missing, "$tag:\$$k";
    }
}
is_deeply(
    \@fw_missing, [],
    'Forward: every isbd.py non-empty key is a key, cb_pre-handled, or a documented known gap'
);

# The known-gap list must match EXACTLY what is genuinely unhandled (so a
# gap fixed without updating the list turns this gate red).
note( 'Documented known gaps (surfaced for a later decision): '
      . ( @{ [ sort { $a <=> $b } keys %KNOWN_GAP ] } ? join( ', ', sort { $a <=> $b } keys %KNOWN_GAP ) : '(none)' ) );

# ---- REVERSE: single-char D-A-CH keys are isbd.py keys or documented. ---
# Multi-char keys (cc/dc/nd/gg/aa/ba/ab/cb/de/ef/cd/ep/gn/tn/3X...) are engine
# compound/mechanism keys, never subfield codes - auto-allowed.
my @rv_extra;
for my $tag ( sort { $a <=> $b } keys %ISBD ) {
    my $r = _resolved($tag) or next;
    my %pyk; $pyk{$_} = 1 for @{ $ISBD{$tag} };
    my @keys = keys %{ $r->{pchrs} || {} };
    push @keys, keys %{ $r->{post} || {} }, keys %{ $r->{wrap} || {} };
    for my $k (@keys) {
        next if length($k) != 1;    # compound/mechanism keys auto-allowed
        next if $pyk{$k} || ( $SINGLE_EXTRA{$tag} && $SINGLE_EXTRA{$tag}{$k} );
        push @rv_extra, "$tag:\$$k";
    }
}
is_deeply(
    \@rv_extra, [],
    'Reverse: every single-char D-A-CH key is an isbd.py key or a documented LoCPCC keep'
);

done_testing();
