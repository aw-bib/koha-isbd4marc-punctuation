#!/usr/bin/perl
# Before running, set PERL5LIB to include t/lib:
#   PERL5LIB=t/lib perl t/00-load.t

use strict;
use warnings;

# Mock Koha base class before loading the filter
use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More tests => 2;

BEGIN { use_ok('Koha::Filter::MARC::ISBD4MARCPunctuation') }

my $filter = Koha::Filter::MARC::ISBD4MARCPunctuation->new;
isa_ok( $filter, 'Koha::Filter::MARC::ISBD4MARCPunctuation', 'filter object created' );
