#!/bin/bash
# Compile-check the plugin templates with Template Toolkit itself.
#
# Usage: ./scripts/check_templates.sh
#
# Template syntax errors in a plugin's configure.tt stay invisible until an
# admin clicks Configure on a real server: the test suite does not render the
# template (its mock returns a stand-in string). This script compiles every .tt
# under Koha/Plugin/ with the real parser, so a broken TAG fails here instead of
# on the test server.
#
# Only EXTERNAL includes (Koha's shared intranet/html files) are stubbed - they
# are not in this repo. Compiling catches bad TAG syntax, unbalanced block
# directives, unknown directives and misused filters. It does NOT catch variables
# that are undefined at runtime; those render empty, as they would in Koha.

set -eu

cd "$(dirname "$0")/.." || exit 1

if ! perl -MTemplate -e 1 2>/dev/null; then
    echo "Template Toolkit not installed; cannot check templates." >&2
    echo "Install with: cpanm Template" >&2
    exit 1
fi

mapfile -t TEMPLATES < <(find Koha -name '*.tt' | sort)

if [ ${#TEMPLATES[@]} -eq 0 ]; then
    echo "No templates found under Koha/." >&2
    exit 1
fi

PERL5LIB=. perl - "${TEMPLATES[@]}" <<'PERL'
use strict;
use warnings;
use Template;
use Template::Provider;

# External includes that live in Koha, not here. Empty stubs so INCLUDE
# resolves; their content is irrelevant to a compile check. Keep this list in
# sync with the INCLUDE directives: csrf-token.inc supplies the CSRF token that
# Koha::Middleware::CSRF demands on every POST.
my @external = qw(
  doc-head-open.inc doc-head-close.inc header.inc cat-search.inc
  sub-header.inc intranet-bottom.inc breadcrumbs breadcrumb_item
  csrf-token.inc
);

my %stub = map { ( $_.'.tt' => 1, $_ => 1 ) } @external;

package StubProvider;
our @ISA = ('Template::Provider');

# Serve an empty body for the known Koha includes; decline anything else so the
# next provider in the chain reports a genuinely missing file. fetch() accepts a
# SCALAR reference as template text, which is all an include stub needs to be.
sub fetch {
    my ( $self, $name ) = @_;
    return ( undef, Template::Constants::STATUS_DECLINED ) if ref $name;

    ( my $base = $name ) =~ s{.*/}{};
    return ( undef, Template::Constants::STATUS_DECLINED )
      unless $stub{$name} || $stub{$base};

    my $text = \'';
    return $self->SUPER::fetch($text);
}

package main;

my $tt = Template->new(
    {
        LOAD_TEMPLATES => [ StubProvider->new( {} ), Template::Provider->new( {} ) ],
        PLUGINS        => { raw => 'Template::Plugin::Filter' },
        PRE_CHOMP      => 1,
        POST_CHOMP     => 1,
    }
);

my $failed = 0;
for my $file (@ARGV) {
    my $ok = $tt->process( $file, { dummy => 1 }, \my $out );
    if ($ok) {
        printf "ok   %s\n", $file;
    }
    else {
        $failed++;
        printf "FAIL %s\n     %s\n", $file, $tt->error;
    }
}

if ($failed) {
    print "\n$failed template(s) failed to compile.\n";
    exit 1;
}
print "\nAll templates compile.\n";
PERL
