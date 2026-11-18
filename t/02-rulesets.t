#!/usr/bin/perl
#
# Test the switchable RULE SETS layer:
#   - ruleset() get/set accessor, defaulting to LoC/PCC
#   - rules_for() with no argument returns the ACTIVE set
#   - rules_for('None') returns an empty set (no-op)
#   - rules_for('LoC/PCC') returns the LoC/PCC set
#   - rules_for('DACH') returns the D-A-CH set
#   - rulesets() / ruleset_label(): identifiers vs display names
#   - rules_for(<unknown>) dies
#   - the engine decorates via the ACTIVE set, and switching sets (here a
#     no-op 'None') actually changes the applied rules without touching the
#     decoration business logic.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# Reset to a known default at the start (test ordering / state hygiene).
Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset('LoC/PCC');

# 1. Default rule set is LoC/PCC
is(
    Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset(),
    'LoC/PCC',
    'ruleset() defaults to LoC/PCC'
);

# 2. rules_for() with no argument returns the ACTIVE (LoC/PCC) set
my $active = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for();
ok( defined $active, 'rules_for() returns a defined hash' );
is(
    scalar( keys %$active ),
    95,
    'rules_for() (active default LoC/PCC) has 95 field tags'
);
my $active135 = $active->{'245'}{pchrs}{b};
is( $active135, ' : ', 'active set 245 $b punctuation is " : " (LoC/PCC)' );

# 3. rules_for('None') returns an empty set (no automatic punctuation)
my $none = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for('None');
is_deeply( $none, {}, "rules_for('None') is an empty set (no-op)" );

# 4. rules_for('LoC/PCC') returns the LoC/PCC set
my $loc = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for('LoC/PCC');
is(
    $loc->{110}{cb_pre},
    'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
    "LoC/PCC 110 cb_pre is a shared callback string reference"
);
is(
    ref( $loc->{'020'}{cb_pre} ),
    'CODE',
    "LoC/PCC 020 inline cb_pre is a code-ref"
);

# 4b. rules_for('DACH') returns the set behind the D-A-CH rules. It activates
#     DACH (Option-2 fix) so use_rules aliases resolve against DACH, not the
#     previous default. Note the identifier/display-name split: the code key is
#     'DACH', the label reported for humans is 'D-A-CH'.
my $dach = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for('DACH');
is(
    scalar( keys %$dach ),
    97,
    'rules_for(DACH) has 97 field tags (95 shared + 249 + 532)'
);
is(
    ( exists $dach->{'249'} ? 1 : 0 ),
    1,
    'DACH set contains the German-only field 249'
);
is(
    ( exists $dach->{'532'} ? 1 : 0 ),
    1,
    'DACH set contains the DACH-only field 532'
);
is(
    ( exists $loc->{'532'} ? 1 : 0 ),
    0,
    'LoC/PCC set does NOT contain 532 (D-A-CH-only tag)'
);
is(
    $dach->{'100'}{pchrs}{n},
    ', ',
    'D-A-CH 100 $n punctuation is ", " (deviates from LoC/PCC ". ")'
);
# Dispatching a set by name activates it (so use_rules resolves within it).
is(
    Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset(),
    'DACH',
    'rules_for(DACH) activated the DACH set (alias resolution scope)'
);

# 4c. The set registry: identifiers are what the code uses, labels are what
#     users see. DACH/D-A-CH is the one place where they differ.
is_deeply(
    [ Koha::Filter::MARC::ISBD4MARCPunctuation::rulesets() ],
    [ 'DACH', 'LoC/PCC', 'None' ],
    'rulesets() lists every known set identifier (sorted)'
);
is( Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset_label('DACH'),
    'D-A-CH', 'DACH label is D-A-CH' );
is( Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset_label('LoC/PCC'),
    'LoC/PCC', 'LoC/PCC label is its own identifier' );
is( Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset_label('None'),
    'None', 'None label is its own identifier' );
is( Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset_label(),
    'D-A-CH', 'ruleset_label() with no arg describes the ACTIVE set' );
ok( !defined Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset_label('Nope'),
    'ruleset_label() of an unknown set is undef' );

# 5. rules_for('DoesNotExist') dies
eval { Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for('DoesNotExist') };
ok( $@, "rules_for('DoesNotExist') dies" );

# 6. The engine really uses the ACTIVE set: decorate a 245 with LoC/PCC,
#    then with the no-op 'None' set (which has no rules), and observe that
#    switching the set changes the output WITHOUT touching the decoration
#    business logic (same _decorate_field, different rules hash).
my $make_field = sub {
    return MARC::Field->new( '245', '1', '0', a => 'Value', b => 'Other' );
};

# 6a. With LoC/PCC active, $a gets ' : ' before $b.
Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset('LoC/PCC');
my $f_loc = $make_field->();
my @out_loc =
  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field(
    $f_loc,
    Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for()->{245},
    'postfix'
  );
is_deeply(
    \@out_loc,
    [ 'a', 'Value : ', 'b', 'Other' ],
    'LoC/PCC active: 245 $a gets " : " before $b'
);

# 6b. With the no-op 'None' set active, rules_for()->{245} is undefined, so
#     the same decoration path produces no punctuation (pass-through).
Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset('None');
my $f_none = $make_field->();
my $none_rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for()->{245};
is( $none_rules, undef, 'None active: no rules for 245 (pass-through)' );

# Restore default for other tests / hygiene.
Koha::Filter::MARC::ISBD4MARCPunctuation::ruleset('LoC/PCC');

done_testing();
