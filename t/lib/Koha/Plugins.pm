package Koha::Plugins;

# Minimal mock for testing outside of Koha.
# Serves the plugin objects returned by Koha::Plugins::Loader, which the real
# Koha::Plugins wraps. Tests set the list via $Koha::Plugins::MOCK_PLUGINS
# (an arrayref of plugin objects); undef means "plugins unavailable".

our $MOCK_PLUGINS;

sub get_enabled_plugins {
    return () unless defined $MOCK_PLUGINS;
    return @{$MOCK_PLUGINS};
}

1;
