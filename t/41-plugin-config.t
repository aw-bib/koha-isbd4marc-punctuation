#!/usr/bin/perl
#
# Plugin configuration: storage, validation and the route from the settings
# screen to the filter's behaviour.
#
# The Koha plugin infrastructure is mocked (t/lib/Koha/Plugins/Base.pm and
# t/lib/Koha/Plugins.pm), so this file needs no Koha installation and no database.

use strict;
use warnings;

use lib 't/lib';
use Koha::RecordProcessor::Base;
use Koha::Plugins::Base;

use Test::More;
use MARC::Record;
use JSON qw( encode_json );

use Koha::Filter::MARC::ISBD4MARCPunctuation;
use Koha::Plugin::HKS3::ISBD4MARCPunctuation;

my $CLASS = 'Koha::Plugin::HKS3::ISBD4MARCPunctuation';

# --- Engine contract: one source of truth for the valid attach modes ---

is_deeply(
    [ Koha::Filter::MARC::ISBD4MARCPunctuation::ATTACH_MODES ],
    [ 'postfix', 'prefix' ],
    'engine: ATTACH_MODES lists postfix first (the default), then prefix'
);

is( Koha::Filter::MARC::ISBD4MARCPunctuation::DEFAULT_ATTACH_MODE, 'postfix',
    'engine: default attach mode is postfix' );

ok( Koha::Filter::MARC::ISBD4MARCPunctuation::is_valid_attach_mode('prefix'),
    'engine: prefix is a valid attach mode' );
ok( !Koha::Filter::MARC::ISBD4MARCPunctuation::is_valid_attach_mode('sideways'),
    'engine: an unknown attach mode is rejected' );
ok( !Koha::Filter::MARC::ISBD4MARCPunctuation::is_valid_attach_mode(undef),
    'engine: undef is not a valid attach mode' );

# --- installment/first run: the plugin seeds usable defaults ---

{
    my $plugin = $CLASS->new( {} );
    $plugin->install();
    my $stored = $plugin->retrieve_data('isbd_config');
    is_deeply(
        JSON::decode_json($stored),
        { ruleset => 'LoC/PCC', attach_mode => 'postfix' },
        'install: seeds the default rule set and attach mode'
    );
}

# --- punctuation_config: valid values are returned as stored ---

{
    my $plugin = $CLASS->new( {} );
    $plugin->mock_data( { isbd_config => encode_json( { ruleset => 'DACH', attach_mode => 'prefix' } ) } );
    is_deeply(
        $plugin->punctuation_config,
        { ruleset => 'DACH', attach_mode => 'prefix' },
        'punctuation_config: returns a stored valid pair unchanged'
    );
}

# --- punctuation_config: garbage falls back to the defaults ---

{
    my $plugin = $CLASS->new( {} );
    $plugin->mock_data(
        { isbd_config =>
              encode_json( { ruleset => 'NoSuchSet', attach_mode => 'sideways' } ) } );
    is_deeply(
        $plugin->punctuation_config,
        { ruleset => 'LoC/PCC', attach_mode => 'postfix' },
        'punctuation_config: unknown ruleset and mode fall back to the defaults'
    );
}

# --- punctuation_config: unreadable/absent data never dies ---

{
    my $plugin = $CLASS->new( {} );
    is_deeply(
        $plugin->punctuation_config,
        { ruleset => 'LoC/PCC', attach_mode => 'postfix' },
        'punctuation_config: no stored settings -> defaults'
    );

    $plugin->mock_data( { isbd_config => 'this is not json' } );
    is_deeply(
        $plugin->punctuation_config,
        { ruleset => 'LoC/PCC', attach_mode => 'postfix' },
        'punctuation_config: broken JSON -> defaults, no exception'
    );
}

# --- the filter asks the plugin: configured values change the output ---

sub _leader_with {
    my ($pos18) = @_;
    my $leader = '00000naa a2200000   4500';
    substr( $leader, 18, 1, $pos18 );
    return $leader;
}

sub _filtered_field {
    my ( $mode, $tag, @subfields ) = @_;
    $tag ||= '245';
    my $record = MARC::Record->new;
    $record->leader( _leader_with('c') );
    $record->add_fields( $tag, ( $tag eq '245' ? ( '0', '0' ) : ( '1', '' ) ),
        @subfields );
    my $filter = Koha::Filter::MARC::ISBD4MARCPunctuation->new;

    # Forward the argument only when the caller passed one: `filter($record, undef)`
    # is a defined argument and must count as "explicitly given" in the precedence.
    if ( defined $mode ) {
        $filter->filter( $record, $mode );
    }
    else {
        $filter->filter($record);
    }

    return $record->field($tag);
}

sub _enable_plugin {
    my ( $ruleset, $attach_mode ) = @_;
    my $plugin = $CLASS->new( {} );
    $plugin->mock_data(
        { isbd_config =>
              encode_json( { ruleset => $ruleset, attach_mode => $attach_mode } ) } );

    # Replace the object the filter sees for the REST OF THE FILE: a `local` here
    # would be undone on return, and the filter would never see the plugin.
    no warnings 'once';
    $Koha::Plugins::MOCK_PLUGINS = [$plugin];
    return $plugin;
}

# No plugin: built-in behaviour (LoC/PCC, postfix = punctuation appended to the
# PRECEDING subfield, i.e. `$a` ends with ' : ').
{
    no warnings 'once';
    $Koha::Plugins::MOCK_PLUGINS = undef;
    my $field = _filtered_field( undef, '245', a => 'A title', b => 'a subtitle' );
    is( $field->subfield('a'), 'A title : ',
        'filter: no plugin -> default LoC/PCC postfix behaviour' );
}

# Configured attach mode applies when filter() is called without an argument.
{
    _enable_plugin( 'LoC/PCC', 'prefix' );
    my $field = _filtered_field( undef, '245', a => 'A title', b => 'a subtitle' );
    is( $field->subfield('a'), 'A title',
        'filter: configured prefix mode leaves $a clean' );
    is( $field->subfield('b'), ' : a subtitle',
        'filter: configured prefix mode prepends to $b' );
}

# An explicit argument wins over the configured value.
{
    _enable_plugin( 'LoC/PCC', 'prefix' );
    my $field = _filtered_field( 'postfix', '245', a => 'A title', b => 'a subtitle' );
    is( $field->subfield('a'), 'A title : ',
        'filter: explicit postfix argument overrides configured prefix' );
    is( $field->subfield('b'), 'a subtitle',
        'filter: explicit postfix argument leaves $b undecorated' );
}

# --- the configured RULE SET is what gets applied ---
# 100 $n is '.' + space in LoC/PCC but ',' + space in D-A-CH, so the rendered
# $a tells the two sets apart (postfix mode: the separator lands on the value
# BEFORE the triggering subfield).
{
    no warnings 'once';
    $Koha::Plugins::MOCK_PLUGINS = undef;
    my $loc = _filtered_field( undef, '100', a => 'Doe, John', n => '1' );
    is( $loc->subfield('a'), 'Doe, John. ',
        'filter: default LoC/PCC set separates 100 $a from $n with ". "' );

    _enable_plugin( 'DACH', 'postfix' );
    my $dach = _filtered_field( undef, '100', a => 'Doe, John', n => '1' );
    is( $dach->subfield('a'), 'Doe, John, ',
        'filter: configured D-A-CH set separates 100 $a from $n with ", "' );
}

# --- storage path used by the settings screen: validate, then store ---

{
    # configure() ends with `print $redirect; exit;`. The `exit` makes it
    # untestable in-process, so the plugin offers the save step as a separate
    # method that configure() itself uses - the test drives that method, which
    # keeps the assertion on the REAL validation + storage path.
    my $plugin = $CLASS->new( {} );
    $plugin->store_config( 'NoSuchSet', 'sideways' );
    is_deeply(
        JSON::decode_json( $plugin->retrieve_data('isbd_config') ),
        { ruleset => 'LoC/PCC', attach_mode => 'postfix' },
        'store_config: an invalid pair is stored as the defaults, never raw'
    );

    $plugin->store_config( 'DACH', 'prefix' );
    is_deeply(
        JSON::decode_json( $plugin->retrieve_data('isbd_config') ),
        { ruleset => 'DACH', attach_mode => 'prefix' },
        'store_config: a valid pair is stored as given'
    );
}

# --- the settings form must be a POST that carries Koha's CSRF token ---
#
# Koha::Middleware::CSRF rejects every POST without a csrf_token parameter
# (403 "No CSRF token passed"), which is what happened on the first real
# install. The token comes from that include only; a template that forgets it
# compiles fine and fails only when someone clicks Save on a live server.

{
    my $template_file =
      'Koha/Plugin/HKS3/ISBD4MARCPunctuation/configure.tt';
    open my $fh, '<', $template_file
      or plan skip_all => "cannot read $template_file: $!";
    local $/;
    my $tt = <$fh>;
    close $fh;

    like( $tt, qr/<form[^>]*method="post"/,
        'configure.tt: the settings form uses POST' );
    like( $tt, qr/INCLUDE 'csrf-token\.inc'/,
        'configure.tt: the form includes csrf-token.inc, so Koha::Middleware::CSRF accepts the POST'
    );
    unlike( $tt, qr/name="csrf_token"/,
        'configure.tt: the token is not hand-written (the include generates it)'
    );
}

done_testing();
