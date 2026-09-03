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
    # $t/$g get ' -- ' when $n follows via COMPOUND keys tn/gn:
    # a plain single key `n` would also fire on $i when $n
    # follows, which would be wrong. Compound keys only fire on $t/$g+n.
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
    #   $j:  ', '  $k:  '. '  $l:  '. '  $m:  ', '  $n:  '. '
    #   $o:  '; '  $p:  ', '  $q:  '()'  $r:  ', '  $s:  '. '
    #   $t:  '. '  $v:  ' ;'  (only for 800)
    #   $i: '' (ends with ':' via cataloger input; we leave it)
    #
    # NOTE (2026-08-31): $n => '. ' and $p => ', ' are the LoC/PCC (spec
    # §5.5) reading, aligned with x10/x11 (Option A) — e.g. Tolkien 700
    # $t ... $n 2 $p Two towers -> ...rings. 2, Two towers. This differs
    # from the colleague's German-union ISBDX00 (n=', ', p='. '). That
    # union variant belongs in the future regional/switchable overlay.
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
            n => '. ',
            o => '; ',
            p => ', ',
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
            n => '. ',
            o => '; ',
            p => ', ',
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
            n => '. ',
            o => '; ',
            p => ', ',
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
# ISBD punctuation = NAME PORTION (spec §5.3) + TITLE PORTION (spec §5.5).
#
# Name portion (§5.3):
#   $a: no change  $b: '. '  $c: ', '  $d: ', '  $e: ', '
#   $g: '()' (qualifying info) — wrap
#   compound keys: cc => '; '  dc => ' : '  nd => ' : ' (inside n/d/c group)
#   $o, $u, $x, $y, $z: no punctuation
#
# Title portion (§5.5) — uniform-title subfields.
#   $p: ', '  $r: ', '  $s: '. '  $t: '. '
#   plus (added 2026-08-31): $k '. '  $l '. '  $m ', '  $o '; '  $f '. '
#     $h '. '  $j ', '.
#   $n: NOT a broad single key (ambiguous with the $n/$d/$c meeting group);
#     handled via the COMPOUND key `tn` (fires when $n follows $t).
#   NOTE: $p => ', ' follows the §5.5 examples (Ecuador 710) — the
#   LoC/PCC (spec) reading. This DIFFERS from x00 where $p = '. '
#   (German-union-catalogue convention).
#
# $n/$d/$c (meeting number / date / location) grouped in one pair of
# parentheses by _decorate_x10_pre (matches enclose_in_parentheses('n','d','c')).
# NOTE: $n has NO broad single key — in x10 $n is ambiguous (meeting-group
# number vs §5.5 title-part number). Its title-portion punctuation is a
# COMPOUND key `tn` (fires only when $n FOLLOWS $t), so the $n/$d/$c meeting
# group is unaffected. A broad single `n => '. '` WOULD over-fire on $a $n in
# the meeting group (e.g. "Symposium. (2nd : ...)") — that broke tests.
#
# KNOWN GAPS / DECISIONS:
#   - $u (affiliation): NO punctuation, following spec §5.3 (N/A). NOTE for
#     reviewers: 'u' => '. ' might be possible as well; we
#     chose to follow the PDF (no punct). Revisit if real data shows a need.
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

            # title-portion (§5.5)
            k => '. ',
            l => '. ',
            m => ', ',
            o => '; ',
            f => '. ',
            h => '. ',
            j => ', ',

            # compound keys (preceded subfield + followed subfield), take
            # precedence over the single next_sf keys in _decorate_field
            cc => ' ; ',
            dc => ' : ',
            nd => ' : ',
            tn => '. ',    # $t followed by $n (title part, §5.5 Ecuador ex)
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
  # Title-portion (§5.5) keys retained (as for x00=600).
    '610' => {
        pchrs => {
            b  => '. ',
            e  => ', ',
            p  => ', ',
            r  => ', ',
            s  => '. ',
            t  => '. ',
            k  => '. ',
            l  => '. ',
            m  => ', ',
            o  => '; ',
            f  => '. ',
            h  => '. ',
            j  => ', ',
            cc => '; ',
            dc => ' : ',
            nd => ' : ',
            tn => '. ',    # $t followed by $n (title part, §5.5)
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
            k  => '. ',
            l  => '. ',
            m  => ', ',
            o  => '; ',
            f  => '. ',
            h  => '. ',
            j  => ', ',
            cc => '; ',
            dc => ' : ',
            nd => ' : ',
            tn => '. ',    # $t followed by $n (title part, §5.5)
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
    },

    # 111 – Main Entry – Meeting Name
    # ISBD punctuation for meeting names = NAME PORTION (spec §5.4) + TITLE
    # PORTION (spec §5.5).
    #
    # Name portion (§5.4), mirroring x10's structure:
    #   $n/$d/$c grouped in one paren pair by _decorate_x10_pre;
    #   $g wrapped with leading space.
    #   $e (SUBORDINATE UNIT) -> period-space '. '  [NOTE: differs from
    #     x10's $e which is a RELATOR -> ', ' following the spec]
    #   $j (relator term)     -> comma-space ', '
    #   $q (name after jurisdiction) -> period-space '. '
    #   $a, $u: no punctuation. $n/$d/$c via compound group keys nd/dc/cc.
    #
    # Title portion (§5.5) — uniform-title subfields on the name fields,
    # same as x00/x30:
    #   $t/.  $k/.  $l/.  $f/.  $h/.  ($h also used as medium, see §5.5)
    #   $p -> ', '   $s -> '. '   (both are '.'/',' choices in §5.5)
    #
    # KNOWN GAP: MULTIPLE $g -> each wrapped (a)(b), not (a : b) (same as x10).
    '111' => {
        pchrs => {
            e => '. ',
            j => ', ',
            q => '. ',

            # title-portion (§5.5): uniform title, part/version etc.
            t => '. ',
            k => '. ',
            l => '. ',
            f => '. ',
            h => '. ',
            p => ', ',
            s => '. ',

            # compound keys (group $n/$d/$c), take precedence in _decorate_field
            cc => ' ; ',
            dc => ' : ',
            nd => ' : ',
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
    },

    # 711 – Added Entry – Meeting Name
    # Identical structure to 111
    '711' => {
        use_rules => '111',
    },

    # 611 – Subject Added Entry – Meeting Name
    # Same as 111 but $v/$x/$y/$z (subject subdivisions) get NO punctuation
    # (111 has no $v; subject '/x/y/z are deliberately excluded).
    # Title-portion (§5.5) keys retained, as for x00=600.
    '611' => {
        pchrs => {
            e => '. ',
            j => ', ',
            q => '. ',

            # title-portion (§5.5)
            t => '. ',
            k => '. ',
            l => '. ',
            f => '. ',
            h => '. ',
            p => ', ',
            s => '. ',

            cc => ' ; ',
            dc => ' : ',
            nd => ' : ',
        },
        wrap   => { g => [ ' (', ')' ] },
        cb_pre => \&_decorate_x10_pre,
    },

    # 811 – Series Added Entry – Meeting Name
    # Same as 111 but $v (volume) gets ' ;' punctuation (subject 611 differs)
    '811' => {
        pchrs => {
            e => '. ',
            j => ', ',
            q => '. ',
            v => ' ;',

            # title-portion (§5.5)
            t => '. ',
            k => '. ',
            l => '. ',
            f => '. ',
            h => '. ',
            p => ', ',
            s => '. ',

            cc => ' ; ',
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
111/611/711/811). Groups a MEETING run of C<$n> (number), C<$d> (date) and
C<$c> (location) into a single pair of parentheses, e.g.

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
C<$t> subfield. A n/d/c that starts right after $t is a §5.5 title element and
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
