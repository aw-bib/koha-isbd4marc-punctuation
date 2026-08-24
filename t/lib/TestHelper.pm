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

1;
