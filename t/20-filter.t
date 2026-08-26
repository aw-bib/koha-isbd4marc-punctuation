#!/usr/bin/perl
#
# Integration test for the full filter() method.
# Tests that filter() responds correctly to leader byte 18,
# and that it actually processes (or skips) fields as expected.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use MARC::Record;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

my $filter = Koha::Filter::MARC::ISBD4MARCPunctuation->new;

# Helper: create a 24-char MARC leader with a given value at position 18
sub _leader_with {
    my ($pos18) = @_;
    my $leader = '00000naa a2200000   4500';  # 24 chars, pos18 is space
    substr( $leader, 18, 1, $pos18 );
    return $leader;
}

# --- Test 1: Leader/18 = 'c' → filter active ---
{
    my $record = MARC::Record->new;
    $record->leader( _leader_with('c') );
    $record->add_fields(
        '245', '0', '0',
        a => 'The great book',
        b => 'a subtitle',
    );

    my $result = $filter->filter($record);
    my $field  = $result->field('245');
    is(
        $field->subfield('a'),
        'The great book',
        'filter: leader/c → $a unchanged (prefix mode)'
    );
    is(
        $field->subfield('b'),
        ' : a subtitle',
        'filter: $b gets " : " prepended (prefix mode)'
    );
}

# --- Test 2: Leader/18 = 'n' → filter active ---
{
    my $record = MARC::Record->new;
    $record->leader( _leader_with('n') );
    $record->add_fields(
        '245', '0', '0',
        a => 'Another book',
        b => 'another subtitle',
    );

    my $result = $filter->filter($record);
    my $field  = $result->field('245');
    is(
        $field->subfield('a'),
        'Another book',
        'filter: leader/n → $a unchanged (prefix mode)'
    );
    is(
        $field->subfield('b'),
        ' : another subtitle',
        'filter: leader/n → $b gets " : " prepended (prefix mode)'
    );
}

# --- Test 3: Leader/18 = space → filter inactive ---
{
    my $record = MARC::Record->new;
    $record->leader( _leader_with(' ') );
    $record->add_fields(
        '245', '0', '0',
        a => 'Unchanged book',
        b => 'unchanged subtitle',
    );

    my $result = $filter->filter($record);
    my $field  = $result->field('245');
    is(
        $field->subfield('a'),
        'Unchanged book',
        'filter: leader/space → $a unchanged'
    );
    is(
        $field->subfield('b'),
        'unchanged subtitle',
        'filter: $b also unchanged'
    );
}

# --- Test 4: Undefined record → returns undef gracefully ---
{
    my $result = $filter->filter(undef);
    is( $result, undef, 'filter: undef record returns undef' );
}

# --- Test 5: Non-MARC::Record → returns as-is ---
{
    my $result = $filter->filter('just a string');
    is( $result, 'just a string', 'filter: non-MARC record returned as-is' );
}

done_testing();
