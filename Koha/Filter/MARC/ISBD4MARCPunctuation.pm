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

    # 020 – International Standard Book Number
    # ISBD punct: $a ($q ; $q) : $c
    # Full implementation with $q parenthetical grouping via cb_pre
    '020' => {
        pchrs => {
            c => ' : ',
        },
        cb_pre => sub {
            my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
            return $value unless $sf eq 'q';

            my $last_sf = $$last_sf_ref;
            my $next    = $subfields->[ $i + 1 ];
            my $next_sf = $next ? $next->[0] : '';

            if ( $last_sf ne 'q' && $next_sf eq 'q' ) {

                # First $q in a multi-$q group: open paren
                return "($value";
            }
            elsif ( $last_sf eq 'q' && $next_sf eq 'q' ) {

                # Middle $q: separator only
                return " ; $value";
            }
            elsif ( $last_sf eq 'q' && $next_sf ne 'q' ) {

                # Last $q in group: separator + close paren
                return " ; $value)";
            }

            # Single $q: wrap entirely
            return "($value)";
        },
    },

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

    # 250 – Edition Statement
    # ISBD punct: $a / $c ; $d = $r = $t
    # $b is obsolete, replaced by $c and $r in the future form
    250 => {
        pchrs => {
            c => ' / ',
            d => ' ; ',
            r => ' = ',
            t => ' = ',
        },
    },

    # 260 – Publication, Distribution, etc. (Imprint)
    # ISBD punct: $a ; $a : $b , $c ( $e : $f , $g ) (q)
    # Note: $e/$f/$g form a grouped parenthetical: ($e : $f , $g)
    # Repeated $a (and $b followed by $a) are separated with " ; " via the
    # COMPOUND pchrs keys aa/ba (fires when a subfield is followed by $a).
    # A bare single `a` would also fire on $3$a, producing a spurious ' ;'
    # before the post ' : '. Compound keys avoid that (see also 264).
    260 => {
        pchrs => {
            aa => ' ; ',
            ba => ' ; ',
            b  => ' : ',
            c  => ', ',
            r  => ' = ',
            t  => ' = ',
        },
        post   => { 3 => ': ' },
        wrap   => { q => [ '(', ')' ] },
        cb_pre => \&_decorate_260_pre,
    },

    # 264 – Production, Publication, Distribution, Manufacture, and Copyright
    # Similar to 260 but without $e/$f/$g grouping
    # Repeated $a (and $b followed by $a) are separated with " ; " via the
    # COMPOUND pchrs keys aa/ba (fires when a subfield is followed by $a).
    # A bare single `a` would also fire on $3$a (e.g. $3 August 1990 $a Berlin),
    # producing a spurious ' ;' before the post ' : '. Compound keys avoid that.
    264 => {
        pchrs => {
            aa => ' ; ',
            ba => ' ; ',
            b  => ' : ',
            c  => ', ',
            r  => ' = ',
            t  => ' = ',
        },
        post => { 3 => ': ' },
        wrap => { q => [ '(', ')' ] },
    },

    # 300 – Physical Description
    # ISBD punct: $a : $b ; $c + $e
    # $h wrapped in parentheses
    # $a-to-$a (scores with parts) gets preceding +
    # Known gaps: $h/$i/$j accompanying material grouping (rare)
    300 => {
        pchrs => {
            b => ' : ',
            c => ' ; ',
            e => ' + ',
            a => ' + ',    # second+ $a in multi-$a fields (scores with parts)
        },
        wrap => { h => [ '(', ')' ] },
    },

    # 490 - Series statement
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

    # 502 – Dissertation Note
    # ISBD punct: (b) -- c, d
    # $b wrapped in parentheses, $c gets preceding dash, $d gets preceding comma
    502 => {
        pchrs => {
            c => ' -- ',
            d => ', ',
        },
        wrap => {
            b => [ '(', ')' ],
        },
    },

    # 505 – Formatted Contents Note
    # ISBD punct: $t -- $t / $r  (between titles), $g wrapped in (...)
    # $t gets preceding -- when another $t or $r follows
    # $r gets preceding /
    # $i (display text) gets trailing ': ' via cb_pre
    # $n (part designation): $n gets ' -- ' when $t follows
    #   (single pchrs key `t`, fires whenever a subfield is followed by $t)
    # $t/$g get ' -- ' when $n follows via COMPOUND keys tn/gn — this is the
    #   precise fix: a plain single key `n` would also fire on $i when $n
    #   follows, which would be wrong. Compound keys only fire on $t/$g+n.
    505 => {
        pchrs => {
            r  => ' / ',
            t  => ' -- ',
            tn => ' -- ',
            gn => ' -- ',
        },
        wrap   => { g => [ '(', ')' ] },
        cb_pre => sub {
            my ( $sf, $value ) = @_;
            return $sf eq 'i' ? "$value: " : $value;
        },
    },

    # 520 – Summary, etc.
    # ISBD punct: $a $z (takes preceding -- or .)
    # $z gets ' -- ' prepended (from eliminated preceding dash or period-space)
    520 => {
        pchrs => {
            z => ' -- ',
        },
    },

    # 100 – Main Entry – Personal Name
    # Also covers 700 (Added Entry) via use_rules
    # ISBD separating punctuation between subfields:
    #   $a alone: no change (inversion comma already in $a)
    #   $b:  '. '  $c:  ', '  $d:  ', '  $e:  ', '  $f:  '. '
    #   $j:  ', '  $k:  '. '  $l:  '. '  $m:  ', '  $n:  ', '
    #   $o:  '; '  $p:  '. '  $q:  '()'  $r:  ', '  $s:  '. '
    #   $t:  '. '  $v:  ' ;'  (only for 800)
    #   $i: '' (ends with ':' via cataloger input; we leave it)
    #
    # Note: $a/$h split (spec section 5.2) is NOT in use yet.
    # Real records have $a with inversion comma (e.g. "Morgan, Robert").
    # We pass $a through unchanged and only add separating punctuation
    # between subfields.
    '100' => {
        pchrs => {
            b => '. ',
            c => ', ',
            d => ', ',
            e => ', ',
            f => '. ',
            j => ', ',
            k => '. ',
            l => '. ',
            m => ', ',
            n => ', ',
            o => '; ',
            p => '. ',
            r => ', ',
            s => '. ',
            t => '. ',
        },
        wrap => {
            q => [ '(', ')' ],
        },
    },

    # 700 – Added Entry – Personal Name
    # Identical structure to 100
    '700' => {
        use_rules => '100',
    },

  # 600 – Subject Added Entry – Personal Name
  # Same pchrs/wrap as 100 but:
  #   - $v (form subdivision) gets NO punctuation (deliberately excluded)
  #   - $x, $y, $z (general/chronological/geographic subdivisions) also excluded
    '600' => {
        pchrs => {
            b => '. ',
            c => ', ',
            d => ', ',
            e => ', ',
            f => '. ',
            j => ', ',
            k => '. ',
            l => '. ',
            m => ', ',
            n => ', ',
            o => '; ',
            p => '. ',
            r => ', ',
            s => '. ',
            t => '. ',
        },
        wrap => { q => [ '(', ')' ] },
    },

    # 800 – Series Added Entry – Personal Name
    # Same as 100 but $v (volume) gets ' ;' punctuation (600 differs)
    '800' => {
        pchrs => {
            b => '. ',
            c => ', ',
            d => ', ',
            e => ', ',
            f => '. ',
            j => ', ',
            k => '. ',
            l => '. ',
            m => ', ',
            n => ', ',
            o => '; ',
            p => '. ',
            r => ', ',
            s => '. ',
            t => '. ',
            v => ' ;',
        },
        wrap => { q => [ '(', ')' ] },
    },

# 110 – Main Entry – Corporate Name
# Also covers 710 (Added Entry) via use_rules
# Also 610 (Subject) and 810 (Series) with the usual subdivision differences.
# Full ISBDX10 rules (spec §5.3):
#   $a:  no change          $b:  '. '   $c:  ', '  $d:  ', '  $e:  ', '
#   $p:  ', '   $r:  ', '   $s:  '. '   $t:  '. '
#   $g:  '()'  (qualifying information) — wrap
#   compound keys: cc => '; '  dc => ' : '  nd => ' : ' (inside n/d/c group)
#   $n, $o, $u, $x, $y, $z: no punctuation
#
# $n/$d/$c (meeting number / date / location) are grouped in one pair of
# parentheses by _decorate_x10_pre (matches enclose_in_parentheses('n','d','c')).
#
# KNOWN GAPS / DECISIONS:
#   - $u (affiliation): NO punctuation, following spec §5.3 (N/A). NOTE for
#     reviewers: 'u' => '. ' might be possible as well; we
#     chose to follow the PDF (no punct). Revisit if real data shows a need.
#   - $n: deliberately NOT individually wrapped  to avoid double-paren on
#     the $n/$d/$c group (cb_pre already groups them).
#   - MULTIPLE $g (e.g. $g 1981-1989 $g Reagan): each $g gets its own (),
#     i.e. (a)(b), NOT the ideal (a : b). Left as a known imperfection.
    '110' => {
        pchrs => {
            b => '. ',
            e => ', ',
            p => ', ',
            r => ', ',
            s => '. ',
            t => '. ',

            # compound keys (preceded subfield + followed subfield), take
            # precedence over the single next_sf keys in _decorate_field
            cc => ' ; ',
            dc => ' : ',
            nd => ' : ',
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
    },

    # 710 – Added Entry – Corporate Name
    # Identical structure to 110
    '710' => {
        use_rules => '110',
    },

  # 610 – Subject Added Entry – Corporate Name
  # Same pchrs/wrap as 110 but:
  #   - $v (form subdivision) gets NO punctuation (deliberately excluded)
  #   - $x, $y, $z (general/chronological/geographic subdivisions) also excluded
    '610' => {
        pchrs => {
            b  => '. ',
            e  => ', ',
            p  => ', ',
            r  => ', ',
            s  => '. ',
            t  => '. ',
            cc => '; ',
            dc => ' : ',
            nd => ' : ',
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
    },

    # 810 – Series Added Entry – Corporate Name
    # Same as 110 but $v (volume) gets ' ;' punctuation (610 differs)
    '810' => {
        pchrs => {
            b  => '. ',
            e  => ', ',
            p  => ', ',
            r  => ', ',
            s  => '. ',
            t  => '. ',
            v  => ' ;',
            cc => '; ',
            dc => ' : ',
            nd => ' : ',
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
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

Pre-callback for field 260. Handles the parenthetical grouping of C
(producer), C (producer place) and C (production date)/C
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

Pre-callback for the corporate/meeting-name fields (110/610/710/810). Groups
consecutive C<$n> (meeting number), C<$d> (date of meeting) and C<$c>
(location of meeting) subfields into a single pair of parentheses, e.g.

    $d 1857 $c Waco, Tex.  ->  (1857 : Waco, Tex.)

This mirrors I<enclose_in_parentheses(datafield, 'n', 'd', 'c')>
The internal C<' : '> / C<'; '> separators are supplied by
the compound pchrs keys C<nd>/C<dc>/C<cc> in step 4 of C<_decorate_field>.

A leading space is added before the opening paren when the group is preceded
by other content (e.g. C<$b State Convention (1857 : ...>).

=cut

sub _decorate_x10_pre {
    my ( $sf, $value, $i, $subfields, $last_sf_ref ) = @_;
    my $last_sf = $$last_sf_ref;

    my %group_sf = map { $_ => 1 } qw(n d c);

    # Not part of the n/d/c meeting group — leave untouched
    return $value unless $group_sf{$sf};

    my $next    = $subfields->[ $i + 1 ];
    my $next_sf = $next ? $next->[0] : '';

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
    my ( $self, $record, $attach_mode ) = @_;
    $attach_mode //= 'postfix';

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

            # Default to postfix addition:
            # = add punctuation to the end of a subfield depending on
            # the subsequent subfield.
            #
            # prefix notation would also be possible and add the
            # punctuation to the beginning of a subfield depending on
            # the previous subfield. This might be advantageous in
            # case a subfield is not rendered in display to avoid
            # dangling punctuation.
            my @new_subfields = _decorate_field( $field, $rules, $attach_mode );

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
