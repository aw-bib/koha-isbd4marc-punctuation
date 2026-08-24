package Koha::RecordProcessor::Base;

# Minimal mock for testing outside of Koha.
# This provides just enough of the base class for the filter to load.

use strict;
use warnings;

sub new {
    my ( $class ) = @_;
    return bless {}, $class;
}

1;
