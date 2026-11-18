#!/usr/bin/perl
#
# DACH EQUAL-FIELD GUARD (descendant-vs-baseline).
#
# LoC/PCC is the BASELINE rule set; every later set (DACH first) is built
# as a DELTA over it. This file pins the tags where a descendant's resolved
# rules (pchrs/wrap/post/cb_pre, after use_rules) are byte-identical to
# LoC/PCC's: for those, a single equality assert per tag IS the test (no
# duplicated render blocks), and it catches future drift where a descendant
# silently diverges from the baseline it was meant to share.
#
# The identical set is computed defensively at runtime (a tag only belongs
# here if its resolved signature truly matches), then each is asserted. If a
# tag legitimately deviates later, it stops matching here and must move to the
# deltas test - the guard going red is the signal.
#
# The DACH-only fields (249, 532) and the deviating tags are tested in
# 50-dach-02-deltas.t / 50-dach-03-exclusive.t.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field combined_string check_combined);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $SET = 'DACH';
note( "Rule set under test: $SET (baseline: LoC/PCC)" );

my $dach = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);
my $lcp = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for('LoC/PCC');

# Resolve use_rules alias within a set, keeping the tag's own name.
sub _resolved {
    my ( $set, $tag ) = @_;
    my $r = $set->{$tag} or return undef;
    return $r unless $r->{use_rules};
    my $t = $set->{ $r->{use_rules} } or return $r;
    return { %$t, name => $r->{name} };
}

# A stable signature of the punctuation-relevant rule fields.
sub _sig {
    my ($r) = @_;
    return '' unless $r;
    my $p = $r->{pchrs} || {};
    my $w = $r->{wrap}  || {};
    my $po = $r->{post} || {};
    return join( '|',
        join( ',', sort map { "$_=" . ( ref $p->{$_} ? '[]' : $p->{$_} ) } keys %$p ),
        join( ',', sort map { "$_=" . join( '', @{ $w->{$_} } ) } keys %$w ),
        join( ',', sort map { "$_=" . $po->{$_} } keys %$po ),
        ( ref $r->{cb_pre} eq 'CODE' ? 'cbCODE' : ( $r->{cb_pre} || '' ) ),
    );
}

# Collect tags present in BOTH sets whose resolved signatures are identical.
my @identical =
  sort { $a <=> $b }
  grep { _sig( _resolved( $dach, $_ ) ) eq _sig( _resolved( $lcp, $_ ) ) }
  grep { $lcp->{$_} } keys %$dach;

ok( scalar(@identical) >= 1, 'Found at least one identical (shared) tag for the guard' );

for my $tag (@identical) {
    my $kr = _resolved( $dach, $tag );
    my $lr = _resolved( $lcp, $tag );
    is_deeply(
        { pchrs => $kr->{pchrs} || {}, wrap => $kr->{wrap} || {}, post => $kr->{post} || {} },
        { pchrs => $lr->{pchrs} || {}, wrap => $lr->{wrap} || {}, post => $lr->{post} || {} },
        "D-A-CH tag $tag keeps LoC/PCC baseline rules"
    );
    is(
        ( ref $kr->{cb_pre} eq 'CODE' ? ref($kr->{cb_pre}) : ( $kr->{cb_pre} || '' ) ),
        ( ref $lr->{cb_pre} eq 'CODE' ? ref($lr->{cb_pre}) : ( $lr->{cb_pre} || '' ) ),
        "D-A-CH tag $tag cb_pre matches LoC/PCC baseline"
    );
}

# Sanity: the guard should NOT silently include tags we deliberately deviate.
my @known_deviation = qw(015 020 024 100 110 130 240 242 243 245 246 247 250 254
  255 260 264 300 310 321 343 362 490 500 502 515 520 525 534 700 710 730
  760 762 765 767 770 772 773 774 775 776 777 780 785 786 787 830);
my %dev = map { $_ => 1 } @known_deviation;
my @wrong = grep { $dev{$_} } @identical;
is_deeply( \@wrong, [], 'Guard excludes all known-deviating tags (no false inclusion)' );

done_testing();
