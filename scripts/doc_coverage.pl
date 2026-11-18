#!/usr/bin/env perl
#
# doc_coverage.pl - Generate a machine-readable coverage table (YAML) of the
#   LoC/PCC rule set's test coverage against the reference document.
#
# The reference document ("Revised Final Report PCC ISBD and MARC Task Group,
# October 2016", isbdmarc2016.txt) contains per-field "Current:"/"Future:"
# example pairs. Our test suite carries a '# render:' marker (with a
# [doc ...]/[LoC ...]/[constructed] provenance token) per example it
# implements. This script reads those markers -- the SINGLE SOURCE OF TRUTH --
# and emits a machine-readable YAML table so that "have we covered every
# documented example?" becomes a queryable, diff-able statement rather than a
# manual claim.
#
#   Provenance kinds (from the marker token):
#     doc          - drawn verbatim (or '- derived') from the reference doc
#     loc          - split from a real pre-punctuated LoC (MARC21) record
#     constructed  - made up to exercise the rules as written
#     not_handled  - a documented skip: [doc §X.Y #N - NOT HANDLED: reason]
#                    (added in the coverage pass; no render body)
#
# The examples carry no doc '#' (per-section example) numbering yet; that
# pin is added in the coverage pass (marker form [doc §X.Y #N]). Until then,
# 'num' is null and 'status' mirrors the provenance kind.
#
# Usage:
#   ./scripts/doc_coverage.pl [--set=LoC/PCC|DACH] [OUTFILE] [TESTFILE...]
#
# By default only the LoC/PCC markers are collected (the coverage table is
# LoC/PCC-scoped). Pass --set=DACH (or any set name, matched against each
# test file's 'my $SET = ...' declaration) to collect that set's markers
# instead, e.g. for a future DACH coverage run.
#
# Sync check (to assert the table is up to date with the tests):
#   perl scripts/doc_coverage.pl && git diff --exit-code docs/doc_coverage.yaml
#
# Reads TestHelper from t/lib so marker parsing stays the single source of
# truth with the rest of the suite.

use strict;
use warnings;
use lib '.';
use lib 't/lib';
use t::lib::TestHelper qw( parse_render_marker );

# Which rule set's markers to collect. Every marker-bearing test file declares
# 'my $SET = ...'; we only collect files whose declared set matches this.
# Default 'LoC/PCC' keeps docs/doc_coverage.yaml (and the t/99 byte-identity
# gate) LoC/PCC-pure - the DACH markers in t/50-dach-*.t are excluded.
my $set_filter = 'LoC/PCC';
my @rest;
for my $a (@ARGV) {
    if ( $a =~ /^--set=(.*)$/ ) { $set_filter = $1; }
    else                        { push @rest, $a; }
}
@ARGV = @rest;

my $outfile   = shift // 'docs/doc_coverage.yaml';
my @testfiles = @ARGV;
@testfiles = glob('t/*.t') unless @testfiles;

# --- Collect examples: field tag -> ordered list of { ... } ---
# Preserve source-file + original order; group later by tag.
my @collect;    # flat list of { tag, prov, marker, file }

for my $file (@testfiles) {
    open my $fh, '<', $file or die "Cannot read $file: $!\n";
    # A file belongs to this run only if its declared $SET matches. (Marker-
    # bearing files always declare 'my $SET = ...'; a file with no such
    # declaration contributes nothing to any set's table.)
    my $file_set = '';
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*my\s+\$SET\s*=\s*'([^']+)'/ ) { $file_set = $1; last; }
    }
    close $fh;
    next unless $file_set eq $set_filter;

    open $fh, '<', $file or die "Cannot read $file: $!\n";
    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*#\s*render:/;
        my $marker = $line;

        # Detect a NOT-HANDLED / DECISION marker (no render body): line forms
        #   # render: [doc §X.Y #N - NOT HANDLED: reason]
        #   # render: [doc §X.Y - DECISION: reason]
        if ( $marker =~ /\[(doc|LoC)\b[^\]]*\b(?:NOT\s+HANDLED|DECISION)\b[^\]]*\]/i ) {
            # Tag is the 3-digit field code AFTER the [doc ...] provenance
            # token (the marker has no render body, so the tag is the only
            # field info on the line).
            my ($tag) = $marker =~ /render:\s*(?:\[[^\]]*\]\s*)?(\d{3})\b/;
            $tag = '' unless defined $tag;
            my $kind = ( $marker =~ /\bDECISION\b/i ) ? 'decision' : 'not_handled';
            my ($reason) = $marker =~ /-\s*(?:NOT\s+HANDLED|DECISION):\s*([^\]]*)\]/i;
            $reason = '' unless defined $reason;
            push @collect, {
                tag      => $tag,
                kind     => $kind,
                section  => '',
                derived  => 0,
                num      => undef,
                reason   => ( defined $reason ? $reason : '' ),
                marker   => $marker,
                file     => $file,
            };
            next;
        }

        my ( $prov, $tag, $ind1, $ind2, @subfields ) =
          parse_render_marker($marker);
        next unless defined $tag;

        my $kind = $prov->{kind} eq 'doc' ? 'doc'
          : $prov->{kind} eq 'LoC' ? 'loc'
          : 'constructed';

        # status: doc gets 'derived' when '- derived'; loc/constructed as-is
        my $status = $kind;
        $status = 'derived' if $kind eq 'doc' && $prov->{derived};

        push @collect, {
            tag      => $tag,
            kind     => $kind,
            status   => $status,
            section  => $prov->{section},
            derived  => $prov->{derived},
            num      => undef,
            reason   => '',
            marker   => $marker,
            file     => $file,
        };
    }
    close $fh;
}

# --- Group by tag, preserving first-seen order, keep original file order ---
my %order;
my @tags;
for my $e (@collect) {
    next unless length $e->{tag};
    if ( !exists $order{ $e->{tag} } ) {
        $order{ $e->{tag} } = 1;
        push @tags, $e->{tag};
    }
}
@tags = sort { $a <=> $b } @tags;

# --- Count summary by kind ---
my %bykind;
$bykind{ $_->{kind} }++ for @collect;

# --- Emit deterministic YAML ---
my @out;
push @out, '# GENERATED by scripts/doc_coverage.pl from the t/*.t "# render:"';
push @out, '# markers (the single source of truth). DO NOT EDIT BY HAND.';
push @out, '# Regenerate with: perl scripts/doc_coverage.pl';
push @out, '# Sync check:      perl scripts/doc_coverage.pl && git diff --exit-code docs/doc_coverage.yaml';
push @out, '';
push @out, 'meta:';
push @out, '  ruleset: "LoC/PCC"';
push @out, '  doc: "Revised Final Report PCC ISBD and MARC Task Group, October 2016"';
push @out, '  source: "t/*.t # render: markers (single source of truth)"';
push @out, '  generated_by: "scripts/doc_coverage.pl"';
push @out, '  notes: >-';
push @out, '    "num" (per-section example number) is null until the coverage pass';
push @out, '    pins each [doc §X.Y #N] marker; "status" mirrors kind until then.';
push @out, 'summary:';
push @out, '  total_examples: ' . scalar(@collect);
for my $k (qw(doc derived loc constructed not_handled decision)) {
    push @out, sprintf( '  %s: %d', $k, $bykind{$k} || 0 );
}
push @out, 'fields:';

for my $tag (@tags) {
    push @out, "  - tag: \"$tag\"";
    push @out, '    examples:';
    for my $e ( grep { $_->{tag} eq $tag } @collect ) {
        push @out, '      - doc: ' . ( $e->{section} ? qq{"$e->{section}"} : 'null' );
        push @out, '        num: ' . ( defined $e->{num} ? $e->{num} : 'null' );
        push @out, '        kind: ' . $e->{kind};
        push @out, '        status: ' . ( $e->{status} || $e->{kind} );
        push @out, '        derived: ' . ( $e->{derived} ? 'true' : 'false' );
        push @out, '        reason: ' . ( length $e->{reason} ? qq{"$e->{reason}"} : '""' );
        push @out, '        testfile: ' . qq{"$e->{file}"};
        # marker: prose one-liner (first line, trimmed) for human glance
        my $m = $e->{marker};
        $m =~ s/^\s+|\s+$//g;
        $m =~ s/\$\\/\\\$/g;    # keep \$ readable, avoid YAML-ambiguous
        push @out, '        marker: ' . qq{"$m"};
    }
}

open my $out, '>', $outfile or die "Cannot write $outfile: $!\n";
print {$out} join( "\n", @out ), "\n";
close $out;

print "Wrote $outfile (", scalar(@collect), " examples across ",
  scalar(@tags), " fields)\n";
