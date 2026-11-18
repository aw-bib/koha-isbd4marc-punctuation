#
# Ensure the README "Implemented fields" list stays in sync with the
# active LoC/PCC rule set. This guards against the drift that happened
# after C1/C2 (README lagged 11 missing tags).
#
# The README list must contain EXACTLY the same MARC tags as the rule set,
# regardless of which codebase changed first (a new tag added to the rules
# without a README entry, OR a README entry that has no backing rule).

use strict;
use warnings;
use FindBin qw($RealBin);
use File::Spec;

use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);
my @rule_tags = sort { $a <=> $b } keys %$rules;

# Locate the README at the repo root (tests may be run from anywhere).
my $readme = File::Spec->catfile( $RealBin, '..', 'README.md' );
ok( -f $readme, "README.md found at $readme" )
    or BAIL_OUT( 'README.md not found next to the repo root' );

# Extract the MARC tags listed in the "Implemented fields:" section ONLY.
# Capturing is switched on by the "Implemented fields:" line and off by the
# first blank line or heading after it, so the helper cannot pick up a tag
# that is merely MENTIONED later in the README (e.g. the note that 249/532
# are D-A-CH-only, which must NOT count as LoC/PCC coverage).
open my $fh, '<', $readme or die "open $readme: $!";
my @readme_tags;
my $in_list = 0;
while ( my $line = <$fh> ) {
    if ( $line =~ /^Implemented fields:/ ) { $in_list = 1; next; }
    next unless $in_list;
    # Skip the blank line(s) between the heading and the first list item;
    # once the list has STARTED, a blank line ends it.
    if ( $line =~ /^\s*$/ ) {
        last if @readme_tags;
        next;
    }
    last if $line =~ /^#/;
    push @readme_tags, $1 if $line =~ /^- `(\d{3})`:/;
}
close $fh;
@readme_tags = sort { $a <=> $b } @readme_tags;

# One authoritative check: the README list equals the rule set, tag for tag.
# Catches BOTH a missing README entry (rule without doc) and a stray README
# entry (doc without rule). Human-friendly diagnostic below.
is_deeply( \@readme_tags, \@rule_tags,
    "README Implemented-fields list matches the $SET rule set (" . scalar(@rule_tags) . " tags)" );

# Scope guard: the capture must stop at the end of the list. The README
# mentions D-A-CH-only tags (249, 532) further down; if the capture leaked
# past the list, those would show up here and the equality above would fail
# for the WRONG reason. Pinning the absence keeps the diagnostic honest.
ok( !grep( { $_ eq '532' or $_ eq '249' } @readme_tags ),
    'README capture stops at the list end (no D-A-CH-only tags leaked in)' );

done_testing();
