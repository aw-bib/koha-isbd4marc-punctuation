#!/usr/bin/perl
#
# render_examples.pl - Generate a human/librarian-readable Markdown report
# of the ISBD punctuation plugin output.
#
# The report is derived from the SAME input data as the unit tests: each
# example block in a t/*.t file that carries a '# render:' marker comment is
# parsed, decorated in both postfix and prefix modes, and rendered as MARC-ish
# lines. Keeping the tests as the single source of truth means the report
# cannot drift away from what is actually tested.
#
# The bookkeeping of the plugin's rules lives in the plugin module itself, so
# this script only needs to read the markers and call _decorate_field.
#
# Marker convention (one line per example block):
#     # render: 245 ## $a Quatrain II $g 16:35 $t Water ways
#
# Usage:
#     ./scripts/render_examples.pl [OUTFILE] [TESTFILE...]
#
# Defaults:
#     OUTFILE   = examples/koha-isbd4marc-puncuation-output.md
#     TESTFILES = t/*.t
#

use strict;
use warnings;
use lib 'lib', 't/lib';
use File::Basename qw(basename);
use Koha::RecordProcessor::Base;
use Koha::Filter::MARC::ISBD4MARCPunctuation;
use t::lib::TestHelper qw( parse_render_marker render_field_string combined_string );

# The rule set the report is rendered for.
my $SET = 'LoC/PCC';

my $outfile   = shift // 'examples/koha-isbd4marc-puncuation-output.md';
my @testfiles = @ARGV;
@testfiles = glob('t/*.t') unless @testfiles;

# --- Collect (field_tag => [ marker, ... ]) per file, preserving order ---
my @sections;    # each: { tag, markers => [ [file, marker], ... ] }
my %index;       # tag -> section index

for my $file (@testfiles) {
    open my $fh, '<', $file or die "Cannot read $file: \$!\n";
    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*#\s*render:/;
        my $marker = $line;
        # Optional [doc ...] provenance token may precede the tag.
        my ($tag) = $marker =~ /render:\s*(?:\[doc\b[^\]]*\]\s*)?(\d{3})\b/ or next;
        $tag =~ s/\D//g;    # defensive

        # Provenance: [doc] token (possibly with section / '- derived') =
        # drawn from / derived from the reference document; absent =>
        # constructed. Keep the raw token for the per-example label.
        my ($tok) = $marker =~ /render:\s*(\[doc\b[^\]]*\])\s*\d{3}/i;
        my $provenance =
            defined $tok ? $tok
          : 'constructed';

        my $idx = $index{$tag};
        if ( !defined $idx ) {
            $idx = scalar @sections;
            $index{$tag} = $idx;
            push @sections, { tag => $tag, markers => [] };
        }
        push @{ $sections[$idx]{markers} }, [ $file, $marker, $provenance ];
    }
    close $fh;
}

# --- Order the field sections numerically by tag for easy reference ---
# Each section already merges every marker for its tag across ALL files
# (field tests + regression tests), so sorting sections gives e.g. one
# contiguous "Field 245" block even though its markers came from two files.
@sections = sort { $a->{tag} <=> $b->{tag} } @sections;

# --- Render each example in both modes ---
my @md;
push @md, '# ISBD punctuation plugin — rendered examples';
push @md, '';
push @md, "Rule set: $SET";
push @md, '';
push @md,
    'These examples are generated from the plugin\'s own test suite. '  
  . 'For each field, the raw (un-punctuated) input is shown together '  
  . 'with the automatic punctuation added in `postfix` mode, plus the '  
  . 'combined (concatenated) output. `prefix` mode produces the same '  
  . 'combined string, so only the combined line is shown here.';
push @md, '';

# Provenance legend. 'doc' = drawn from the reference document; constructed
# = made up to cover every decoration the working group came up with.
push @md, '## Provenance';
push @md, '';
push @md,
    'Examples marked with `[doc]` were drawn from the '
  . '"Revised Final Report PCC ISBD and MARC Task Group, October 2016".';
push @md, '';
push @md,
    'Examples marked `Constructed` are not taken from that document — they '
  . 'were made up to exercise the rules as written (edge cases and the '
  . 'various decorations the working group described), so both the '
  . 'reference cases and the general rule coverage are visible.';
push @md, '';
push @md,
    'Within each field, the reference (`[doc]`) examples are listed first; '
  . 'constructed examples follow.';
push @md, '';

for my $section (@sections) {
    my $tag = $section->{tag};
    push @md, "## Field $tag";
    push @md, '';

    # Within a field, list the reference-document (doc) examples FIRST, then
    # the constructed ones — keeps the 'we reproduce the spec examples'
    # capability front and center. Stable: doc and constructed each keep
    # their original (file) order.
    my @order =
      sort { ( $b->[2] ne 'constructed' ) <=> ( $a->[2] ne 'constructed' ) }
      @{ $section->{markers} };

    my $exno = 0;
    for my $ref (@order) {
        my ( $file, $marker, $provenance ) = @$ref;
        $exno++;

        my ( $prov, $ftag, $ind1, $ind2, @subfields ) =
          parse_render_marker($marker);
        my $rules =
          Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{$ftag};
        if ( !$rules ) {
            warn "No rules for tag $ftag (from $file); skipping\n";
            next;
        }

        my $field = MARC::Field->new( $ftag, $ind1, $ind2, @subfields );

        my @out_postfix =
          Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
            $rules, 'postfix' );

        my $no_punct = render_field_string( $ftag, $ind1, $ind2, @subfields );
        my $postfix  = render_field_string( $ftag, $ind1, $ind2, @out_postfix );
        my $combined = combined_string(@out_postfix);

        # Provenance label from the parsed [doc ...] token.
        my $label;
        if ( $prov->{kind} ne 'doc' ) {
            $label = 'Constructed (rules as written)';
        }
        elsif ( $prov->{derived} ) {
            $label = $prov->{section}
              ? "Derived from doc $prov->{section}"
              : 'Derived from doc';
        }
        else {
            $label = $prov->{section}
              ? "Reference (doc $prov->{section})"
              : 'Reference (doc)';
        }
        push @md, "### $tag example $exno — $label";
        push @md, '';
        push @md, "No punctuation (LDR/18 = c or n):";
        push @md, "```";
        push @md, "  $no_punct";
        push @md, "```";
        push @md, "_Postfix_ punctuation (automatic):";
        push @md, "```";
        push @md, "  $postfix";
        push @md, "```";
        push @md, "_Combined string_ (concatenation of the postfix values):";
        push @md, "```";
        push @md, "  $combined";
        push @md, "```";
        push @md, '';
    }
}

# --- Write output ---
open my $out, '>', $outfile or die "Cannot write $outfile: $!\n";
print {$out} join( "\n", @md ), "\n";
close $out;

print "Wrote $outfile\n";
