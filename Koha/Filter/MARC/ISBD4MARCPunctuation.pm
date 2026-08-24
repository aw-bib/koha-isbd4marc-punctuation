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

our $NAME    = 'ISBD4MARCPunctuation';
our $VERSION = '0.02';

=head1 NAME

Koha::Filter::MARC::ISBD4MARCPunctuation - Automatically add ISBD punctuation
to MARC21 records if the leader specifies they were catalogued without it.

Documentation for proper punctuation:
https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf

=head1 DESCRIPTION

If the MARC leader byte 18 specifies that the record was catalogued
without punctuation (values C<n> or C<c>), this filter injects the
proper ISBD punctuation into the individual fields before passing the
record on to further processing. The records in the database are I<not>
changed.

The punctuation rules are defined in a static hash and the core
loop in C<_decorate_field> handles them generically. Adding support
for a new field is as simple as adding an entry to the C<RULES>
constant.

=cut

=head1 PUNCTUATION RULES

Each rule hash supports the following keys:

=over

=item C<pchrs>

Hashref of preceding characters. Key is the I<next> subfield tag,
value is the punctuation to append to the I<current> subfield.
E.g. C<< { b => ' : ' } >> means "if the next subfield is C<$b>,
append ' : ' to the current subfield."

=item C<post>

Hashref of always-appended suffixes. The value is appended to the
current subfield after all other processing. E.g. C<< { 3 => ': ' } >>

=item C<wrap>

Hashref of wrapping pairs. Key is the subfield tag, value is an
arrayref of C<[prefix, suffix]>. E.g. C<< { h => [ '[', ']' ] } >>
wraps C<$h> content in square brackets.

=item C<cb_pre>

Optional callback run I<before> wrapping and look-ahead logic.
Receives C<< ($sf, $value, $i, \@subfields, \$last_sf) >>.
Use this for grouping logic (e.g. C<$e/$f/$g> in 260).
Must return the (possibly modified) value.

=item C<cb_post>

Optional callback run I<after> wrapping but I<before> look-ahead.
Same signature as C<cb_pre>.

=item C<use_rules>

Alias to another tag's rules. Only one level of indirection is
resolved. E.g. C<< { use_rules => 246 } >> means "use the same
rules as field 246."

=back

=cut

use constant RULES => {

    # 245 – Title Statement
    # ISBD punct: $a : $b / $c ; $d . $e , $f , $g [h] . $n , $p : $k . $s
    245 => {
        pchrs => {
            b => ' : ',
            c => ' / ',
            d => ' ; ',
            e => '. ',
            f => ', ',
            g => ', ',
            k => ' : ',
            n => '. ',
            p => ', '
            , # Could be `, ` or `. ` depending on context. Pick `, ` as more likely
            q => ', ',
            r => ' = ',
            s => '. ',
            t => ' = ',

            # Missing subfields:
            # o: puncuation is context dependend and the context is
            #    not encoded in MARC.
            #
        },
        wrap => { h => [ '[', ']' ] },
    },

    # 246 – Varying Form of Title
    # 247 – Former Title
    # ISBD punct: $i: $a : $b / $c . $n , $p , $f = $r
    246 => {
        pchrs => {
            b => ' : ',
            f => ', ',
            n => '. ',
            p => ', ',
            q => ', ',
            r => ' = ',
            t => ' = ',
        },
        wrap   => { g => [ '(', ')' ], h => [ '[', ']' ] },
        cb_pre => sub {
            my ( $sf, $value ) = @_;
            return $sf eq 'i' ? "$value: " : $value;
        },
    },

  # 247 – Former Title
  # ISBD punct: $a : $b / $c . $n , $p , $f = $r (no $i)
  # Similar to 246 but has no $i subfield, and has $x (ISSN) with no punctuation
    247 => {
        pchrs => {
            b => ' : ',
            f => ', ',
            n => '. ',
            p => ', ',
            q => ', ',
            r => ' = ',
            t => ' = ',
        },
        wrap => { g => [ '(', ')' ], h => [ '[', ']' ] },

        # NOTE: No cb_pre — 247 has no $i subfield
    },

    # 260 – Publication, Distribution, etc. (Imprint)
    # ISBD punct: $a ; $a : $b , $c ( $e : $f , $g ) (q)
    # Note: $e/$f/$g form a grouped parenthetical: ($e : $f , $g)
    260 => {
        pchrs => {
            b => ' : ',
            c => ', ',
            r => ' = ',
            t => ' = ',
        },
        post   => { 3 => ': ' },
        wrap   => { q => [ '(', ')' ] },
        cb_pre => \&_decorate_260_pre,
    },

    # 264 – Production, Publication, Distribution, Manufacture, and Copyright
    # Similar to 260 but without $e/$f/$g grouping
    264 => {
        pchrs => {
            b => ' : ',
            c => ', ',
            r => ' = ',
            t => ' = ',
        },
        post   => { 3 => ': ' },
        wrap   => { q => [ '(', ')' ] },
        cb_pre => sub {
            my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
            my $last_sf = $$last_sf_ref;
            if ( $sf eq 'a' and $last_sf eq 'a' ) {
                $value = " ; $value";
            }
            if ( $sf eq 'a' and $last_sf eq 'b' ) {
                $value = " ; $value";
            }
            return $value;
        },
    },

    # 490 – Series Statement
    # ISBD punct: $a : $b / $c ; $d (. $n , $p) ; $v , $x = $r = $t = $y
    # $3 gets ': ' appended via post, $l wrapped in (...)
    490 => {
        pchrs => {
            b => ' : ',
            c => ' / ',
            d => ' ; ',
            n => '. ',
            p => ', ',    # Could be `. ` or `, ` depending on context
            r => ' = ',
            t => ' = ',
            v => ' ; ',
            x => ', ',
            y => ' = ',
        },
        post => { 3 => ': ' },
        wrap => { l => [ '(', ')' ] },
    },
};

=head2 _decorate_field

Generic field decorator. Takes a MARC::Field object, a rules
hashref (as defined in C<RULES>), and an optional attachment mode
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

    # Resolve use_rules alias (single level)
    if ( my $alias = $rules->{use_rules} ) {
        $rules = RULES->{$alias};
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
        if ( my $cb = $rules->{cb_pre} ) {
            $value = $cb->( $sf, $value, $i, \@subfields, \$last_sf );
        }

        # 2) Wrap (brackets / parentheses)
        if ( my $wrap = $rules->{wrap}{$sf} ) {
            $value = $wrap->[0] . $value . $wrap->[1];
        }

        # 3) Post-callback
        if ( my $cb = $rules->{cb_post} ) {
            $value = $cb->( $sf, $value, $i, \@subfields, \$last_sf );
        }

        # 4) Punctuation attachment based on mode
        my $next = $subfields[ $i + 1 ];
        if ( defined $next ) {
            my ($next_sf) = @$next;
            if ( exists $rules->{pchrs}{$next_sf} ) {
                my $punct = $rules->{pchrs}{$next_sf};
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

Pre-callback for field 260. Handles the complex grouping logic
for C<$e> (producer), C<$f> (producer place), and C<$g>
(production date) which form a parenthetical group together.

Also handles multiple C<$a> and C<$a> after C<$b> for 260.

=cut

sub _decorate_260_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
    my $last_sf = $$last_sf_ref;

    # Multiple $a: separate with " ; "
    if ( $sf eq 'a' and $last_sf eq 'a' ) {
        $value = " ; $value";
    }

    # $a after $b: separate with " ; "
    if ( $sf eq 'a' and $last_sf eq 'b' ) {
        $value = " ; $value";
    }

    # $e/$f/$g grouping: open parenthetical
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

=head2 log

Logging hook. By default prints to STDERR via C<warn>. In Koha
this can be overridden (or the method can be monkey-patched) to
use Koha's internal logging. Set C<$ENV{ISBD_DEBUG}> to enable
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
omitted, iterates over all fields and applies the rules defined
in C<RULES>.

=cut

sub filter {
    my ( $self, $record ) = @_;

    return $record unless defined $record and ref($record) eq 'MARC::Record';

    my $leader = $record->leader();

    # Add automatic punctuation only if the record requests it
    my $leader18            = substr( $leader, 18, 1 );
    my $punctuation_omitted = ( $leader18 eq 'c' or $leader18 eq 'n' );

    if ($punctuation_omitted) {
        $self->log( 'debug', "Processing record (leader18=$leader18)" );

        foreach my $field ( $record->fields ) {
            my $tag   = $field->tag();
            my $rules = RULES->{$tag};
            next unless $rules;

            $self->log( 'debug', "  Applying rules for field $tag" );

            my @new_subfields = _decorate_field( $field, $rules, 'prefix' );

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
