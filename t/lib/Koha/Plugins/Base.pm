package Koha::Plugins::Base;

# Minimal mock for testing outside of Koha.
# Provides an in-memory plugin_data store (one hash per object) and stubs for
# the parts of the real base class a settings screen touches. Nothing here
# talks to a database, so tests run without a Koha installation.

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;

    my $self = bless {}, $class;
    $self->{_data} = {};
    $self->{_cgi}  = delete $args->{cgi} if $args;

    return $self;
}

# Real Koha stores into plugin_data; the mock just remembers per object.
sub store_data {
    my ( $self, $data ) = @_;

    $data ||= {};
    foreach my $key ( keys %{$data} ) {
        $self->{_data}->{$key} = $data->{$key};
    }

    return 1;
}

sub retrieve_data {
    my ( $self, $key ) = @_;
    return $self->{_data}->{$key};
}

# Seed the store directly (test helper, not part of the real base class).
sub mock_data {
    my ( $self, $data ) = @_;
    $self->{_data} = { %{$data || {}} };
    return $self->{_data};
}

sub get_template {
    my ( $self, $args ) = @_;

    # Return a stand-in object with the two methods configure() calls.
    return Koha::Plugins::Base::MockTemplate->new( $args->{file} );
}

sub output_html { return 1 }

package Koha::Plugins::Base::MockTemplate;

use strict;
use warnings;

sub new {
    my ( $class, $file ) = @_;
    return bless { file => $file, param => {} }, $class;
}

sub param {
    my ( $self, $key, $value ) = @_;
    $self->{param}->{$key} = $value if @_ > 2;
    return $self->{param}->{$key};
}

sub output { return '<mock template output>' }

1;
