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

sub filter {
    my ( $self, $record ) = @_;

    return $record unless defined $record and ref($record) eq 'MARC::Record';

    for my $field ( $record->field('245') ) {
        my @subfields = ();
        for my $subfield ( $field->subfields() ) {
            my ( $code, $value ) = @$subfield;
            if ( $code eq 'a' && defined $value ) {
                $value =~ s/\s+$//;
                $value .= '.' unless $value =~ /[\.,;:\/?!]$/;
            }
            push @subfields, $code, $value;
        }
        $field->replace_with(
            MARC::Field->new(
                $field->tag,
                $field->indicator(1),
                $field->indicator(2),
                @subfields
            )
        );
    }

    return $record;
}

1;
