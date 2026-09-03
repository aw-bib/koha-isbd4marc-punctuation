package Koha::Filter::MARC::ISBD4MARCPunctuation;

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

use Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::LoCPCC;

our $NAME    = 'ISBD4MARCPunctuation';
our $VERSION = '0.02';

=head1 NAME

Koha::Filter::MARC::ISBD4MARCPunctuation - Automatically add ISBD punctuation
to MARC21 records if the leader specifies they were catalogued without it.


=head1 DESCRIPTION

If the MARC leader byte 18 specifies that the record was catalogued
without punctuation (values C<n> or C<c>), this filter injects the
proper ISBD punctuation into the individual fields before passing the
record on to further processing. The records in the database are I<not>
changed.

The punctuation rules are defined in one or more I<rule sets> (see
C<RuleSet>::*), and the core loop in C<_decorate_field> handles them
generically. The active rule set is selected via C<ruleset()> /
C<rules_for()> and defaults to C<LoC/PCC>. Adding support for a new field
is as simple as adding an entry to the active rule set; adding a new
catalogue tradition is a new C<RuleSet>::* module.

=cut

=head1 PUNCTUATION RULES

Each rule hash supports the following keys:

=over

=item C<pchrs>

Hashref of preceding characters. Key is the I<next> subfield tag,
value is the punctuation to append to the I<current> subfield.
E.g. C<< { b => ' : ' } >> means "if the next subfield is C,
append ' : ' to the current subfield."

=item C<post>

Hashref of always-appended suffixes. The value is appended to the
current subfield after all other processing. E.g. C<< { 3 => ': ' } >>

=item C<wrap>

Hashref of wrapping pairs. Key is the subfield tag, value is an
arrayref of C<[prefix, suffix]>. E.g. C<< { h => [ '[', ']' ] } >>
wraps C content in square brackets.

=item C<cb_pre>

Optional callback run I<before> wrapping and look-ahead logic.
Receives C<< ($sf, $value, $i, \@subfields, \$last_sf) >>.
Use this for grouping logic (e.g. C in 260).
Must return the (possibly modified) value.

The value may be a code-ref (an inline closure owned by the rule set) or
a I<method-name string> referring to a shared callback on this package
(resolved via C<can()> in C<_resolve_cb>).

=item C<cb_post>

Optional callback run I<after> wrapping but I<before> look-ahead.
Same signature as C<cb_pre>.

=item C<use_rules>

Alias to another tag's rules. Only one level of indirection is
resolved. E.g. C<< { use_rules => 246 } >> means "use the same
rules as field 246." The alias is resolved within the active rule set.

=back

=cut

=head1 RULE SETS

The plugin supports a pluggable set of punctuation rule sets, one module
under C<RuleSet/> per catalogue tradition. Only one is active at a time;
records are always decorated with the active set's rules.

=over

=item C<ruleset>

The name of the active rule set. Defaults to C<LoC/PCC>. Accepts an
optional argument to set a new value (returns the new name).

=item C<rules_for>

Loads the full rules hash for a named set. Pass C<None> to get an
empty hash (a no-op "no automatic punctuation" set). With no argument,
returns the I<active> set's rules.

=back

=cut

use constant DEFAULT_RULESET => 'LoC/PCC';

# Name of the currently selected rule set. For the moment this is a
# package-level default; a per-plugin-instance override can be layered on
# later (e.g. via the plugin configuration) without changing the engine.
my $ACTIVE_RULESET = DEFAULT_RULESET;

sub ruleset {
    my $set = shift;
    if ( defined $set ) { $ACTIVE_RULESET = $set; }
    return $ACTIVE_RULESET;
}

sub rules_for {
    my $set = shift;
    $set = ruleset() unless defined $set;

    if ( $set eq 'None' ) {
        return {};
    }

    if ( $set eq 'LoC/PCC' ) {
        return
          Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::LoCPCC::rules();
    }

    die "Unknown rule set '$set'\n";
}

=head2 _resolve_cb

Resolve a callback reference from a rule entry. A code-ref is returned
as-is; a string is treated as a fully-qualified method name on this
package and resolved via C<can()>. Returns undef if the string does not
name an existing subroutine.

=cut

sub _resolve_cb {
    my ($cb) = @_;
    return $cb if ref($cb) eq 'CODE';
    return unless defined $cb;
    my $code = __PACKAGE__->can($cb);
    return $code;
}

=head2 _decorate_field

Generic field decorator. Takes a MARC::Field object, a rules
hashref (as returned by C<rules_for>), and an optional attachment mode
(C<'postfix'> or C<'prefix'>). Returns a list of subfield
key/value pairs suitable for constructing a new field.

In C<'postfix'> mode (default), punctuation is appended to the
I<current> subfield (look-ahead). In C<'prefix'> mode, punctuation
is prepended to the I<next> subfield (look-behind), which prevents
orphaned punctuation when subfields like C<245 $c> are not displayed.

=cut

sub _decorate_field {
    my ( $field, $rules, $attach_mode ) = @_;
    $attach_mode //= 'postfix';

    # Resolve use_rules alias within the active rule set (single level)
    if ( my $alias = $rules->{use_rules} ) {
        $rules = rules_for()->{$alias};
    }

    my @subfields     = $field->subfields;
    my @new_subfields = ();
    my $last_sf       = '';
    my $pending       = '';

    for my $i ( 0 .. $#subfields ) {
        my ( $sf, $value ) = @{ $subfields[$i] };
        next unless defined $value;
        $value =~ s/\s+$//;

        # 0) Prefix mode: prepend pending punctuation from previous subfield
        if ( $attach_mode eq 'prefix' && $pending ) {
            $value   = $pending . $value;
            $pending = '';
        }

        # 1) Pre-callback (for complex grouping / prefixing)
        if ( my $cb = _resolve_cb( $rules->{cb_pre} ) ) {
            $value = $cb->( $sf, $value, $i, \@subfields, \$last_sf );
        }

        # 2) Wrap (brackets / parentheses)
        if ( my $wrap = $rules->{wrap}{$sf} ) {
            $value = $wrap->[0] . $value . $wrap->[1];
        }

        # 3) Post-callback
        if ( my $cb = _resolve_cb( $rules->{cb_post} ) ) {
            $value = $cb->( $sf, $value, $i, \@subfields, \$last_sf );
        }

        # 4) Punctuation attachment based on mode
        # Look up punctuation by COMPOUND key (sf . next_sf) first, falling
        # back to the single key (next_sf).
        my $next = $subfields[ $i + 1 ];
        if ( defined $next ) {
            my ($next_sf) = @$next;
            my $compound = $sf . $next_sf;
            my $punct;
            if ( exists $rules->{pchrs}{$compound} ) {
                $punct = $rules->{pchrs}{$compound};
            }
            elsif ( exists $rules->{pchrs}{$next_sf} ) {
                $punct = $rules->{pchrs}{$next_sf};
            }
            if ( defined $punct ) {
                if ( $attach_mode eq 'prefix' ) {
                    $pending = $punct;
                }
                else {
                    $value .= $punct;
                }
            }
        }

        # 5) Always-append suffix
        if ( exists $rules->{post}{$sf} ) {
            $value .= $rules->{post}{$sf};
        }

        push @new_subfields, $sf, $value;
        $last_sf = $sf;
    }
    return @new_subfields;
}

=head2 _decorate_260_pre

Pre-callback for field 260. Handles the parenthetical grouping of
C<(producer)>, C<(producer place)> and C<(production date)>/C
which form the C<($e : $f , $g)> group together.

The  C< ; > separators between repeated C and after C
are provided declaratively by the COMPOUND C<pchrs aa/ba keys> in step 4.
This callback handles only the group's parentheses.

=cut

sub _decorate_260_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
    my $last_sf = $$last_sf_ref;

   # $e/$f/$g grouping: open parenthetical
   #
   # KNOWN GAPS:
   #  - Double SPACE: $e emits a trailing space (" ($value ") and $f/$g emit a
   #    leading space, so clean data yields "(Twickenham  : CTD Printers" (two
   #    spaces before ':'). Not fixed — clean-up is risky and low-value.
   #  - Messy records where the cataloguer already typed '(' in $e / ')' in $f/g
   #    (e.g. glued "1974-(Oak") produce a DOUBLE '('. Data-dependent; cannot be
   #    uniquely decoded, left for cataloguers (leader/18).
    if ( $sf eq 'e' ) {
        $value = " ($value ";
    }
    if ( $sf eq 'f' ) {
        if ( $last_sf eq 'e' ) {
            $value = " : $value";
        }
        else {
            $value = " ($value";
        }
    }
    if ( $sf eq 'g' ) {
        if ( $last_sf ne 'f' ) {
            $value = ", ($value)";
        }
        else {
            $value = ", $value)";
        }
    }

    return $value;
}

=head2 _decorate_x10_pre

Pre-callback for the corporate/meeting-name fields (110/610/710/810 and
111/611/711/811). Groups a MEETING run of C (number), C (date) and
C (location) into a single pair of parentheses, e.g.

    $d 1857 $c Waco, Tex.  ->  (1857 : Waco, Tex.)

This mirrors I<enclose_in_parentheses(datafield, 'n', 'd', 'c')>.
The internal C<' : '> / C<'; '> separators are supplied by
the compound pchrs keys C<nd>/C<dc>/C<cc> in step 4 of C<_decorate_field>.

A leading space is added before the opening paren when the group is preceded
by other content (e.g. C).

=head3 AMBIGUITY DECISION (2026-08-31) — $n (and $d/$c) in the title portion

$n/$d/$c are ambiguous in the corporate/meeting family: they are the MEETING
number/date/location in the NAME portion (grouped as $n : $d : $c) AND
part/date elements in the spec §5.5 TITLE portion (e.g. the Ecuador 710
example: $t ... $n Parte 1 $p ... $l ...). A broad rule could not tell them
apart, and a single pchrs key on $n would over-fire on the meeting group.

Decision: a run of n/d/c is the parenthetical MEETING group unless it
sits in the TITLE portion — i.e. the run starts immediately after a
C subfield. A n/d/c that starts right after $t is a §5.5 title element and
is left PLAIN so the title punctuation (e.g. $t followed by $n, via the
compound pchrs key C<tn>) applies instead of parens.
Consequences:
  - the Ecuador title $n is correctly un-parenthesized;
  - a meeting run always starts in the name portion (after $a/$b/$g/...), so
    all normal meeting groups are preserved, including those that start with
    $d or $c alone (no $n), and lone meeting numbers;
  - a title run like $t $n $d (a title part plus a date) would be treated as
    title/plain and not grouped — that matches §5.5 but differs from a meeting
    reading. Accepted for now; revisit if real records show a need.
If this gets revisited, revisit BOTH the grouping here and the title-portation
(§5.5) interplay.

=cut

sub _decorate_x10_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
    my $last_sf = $$last_sf_ref;

    # Meeting-group subfields.
    my %group_sf = map { $_ => 1 } qw(n d c);

    # Not an n/d/c meeting-group subfield — leave untouched.
    return $value unless $group_sf{$sf};

    my $next    = $subfields->[ $i + 1 ];
    my $next_sf = $next ? $next->[0] : '';

    # A run of n/d/c that starts immediately after $t is in the §5.5 TITLE
    # portion (e.g. $t ... $n Parte 1...) — leave it PLAIN (no parens).
    my $is_run_start = !$group_sf{$last_sf};
    if ( $is_run_start && $last_sf eq 't' ) {
        return $value;
    }

    my $is_first = !$group_sf{$last_sf};
    my $is_last  = ( !defined $next_sf || !$group_sf{$next_sf} );

    if ($is_first) {

        # Leading space unless this is the very first subfield of the field
        my $lead = ( defined $last_sf && length $last_sf ) ? ' ' : '';
        $value = $lead . '(' . $value;
    }
    if ($is_last) {
        $value .= ')';
    }

    return $value;
}

=head2 _decorate_qualifier_group_pre

I<Shared> pre-callback + helper for a REPEATABLE I<qualifying> subfield that
is wrapped in a single pair of parentheses, with multiple occurrences
separated by a per-field separator. This is the pattern used by:

    020 $q  (separator " ; ")
    210 $b  (separator ", ")
    222 $b  (separator ". ")

Example (020, $code q, $sep " ; "):

    $a 0914378260 $q pbk. $q v. 1  ->  (pbk. ; v. 1)

Because the separator differs per field, the rule set passes it in; the data
files therefore reference this helper via small closures that supply
C<$code> and C<$sep>. A naive C E<lt> wrap => { b => ['(',')'] } E<gt> would
instead produce C<(a)(b)>, not C<(a, b)>, so this grouping is structural
and lives in C<cb_pre> (the parens/separator are attached to the run as a
unit), matching the 020/210/222 reference reading.

Non-group subfields pass through unchanged; a single occurrence is wrapped
entirely (C<(...)>); the first/middle/last of a run open the paren, add only
the separator, or add the separator and close the paren, respectively.

Called with the standard C<cb_pre> signature followed by C<$code> (the group
subfield's code) and C<$sep> (the run-internal separator).

=cut

=head2 _decorate_300_pre

Pre-callback for field 300 (Physical Description). Groups the
accompanying-material DETAIL run of C (extent of accompanying material),
C (other physical details) and C (dimensions of accompanying material)
into a single pair of parentheses, mirroring the I<enclose_in_parentheses>
grouping used by the x10/x11 meeting run. E.g. (doc example 6):

    $e 1 atlas $h 37 pages, 19 leaves $i color maps $j 37 cm
      ->  1 atlas (37 pages, 19 leaves : color maps ; 37 cm)

Per spec §4.14 the group is only anchored at C: C is
"((((" and C/C are "(( or prev :/; " respectively. The internal
C<' : '>/C<'; '> separators are supplied by the compound pchrs keys
C<hi>/C<ij>/C<hj> in step 4 of C<_decorate_field> (same mechanism as the
x10 C<nd>/C<dc>/C<cc> keys).

=head3 AMBIGUITY DECISION (2026-09-02) — lone $i / $j (no $h)

§4.14 gives C and C an "or": enclosing parens C<(( ))> I<or> a preceding
space-colon/space-semicolon. That is decodable while a C anchors the run
(C<hh> present -> the in-run separator applies). But a C or C that
appears I<without> a preceding C is the genuinely ambiguous case: the spec
would wrap it in its own parens, yet we have no example and it is a
cataloguer judgment call. Per agreement, a group run may only open at
C; a lone C/C (run not started by C) is left without
parentheses and is a documented gap for cataloguers (via leader/18).

NOTE (2026-09-02, Option A): a lone C/C still gets a bare C<' ; '>
from the C<ij>/C<hj> compound pchrs keys when adjacent to another
C/C (the engine's step 4 fires on C<sf.next_sf> regardless of whether
C anchors the run). There is I<no> real-world test case for a lone
C/C yet (the spec example always has C), so this behaviour is
accepted provisionally and may need revision by an ISBD expert.

A leading space is added before the opening paren when the group is
preceded by other content (e.g. C<$e 1 atlas (>: the space after
"atlas").

=cut

sub _decorate_300_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
    my $last_sf = $$last_sf_ref;

    # Accompanying-material detail group subfields.
    my %group_sf = map { $_ => 1 } qw(h i j);

    # Not an h/i/j group subfield — leave untouched.
    return $value unless $group_sf{$sf};

    # Determine the start of the contiguous group run by scanning back.
    my $run_start = $sf;
    for ( my $k = $i - 1; $k >= 0; $k-- ) {
        my $prev = $subfields->[$k][0];
        last unless $group_sf{$prev};
        $run_start = $prev;
    }

    # A run may ONLY open at $h. A lone $i/$j (no leading $h) is the §4.14
    # "or" case — not mechanically decodable; leave the whole run untouched
    # (documented gap, cataloguer decides via leader/18).
    return $value unless $run_start eq 'h';

    my $next    = $subfields->[ $i + 1 ];
    my $next_sf = $next ? $next->[0] : '';

    my $is_first = ( $i == 0 || !$group_sf{ $subfields->[ $i - 1 ][0] } );
    my $is_last  = ( !defined $next_sf || !$group_sf{$next_sf} );

    if ($is_first) {

        # Leading space unless this is the very first subfield of the field
        my $lead = ( defined $last_sf && length $last_sf ) ? ' ' : '';
        $value = $lead . '(' . $value;
    }
    if ($is_last) {
        $value .= ')';
    }

    return $value;
}

=head2 _decorate_qualifier_group_pre

I<Shared> pre-callback + helper for a REPEATABLE I<qualifying> subfield that
is wrapped in a single pair of parentheses, with multiple occurrences
separated by a per-field separator. This is the pattern used by:

    020 $q  (separator " ; ")
    210 $b  (separator ", ")
    222 $b  (separator ". ")

Example (020, $code q, $sep " ; "):

    $a 0914378260 $q pbk. $q v. 1  ->  (pbk. ; v. 1)

Because the separator differs per field, the rule set passes it in; the data
files therefore reference this helper via small closures that supply
C and C. A naive C E<lt> wrap => { b => ['(',')'] } E<gt> would
instead produce C<(a)(b)>, not C<(a, b)>, so this grouping is structural
and lives in C<cb_pre> (the parens/separator are attached to the run as a
unit), matching the 020/210/222 reference reading.

Non-group subfields pass through unchanged; a single occurrence is wrapped
entirely (C<(...)>); the first/middle/last of a run open the paren, add only
the separator, or add the separator and close the paren, respectively.

Called with the standard C<cb_pre> signature followed by C (the group
subfield's code) and C (the run-internal separator).

=cut

sub _decorate_qualifier_group_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref, $code, $sep ) = @_;

    return $value unless $sf eq $code;

    my $last_sf = $$last_sf_ref;
    my $next    = $subfields->[ $i + 1 ];
    my $next_sf = $next ? $next->[0] : '';

    if ( $last_sf ne $code && $next_sf eq $code ) {

        # First occurrence in a multi-occurrence run: open paren
        return "($value";
    }
    elsif ( $last_sf eq $code && $next_sf eq $code ) {

        # Middle occurrence: separator only
        return "$sep$value";
    }
    elsif ( $last_sf eq $code && $next_sf ne $code ) {

        # Last occurrence in the run: separator + close paren
        return "$sep$value)";
    }

    # Single occurrence: wrap entirely
    return "($value)";
}

=head2 log

Logging hook. By default prints to STDERR via C<warn>. In Koha
this can be overridden (or the method can be monkey-patched) to
use Koha's internal logging. Set C to enable
debug output.

=cut

sub log {
    my ( $self, $level, $message ) = @_;
    return unless $ENV{ISBD_DEBUG} or $level eq 'error';
    warn "[ISBD-$level] $message\n";
}

=head2 filter

Main filter entry point. Called by Koha's record processor
pipeline. Checks the leader byte 18 and, if punctuation was
omitted, iterates over all fields and applies the rules of the
active rule set (see C<rules_for>).

=cut

sub filter {
    my ( $self, $record, $attach_mode ) = @_;
    $attach_mode //= 'postfix';

    return $record unless defined $record and ref($record) eq 'MARC::Record';

    my $leader = $record->leader();

    # Add automatic punctuation only if the record requests it
    my $leader18            = substr( $leader, 18, 1 );
    my $punctuation_omitted = ( $leader18 eq 'c' or $leader18 eq 'n' );

    if ($punctuation_omitted) {
        $self->log( 'debug', "Processing record (leader18=$leader18)" );

        my $rules = rules_for();

        foreach my $field ( $record->fields ) {
            my $tag = $field->tag();
            my $r   = $rules->{$tag};
            next unless $r;

            $self->log( 'debug', "  Applying rules for field $tag" );

            # Default to postfix addition:
            # = add punctuation to the end of a subfield depending on
            # the subsequent subfield.
            #
            # prefix notation would also be possible and add the
            # punctuation to the beginning of a subfield depending on
            # the previous subfield. This might be advantageous in
            # case a subfield is not rendered in display to avoid
            # dangling punctuation.
            my @new_subfields = _decorate_field( $field, $r, $attach_mode );

            if (@new_subfields) {
                $self->log( 'debug', "    Old: " . $field->as_string() );
                $field->replace_with(
                    MARC::Field->new(
                        $field->tag(),        $field->indicator(1),
                        $field->indicator(2), @new_subfields
                    )
                );
                $self->log( 'debug', "    New: " . $field->as_string() );
            }
        }
    }

    return $record;
}

1;
