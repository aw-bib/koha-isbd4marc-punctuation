# Helper for building test MARC::Field and MARC::Record objects.
# Provides convenience functions for quick test construction.

package t::lib::TestHelper;

use strict;
use warnings;
use MARC::Field;
use Exporter qw(import);

our @EXPORT_OK = qw(
  make_field
  field_contains
  parse_render_marker
  render_field_string
);

sub make_field {
    my ( $tag, $ind1, $ind2, @subfields ) = @_;
    return MARC::Field->new( $tag, $ind1, $ind2, @subfields );
}

# Check that a list of subfield key/value pairs contains expected ones
# @new_subfields comes from _decorate_field as (sf, value, sf, value, ...)
sub field_contains {
    my ( $new_subfields, $sf, $expected_value ) = @_;
    my %sf = @$new_subfields;
    return exists $sf{$sf} && $sf{$sf} eq $expected_value;
}

# Parse a '# render:' marker line into a MARC-ish field description.
#
# Format (mirrors the spec's Future/Current lines):
#     # render: 245 ## $a Quatrain II $g 16:35 $t Water ways
# where: tag = 3 digits, then TWO indicator chars, then zero or more
# $<code> <value> pairs (subfield codes are single letters or digits).
# A literal dollar sign inside a subfield value is written as \$ (e.g.
# 020 $c prices like \$5.00) so it is not mistaken for a subfield
# introducer.
# Returns a list: ( tag, ind1, ind2, @subfields ).
sub parse_render_marker {
    my ($marker) = @_;

    # Strip the leading '# render:' prefix and surrounding whitespace
    $marker =~ s/^\s*#?\s*render:\s*//i;

    my ( $tag, $ind1, $ind2, $rest ) = $marker =~ /^(\d{3})\s*(.)(.)\s*(.*)$/;
    die "Cannot parse render marker: '$marker'" unless defined $tag;

    my @subfields;
    # Value capture allows an escaped literal dollar (\$); everything else
    # up to the next unescaped subfield introducer is the value.
    while ( $rest =~ /\$([A-Za-z0-9])\s*((?:\\\$|[^\$\\])*)/g ) {
        my $code  = $1;
        my $value = $2;
        $value =~ s/\\\$/\$/g;    # unescape \$ -> literal $
        $value =~ s/\s+$//;    # trim trailing whitespace
            # Decode Perl-style \uXXXX unicode escapes (as used in test sources)
        $value =~ s/\\u([0-9a-fA-F]{4})/chr(hex($1))/ge;
        push @subfields, $code, $value;
    }

    return ( $tag, $ind1, $ind2, @subfields );
}

# Render a field as a MARC-ish string, e.g.
#     260 ## $a New York $b Penguin $c 2005
# Takes ( tag, ind1, ind2, @subfields ).  A literal dollar sign inside a
# value is escaped as \$ so the output round-trips through
# parse_render_marker and stays unambiguous.
sub render_field_string {
    my ( $tag, $ind1, $ind2, @subfields ) = @_;
    my $out = "$tag $ind1$ind2";
    for ( my $i = 0 ; $i < @subfields ; $i += 2 ) {
        my $val = $subfields[ $i + 1 ];
        $val =~ s/\$/\\\$/g;    # escape literal dollar
        $out .= " \$$subfields[$i] $val";
    }
    return $out;
}

1;
