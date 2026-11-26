package Koha::Plugin::HKS3::ISBD4MARCPunctuation;

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

use CGI;
use JSON qw( decode_json encode_json );
use URI::Escape qw( uri_escape_utf8 );

use Koha::Filter::MARC::ISBD4MARCPunctuation
  qw( ATTACH_MODES DEFAULT_ATTACH_MODE DEFAULT_RULESET is_valid_attach_mode rulesets ruleset_label );

our $VERSION = "0.04";

our $metadata = {
    name   => 'ISBD4MARC Punctuation',
    author =>
      'Alexander Wagner (j2k), Mark Hofstetter (HKS3), DESY Assistant AI',
    description     => 'Add ISBD punctuation during XSLT display processing',
    namespace       => 'isbd4marcpunctuation',
    date_authored   => '2026-02-06',
    date_updated    => '2026-11-26',
    minimum_version => '23.11',
    maximum_version => undef,
    version         => $VERSION,
};

# Keyboard labels for the attach modes; the engine owns the valid VALUES.
my %ATTACH_MODE_LABEL = (
    postfix => 'Postfix (append to the preceding subfield)',
    prefix  => 'Prefix (prepend to the following subfield)',
);

=head2 new

Loads the stored settings once into C<< $self->{config} >> for the settings screen.
The filter must NOT rely on this cache - it calls L</punctuation_config>, which
always reads the database.

=cut

sub new {
    my ( $class, $args ) = @_;

    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;

    my $self = $class->SUPER::new($args);
    $self->{config} = _decode_config( $self->retrieve_data( _config_key() ) );
    $self->{cgi}    = CGI->new();

    return $self;
}

=head2 xslt_record_processor_filters

Registers the ISBD4MARC Punctuation record processor with Koha's XSLT pipeline.

=cut

sub xslt_record_processor_filters {
    my ( $self, $params ) = @_;

    my $filters = $params->{filters} || [];
    push @$filters, 'ISBD4MARCPunctuation';

    return;
}

=head2 punctuation_config

    my $config = $plugin->punctuation_config;

Returns the effective settings as a hashref:

    { ruleset => 'LoC/PCC', attach_mode => 'postfix' }

The values are read from the database on EVERY call, not from the C<<
$self->{config} >> cache built in L</new>: the filter reaches the plugin through
Koha's cached plugin objects, and that cache is only invalidated when a plugin is
enabled or disabled - a settings change must take effect without that.

Every value is validated here, so a hand-edited or outdated row can never make the
filter die: an unknown rule set falls back to the default set, an unknown attach
mode to C<postfix>.

=cut

sub punctuation_config {
    my ($self) = @_;

    return _normalize_config( _decode_config( $self->retrieve_data( _config_key() ) ) );
}

=head2 configure

Settings screen: renders C<configure.tt> on GET, stores the posted values on POST
and answers every POST with a redirect, so a reload cannot re-save.

=cut

sub configure {
    my ($self) = @_;
    my $cgi = $self->{cgi};

    if ( $cgi->param('save') ) {
        $self->store_config( $cgi->param('ruleset'), $cgi->param('attach_mode') );

        # saved=1 makes the next GET show the confirmation alert. Without it the
        # redirect lands on a page identical to the one just submitted and the
        # user cannot tell whether the save was accepted.
        print $cgi->redirect(
            -url => '/cgi-bin/koha/plugins/run.pl?class='
              . uri_escape_utf8(__PACKAGE__)
              . '&method=configure&saved=1'
        );
        exit;
    }

    my $config = _normalize_config( $self->{config} );

    my @sets = map { { id => $_, label => ruleset_label($_) } } rulesets();

    # Keep the engine's order (postfix first = default) but label each value.
    my @modes = map { { id => $_, label => $ATTACH_MODE_LABEL{$_} } } ATTACH_MODES;

    my $template = $self->get_template( { file => 'configure.tt' } );
    $template->param(
        config => $config,
        sets   => \@sets,
        modes  => \@modes,
        saved  => $cgi->param('saved') ? 1 : 0,
    );

    $self->output_html( $template->output() );
}

=head2 store_config

    $plugin->store_config( $ruleset, $attach_mode );

Validates the pair and stores it. The settings form is the only writer, so
invalid values are normalised to the defaults instead of being written raw.
Separate from L</configure> so the save path can be tested without the redirect
that ends the request.

=cut

sub store_config {
    my ( $self, $ruleset, $attach_mode ) = @_;

    my $config = _normalize_config(
        { ruleset => $ruleset, attach_mode => $attach_mode } );
    $self->store_data( { _config_key() => encode_json($config) } );

    return $config;
}

=head2 install

Seeds the settings with the defaults so the filter never has to guess.

=cut

sub install {
    my ($self) = @_;

    $self->store_data(
        { _config_key() => encode_json( _normalize_config( {} ) ) } );

    return 1;
}

=head2 upgrade

Keeps existing settings, back-fills keys missing from an older row.

=cut

sub upgrade {
    my ($self) = @_;

    $self->store_data(
        { _config_key() => encode_json( _normalize_config( $self->{config} ) ) } );

    return 1;
}

# Reserved plugin_data key holding the single JSON settings blob.
sub _config_key { return 'isbd_config'; }

# JSON blob -> hashref; anything unusable becomes an empty config.
sub _decode_config {
    my ($json) = @_;

    return {} unless defined $json and length $json;

    my $config = eval { decode_json($json) };
    return {} unless ref $config eq 'HASH';

    return $config;
}

# Fill in + validate: unknown values are replaced by the engine defaults.
sub _normalize_config {
    my ($config) = @_;
    $config ||= {};

    my $ruleset = $config->{ruleset};
    $ruleset = DEFAULT_RULESET
      unless defined $ruleset
      and grep { $_ eq $ruleset } rulesets();

    my $attach_mode = $config->{attach_mode};
    $attach_mode = DEFAULT_ATTACH_MODE
      unless is_valid_attach_mode($attach_mode);

    return { ruleset => $ruleset, attach_mode => $attach_mode };
}

1;
