package Koha::Plugin::HKS3::TestPunctuation;

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
use base qw(Koha::Plugins::Base);

our $VERSION = "0.01";

our $metadata = {
    name            => 'Test Punctuation',
    author          => 'HKS3 - Mark Hofstetter',
    description     => 'Test punctuation filter hook for XSLT display',
    namespace       => 'testpunctuation',
    date_authored   => '2026-02-06',
    date_updated    => '2026-02-06',
    minimum_version => '23.11',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;

    my $self = $class->SUPER::new($args);
    $self->{cgi} = CGI->new();

    return $self;
}

sub xslt_record_processor_filters {
    my ( $self, $params ) = @_;

    my $filters = $params->{filters} || [];
    push @$filters, 'TestPunctuation';

    return;
}

1;
