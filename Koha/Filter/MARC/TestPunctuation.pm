package Koha::Filter::MARC::TestPunctuation;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use MARC::Field;

use base qw(Koha::RecordProcessor::Base);

our $NAME = 'TestPunctuation';
our $VERSION = '0.01';


=head1 NAME

Koha::Filter::MARC::Punctuation - Automatically add punctuation to
Marc records if the leader specifies they were catalogued without it.

Documentation for proper punctuation:
https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf

=head1 DESCRIPTION

If the Marc leader 18 specifies, that the record was catalogued
without punctuation add the proper punctuation chars to the individual
fields before passing the record on to fruther processing. Once this
filter is applied it should be safe for further steps to assume that
the record holds Marc punctuation. (The records in the database are
_not_ changed.)

Trigger to add punctuation: leader 18 is either `n` or `c`.

Currently handled fields:

- 245
- 246
- 247

=cut

=head2 _decorate_245

Add punctuation to MARC field 245 (title statement). The function
assumes that it is only called if no punctuation is part of the
record.
=cut

sub _decorate_245 {

    my ($field) = @_;

    # simple chars _preceeding_ a subfield
    my %pchrs = (
        'b' => ' : ',
        'c' => ' / ',
        'd' => ' ; ',
        'e' => '. ',
        'f' => ', ',
        'g' => ', ',
        'k' => ' : ',
        'n' => '. ',
        'p' => ', ',
        's' => '. ',
    );

    my @new_subfields = ();
    foreach my $subfield ( $field->subfields ) {
        my ( $sf, $value ) = @$subfield;
        if ( defined $value ) {

            # Clean spaces at the end of a value
            $value =~ s/\s+$//;

            if ( exists $pchrs{$sf} ) {
                $value = $pchrs{$sf} . $value;
            }

            # media type needs to be enclosed
            if ( $sf eq 'h' ) {
                $value = '[' . $value . ']';
            }

            push( @new_subfields, $sf, $value );

            # TBD do titles always end with a `.` e.g.
            # $value .= '.' unless $value =~ /[\.,;:\/?!]$/;
        }
    }
    return @new_subfields;
}


=head2 _decorate_246_247

Add punctuation to MARC field 246 (varying form title), 247 (former
title). The function assumes that it is only called if no punctuation
is part of the record.

=cut

sub _decorate_246_247 {

    my ($field) = @_;

    my %pchrs = (
        'b' => ' : ',
        'f' => ', ',
        'n' => '. ',
        'q' => ', ',
        'r' => ' = ',
        't' => ' = ',
    );

    my @new_subfields = ();
    foreach my $subfield ( $field->subfields ) {
        my ( $sf, $value ) = @$subfield;

        if ( defined $value ) {
            if ( exists $pchrs{$sf} ) {
                $value = $pchrs{$sf} . $value;
            }

            if ( $sf eq 'i' ) {

                # _append_ a char to i
                $value .= ': ';
            }
            if ( $sf eq 'g' ) {
                $value = '(' . $value . ')';
            }

            # media type needs to be enclosed
            if ( $sf eq 'h' ) {
                $value = '[' . $value . ']';
            }

            push( @new_subfields, $sf, $value );

        }
        # TBD do titles always end with a `.`?
    }
    return @new_subfields;
}


=head2 _decorate_260

Add punctuation to MARC field 260. The function assumes that it is only
called if no punctuation is part of the record.

=cut

sub _decorate_260 {

    my ($field) = @_;

    # simple chars _preceeding_ a subfield
    my %pchrs = (

        # 'a' => ' ; ',   # only for multiple $a
        'b' => ' : ',
        'c' => ', ',

        # 'f' => ' : ',
        # 'g' => ',  ',
        'r' => ' = ',
        't' => ' = ',
    );

    # simple chars _appended_ to a subfield
    my %achars = (
        '3' => ': ',
    );

    my $lastsf        = '';
    my @new_subfields = ();

    foreach my $subfield ( $field->subfields() ) {
        my ( $sf, $value ) = @$subfield;

        if ( defined $value ) {

            if ( ( $sf eq 'a' ) and ( $lastsf eq 'a' ) ) {
                $value = ";  $value";
            }
            if ( ( $sf eq 'a' ) and ( $lastsf eq 'b' ) ) {
                $value = " ; $value";
            }

            # for $e: assume that we always have either $f or $g
            if ( $sf eq 'e' ) {
                $value = " ($value ";
            }

            if ( $sf eq 'f' ) {
                if ( $lastsf eq 'e' ) {
                    $value = " : $value";
                } else {
                    $value = " ($value";
                }
            }

            if ( $sf eq 'g' ) {
                if ( $lastsf ne 'f' ) {
                    $value = ", ($value)";
                } else {
                    $value = ", $value)";
                }
            }

            $lastsf = $sf;

            if ( $sf eq 'q' ) {
                $value = "($value)";
            }

            if ( exists $pchrs{$sf} ) {
                $value = $pchrs{$sf} . $value;
            }

            # FIXME something seems wrong here, however $3 is
            # not used by Koha
            # if ( exists $achrs{$sf} ) {
            #     $value = $value . $achrs{$sf};
            # }

            push( @new_subfields, $sf, $value );
        }
    }
    return @new_subfields;
}


sub filter {
    my ( $self, $record ) = @_;

    return $record unless defined $record and ref($record) eq 'MARC::Record';

    my $leader = $record->leader();

    # Add automatic punctuation only if the record requests it
    my $punctuation_omitted =
        ( ( substr( $leader, 18, 1 ) eq 'c' ) or ( substr( $leader, 18, 1 ) eq 'n' ) );

    if ($punctuation_omitted) {
        my @new_subfields = ();
        foreach my $field ( $record->fields ) {
            @new_subfields = ();

            # Process the implemented filters

            # 24x - Title fields
            if ( $field->tag() eq "245" ) {
                @new_subfields = _decorate_245($field);
            }

            if (   ( $field->tag() eq "246" )
                or ( $field->tag() eq "247" ) )
            {
                @new_subfields = _decorate_246_247($field);
            }

            # 260 – Publication, Distribution, etc. (Imprint)
            if ( $field->tag() eq '260' ) {
                @new_subfields = _decorate_260($field);
            }

            # 264 – Production, Publication, Distribution, Manufacture, and Copyright Notice
            # 264 is similar to 260, but does not hold some subfields
            if ( $field->tag() eq '264' ) {
                @new_subfields = _decorate_260($field);
            }

            # If filtered, replace the field content
            if (@new_subfields) {
                $field->replace_with(
                    MARC::Field->new(
                        $field->tag(),
                        $field->indicator(1),
                        $field->indicator(2),
                        @new_subfields
                    )
                );
            }
        }
    }
    return $record;
}

1;
