package Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::LoCPCC;

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
use MARC::Field;    # for clarity; callbacks may construct fields

=head1 NAME

Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::LoCPCC

=head1 DESCRIPTION

The I<LoC/PCC> ISBD punctuation rule set. This is the reading
derived from the PCC ISBD + MARC Task Group reference document
https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf
Any enumeration refers to this document.

This module is one of several possible I<rule sets> selectable by the plugin.
Each rule set is a self-contained hash in the shape of the legacy C<RULES>
constant: keys C<pchrs>, C<post>, C<wrap>, C<cb_pre>, C<cb_post>, C<use_rules>.

Shared structural callbacks (the C<e/f/g> grouping in 260 and the C<n/d/c>
meeting grouping in the x10/x11 name fields) are referenced by I<method-name
string> and resolved via C<can()> by the engine (see
ISBD4MARCPunctuation::_resolve_cb). This keeps this data file a readable
mixture of pure data plus self-contained closures — no code duplication.

=cut

sub rules {
    return {

        # 020 – International Standard Book Number
        # ISBD punct: $a ($q ; $q) : $c
        # The repeatable $q parenthetical grouping (with ' ; ' separators)
        # is the shared _decorate_qualifier_group_pre pattern (also used by
        # 210 $b and 222 $b, which differ only in the separator).
        '020' => {
            pchrs => {
                c => ' : ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'q', ' ; '
                  );
            },
        },

        # 210 – Abbreviated Title
        # ISBD punct: $a ($b , $b)
        # $a unchanged; repeatable $b (qualifying info) wrapped in one paren
        # pair, multiple $b separated by ', ' (spec §4.2). Same shared
        # repeatable-group pattern as 020 $q, with a different separator.
        # Example: $a Fam. her. $b Montr. $b 1859 -> (Montr., 1859)
        '210' => {
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', ', '
                  );
            },
        },

        # 222 – Key Title
        # ISBD punct: $a ($b . $b)
        # $a unchanged; repeatable $b (qualifying info) wrapped in one paren
        # pair, multiple $b separated by '. ' (spec §4.3). Same shared
        # repeatable-group pattern as 020 $q, with a different separator.
        # Example: $a Family herald $b Montreal $b 1859 -> (Montreal. 1859)
        '222' => {
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', '. '
                  );
            },
        },

        # 240 – Uniform Title
        # ISBD punct (spec §5.5 Uniform Titles):
        #   $a: N/A (plain)  $b: (qualifying info, repeatable) -> one paren
        #       pair '(...)', multiple $b separated by ' : '
        #   $f '. '  $g '. '  $h '. '  $j ', '  $k '. '  $l '. '
        #   $m ', '  $n '. '  $o '; '  $p ', '  $r ', '
        #   $s '. '  (DECISION: '. ' chosen; aligns with K10plus and
        #              is subject to review/change)
        #
        #   $b is a repeatable QUALIFYING-INFORMATION group, structurally
        #   the SAME pattern as 020 $q / 210 $b / 222 $b, so the shared
        #   _decorate_qualifier_group_pre callback is reused (separator
        #   ' : ' for multiple qualifiers, per §5.5 / the 130 §5.5 example
        #   "$a Dialogue $b Montreal, Quebec $b 1962" -> "(Montreal,
        #   Quebec : 1962)").
        #
        #   $p: ', ' chosen over '. ' (contextual — like 245 $p). The §5.5
        #       C.5 240 example would want '. ' before the part name, but
        #       the context is not MARC-decodable, so we pick ', '
        #       consistently and document as a known gap.
        #
        #   $d (240: date of treaty signing; §5.5 is '( ) or , '):
        #       NOT handled — contextual, rare. Documented gap.
        '240' => {
            pchrs => {
                f => '. ',
                g => '. ',
                h => '. ',
                j => ', ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => '. ',
                o => '; ',
                p => ', ',
                r => ', ',
                s => '. ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', ' : '
                  );
            },
        },

        # 130 – Main Entry – Uniform Title
        # Uniform title, same §5.5 structure and punctuation as 240.
        # 130 has NO $d per the §5.5 table ("$d ... (240, 243, 610, 611,
        # 710, 711, 730, 810, 811, 830 only)" — 130 not listed), and $d is
        # an unimplemented documented gap in 240 anyway, so aliasing is
        # exact for the implemented subfields.
        '130' => {
            use_rules => '240',
        },

        # 243 – Collective Uniform Title
        # Same §5.5 uniform-title structure and punctuation as 240
        # (Appendix B lists 240 AND 243 for $b/$j/$n). $a is the
        # collective uniform title; no subfield differences affect
        # punctuation, so this aliases 240 exactly.
        '243' => {
            use_rules => '240',
        },

        # 730 – Added Entry – Uniform Title
        # Same §5.5 uniform-title block as 240. 730 ADDS $i (relationship
        # information, 730 only) and $x (ISSN, 730/830... only) — both are
        # **N/A / no punctuation** per §5.5, i.e. they need NO pchrs key and
        # just pass through, which the 240 block already provides. So a
        # direct alias is exact for the implemented subfields.
        '730' => {
            use_rules => '240',
        },

        # 830 – Series Added Entry – Uniform Title
        # Same §5.5 uniform-title block as 240, PLUS $v (volume /
        # sequential designation) which per §5.5 gets ' ; ' (830 only,
        # alongside 800/810/811). $x (ISSN) is N/A (no punct). Mirrors the
        # 800/810/811 series pattern: same base block + a `v` key.
        '830' => {
            pchrs => {
                f => '. ',
                g => '. ',
                h => '. ',
                j => ', ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => '. ',
                o => '; ',
                p => ', ',
                r => ', ',
                s => '. ',
                v => ' ;',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', ' : '
                  );
            },
        },

        # 630 – Subject Added Entry – Uniform Title
        # Same §5.5 uniform-title block as 240/243/730/830, PLUS the ONE
        # subject-only subfield: $e (relator term, 630 only) -> ', ' per
        # §5.5. $v (volume) is NOT in 630 (830 only); $x/$y/$z subject
        # subdivisions have no punct here (uniform-title block defines none
        # of them). K10plus confirms the family grouping (its ISBDX30 is
        # shared by 130/630/730/830 with 630 = base minus $v).
        #
        # Implemented as its own standalone block (like 830) rather than an
        # alias, because use_rules is a FULL alias (no merge) and 630 needs
        # the extra `e` key on top of the 240 base.
        '630' => {
            pchrs => {
                e => ', ',   # 630-only: relator term (spec §5.5)
                f => '. ',
                g => '. ',
                h => '. ',
                j => ', ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => '. ',
                o => '; ',
                p => ', ',
                r => ', ',
                s => '. ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', ' : '
                  );
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

        # 242 – Translation of Title by Cataloging Agency
        # ISBD punct (spec §4.4): $a : $b / $c . $n , $p , $q [h]
        # The spec notes 242 "closely corresponds" to 245; it has NO
        # parallel-data subfields ($r/$t).
        #
        #   $b ' : '  $c ' / '  $e '. '  $n '. '  $q ', '
        #   $h: wrap [ ]
        #
        #   $p: ', ' chosen over '. ' (contextual — like 245 $p).
        #
        # GAPS (context not MARC-decodable, same class as 245 $o):
        #   $a ' ; '  only for SUBSEQUENT titles by the same author
        #   $o ', '   (alternative titles) vs ' ; ' (non-collective same
        #             author) vs trailing ', ' — contextual
        #   $y        language code — N/A, no punctuation
        '242' => {
            pchrs => {
                b => ' : ',
                c => ' / ',
                e => '. ',
                n => '. ',
                p => ', ',
                q => ', ',
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
        # Similar to 246 but has no $i subfield, and has $x (ISSN)
        # with no punctuation
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_260_pre',
        },

        # 264 – Production, Publication, Distribution,
        #       Manufacture, and Copyright
        # Similar to 260 but without $e/$f/$g grouping
        # Repeated $a (and $b followed by $a) are separated with " ; "
        # via the COMPOUND pchrs keys aa/ba (fires when a subfield is
        # followed by $a).
        # A bare single `a` would also fire on $3$a
        # (e.g. $3 August 1990 $a Berlin),
        # producing a spurious ' ;' before the post ' : '.
        # Compound keys avoid that.
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
                a => ' + ',  # second+ $a in multi-$a fields (scores with parts)
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
        # $b wrapped in parentheses, $c gets preceding dash,
        # $d gets preceding comma
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
        # $z gets ' -- ' prepended
        # (from eliminated preceding dash or period-space)
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
        # §5.5) reading, aligned with x10/x11 —
        # e.g. Tolkien 700 $t ... $n 2 $p Two towers -> ...rings. 2, Two towers.
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
        #   - $v (form subdivision) gets NO punctuation
        #        (deliberately excluded)
        #   - $x, $y, $z (general/chronological/geographic subdivisions)
        #     also excluded
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
        # Also 610 (Subject) and 810 (Series) with the usual
        # subdivision differences.
        # ISBD punctuation = NAME PORTION (spec §5.3) +
        #                    TITLE PORTION (spec §5.5).

        # Name portion (§5.3):
        #   $a: no change  $b: '. '  $c: ', '  $d: ', '  $e: ', '
        #   $g: '()' (qualifying info) — wrap
        #   compound keys:
        #      cc => '; '
        #      dc => ' : '
        #      nd => ' : ' (inside n/d/c group)
        #   $o, $u, $x, $y, $z: no punctuation

        # Title portion (§5.5) — uniform-title subfields.
        #   $p: ', '  $r: ', '  $s: '. '  $t: '. '
        #   $k '. '  $l '. '  $m ', '  $o '; '  $f '. '
        #   $h '. '  $j ', '.
        #   $n: NOT a broad single key
        #       (ambiguous with the $n/$d/$c meeting group);
        #       handled via the COMPOUND key `tn`
        #       (fires when $n follows $t).
        #   NOTE: $p => ', ' follows the §5.5 examples (Ecuador 710) — the
        #   LoC/PCC (spec) reading.
        #
        # $n/$d/$c (meeting number / date / location) grouped in one pair
        # of parentheses by _decorate_x10_pre
        # (matches enclose_in_parentheses('n','d','c')).
        # NOTE: $n has NO broad single key as it is ambiguous here
        # (meeting-group number vs §5.5 title-part number).
        #
        # Its title-portion punctuation is a COMPOUND key `tn`
        # (fires only when $n FOLLOWS $t), so the $n/$d/$c meeting
        # group is unaffected. A broad single `n => '. '` WOULD
        # over-fire on $a $n in the meeting group
        # (e.g. "Symposium. (2nd : ...)") — that broke tests.
        #
        # KNOWN GAPS / DECISIONS:
        #   - $u (affiliation): NO punctuation, following spec §5.3 (N/A).
        #     NOTE for reviewers: 'u' => '. ' might be possible as well;
        #     we chose to follow the PDF (no punct).
        #     Revisit if real data shows a need.
        #
        #   - MULTIPLE $g (e.g. $g 1981-1989 $g Reagan):
        #     each $g gets its own (), i.e. (a)(b),
        #     NOT the ideal (a : b). Left as a known imperfection.
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # 710 – Added Entry – Corporate Name
        # Identical structure to 110
        '710' => {
            use_rules => '110',
        },

        # 610 – Subject Added Entry – Corporate Name
        # Same pchrs/wrap as 110 but:
        #   - $v (form subdivision) gets NO punctuation
        #     (deliberately excluded)
        #   - $x, $y, $z (general/chronological/geographic subdivisions)
        #     also excluded Title-portion (§5.5) keys retained
        #     (as for x00=600).
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # 111 – Main Entry – Meeting Name
        # ISBD punctuation for meeting names = NAME PORTION (spec §5.4) + TITLE
        # PORTION (spec §5.5).
        #
        # Name portion (§5.4), mirroring x10's structure:
        #   $n/$d/$c grouped in one paren pair by _decorate_x10_pre;
        #   $g wrapped with leading space.
        #   $e (SUBORDINATE UNIT) -> period-space '. '
        #      NOTE: differs from x10's $e which is a RELATOR -> ', '
        #            following the spec
        #   $j (relator term)     -> comma-space ', '
        #   $q (name after jurisdiction) -> period-space '. '
        #   $a, $u: no punctuation. $n/$d/$c via compound group keys nd/dc/cc.
        #
        # Title portion (§5.5) — uniform-title subfields on the
        # name fields, same as x00/x30:
        #   $t/.  $k/.  $l/.  $f/.  $h/.  ($h also used as medium, see §5.5)
        #   $p -> ', '   $s -> '. '   (both are '.'/',' choices in §5.5)
        #
        # KNOWN GAP: MULTIPLE $g -> each wrapped (a)(b),
        #            not (a : b) (same as x10).
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

                # compound keys (group $n/$d/$c),
                # take precedence in _decorate_field
                cc => ' ; ',
                dc => ' : ',
                nd => ' : ',
            },
            wrap   => { g => [ ' (', ')' ] },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # 811 – Series Added Entry – Meeting Name
        # Same as 111 but $v (volume) gets ' ;' punctuation
        # (subject 611 differs)
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
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

    };
}

1;
