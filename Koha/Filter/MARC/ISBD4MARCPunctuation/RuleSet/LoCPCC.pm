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

        # ISBD punct: $a ($q ; $q) : $c
        # The repeatable $q parenthetical grouping (with ' ; ' separators)
        # is the shared _decorate_qualifier_group_pre pattern (also used by
        # 210 $b and 222 $b, which differ only in the separator).
        '020' => {
            name  => 'International Standard Book Number',
            pchrs => {
                c => ' : ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'q', ' ; ' );
            },
        },

        # ISBD punct: separating punctuation between subfields (§5.5):
        #   $a alone: no change (inversion comma already in $a)
        #   $b '. '  $c ', '  $d ', '  $e ', '  $f '. '  $j ', '
        #   $k '. '  $l '. '  $m ', '  $n '. '  $o '; '  $p ', '
        #   $q '()'  $r ', '  $s '. '  $t '. '  $v ' ;' (800 only)
        #   $i: left as-is (cataloguer ends it with ':')
        #
        # DECISIONS / GAPS:
        #   - $n '. ' / $p ', ' are the §5.5 LoC/PCC reading (aligned with
        #     x10/x11; e.g. Tolkien 700 "…rings. 2, Two towers").
        #   - §5.2 $a/$h split NOT in use: real records keep the inversion
        #     comma inside $a (e.g. "Morgan, Robert"), so $a passes through.
        # 700 (Added Entry) aliases this block.
        '100' => {
            name  => 'Main Entry – Personal Name',
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

# ISBD punct: name portion (§5.3) + title portion (§5.5):
#   $b '. '  $e ', '  $p ', '  $r ', '  $s '. '  $t '. '
#   title: $k '. '  $l '. '  $m ', '  $o '; '  $f '. '  $h '. '  $j ', '
#   compounds: cc ' ; '  dc ' : '  nd ' : '  tn '. ' ($t then $n, §5.5 Ecuador ex)
# $n/$d/$c (meeting number/date/location) grouped in ONE paren pair by
# _decorate_x10_pre; separators via the cc/dc/nd compound keys.
#
# DECISIONS / GAPS:
#   - $n has NO broad single key: a plain `n => '. '` would over-fire
#     on the $n/$d/$c meeting group (e.g. "Symposium. (2nd : ...)" —
#     broke tests). Only the COMPOUND `tn` fires (title part).
#   - $u (affiliation): NO punctuation (spec §5.3 N/A). K10plus used
#     '. '; we follow the PDF.
#   - MULTIPLE $g -> each wrapped (a)(b), not (a : b). Known
#     imperfection (K10plus same).
        '110' => {
            name  => 'Main Entry – Corporate Name',
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

      # ISBD punct: NAME (§5.4) + TITLE (§5.5) portion, mirroring x10.
      #   $e (subordinate unit) '. '  $j (relator) ', '  $q '. '
      #   title: $t '. '  $k '. '  $l '. '  $f '. '  $h '. '  $p ', '  $s '. '
      #   compounds: cc ' ; '  dc ' : '  nd ' : ' (meeting $n/$d/$c group)
      # $n/$d/$c grouped in ONE paren pair by _decorate_x10_pre; $g wrapped (…).
      # $a, $u: no punctuation.
      #
      # DECISIONS / GAPS:
      #   - Meeting $e is a SUBORDINATE UNIT -> '. ' (differs from x10's
      #     relator $e -> ', ', per spec §5.4).
      #   - MULTIPLE $g -> each wrapped (a)(b), not (a : b) (same as x10).
        '111' => {
            name  => 'Main Entry – Meeting Name',
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

        # Uniform title, same §5.5 structure and punctuation as 240.
        # 130 has NO $d per the §5.5 table ("$d ... (240, 243, 610, 611,
        # 710, 711, 730, 810, 811, 830 only)" — 130 not listed), and $d is
        # an unimplemented documented gap in 240 anyway, so aliasing is
        # exact for the implemented subfields.
        '130' => {
            name      => 'Main Entry – Uniform Title',
            use_rules => '240',
        },

        # ISBD punct: $a ($b , $b)
        # $a unchanged; repeatable $b (qualifying info) wrapped in one paren
        # pair, multiple $b separated by ', ' (spec §4.2). Same shared
        # repeatable-group pattern as 020 $q, with a different separator.
        # Example: $a Fam. her. $b Montr. $b 1859 -> (Montr., 1859)
        '210' => {
            name   => 'Abbreviated Title',
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', ', ' );
            },
        },

        # ISBD punct: $a ($b . $b)
        # $a unchanged; repeatable $b (qualifying info) wrapped in one paren
        # pair, multiple $b separated by '. ' (spec §4.3). Same shared
        # repeatable-group pattern as 020 $q, with a different separator.
        # Example: $a Family herald $b Montreal $b 1859 -> (Montreal. 1859)
        '222' => {
            name   => 'Key Title',
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'b', '. ' );
            },
        },

        # ISBD punct (§5.5 Uniform Titles):
        #   $b (qualifying info, repeatable) -> ONE paren pair '(...)',
        #     multiple $b separated by ' : ' (shared qualifier-group pattern
        #     as 020 $q / 210 $b / 222 $b; separator per §5.5 — e.g. the 130
        #     example "$a Dialogue $b Montreal, Quebec $b 1962" ->
        #     "(Montreal, Quebec : 1962)")
        #   $f '. '  $g '. '  $h '. '  $j ', '  $k '. '  $l '. '
        #   $m ', '  $n '. '  $o '; '  $p ', '  $r ', '  $s '. '
        #
        # DECISIONS / GAPS:
        #   - $s '. ' chosen over §5.5's '( )' alternative (K10plus-aligned,
        #     subject to review).
        #   - $p ', ' chosen over '. ' (contextual, like 245; the C.5 240
        #     example would want '. ' before the part name — documented gap).
        #   - $d (240: date of treaty signing; §5.5 '( ) or , '): NOT handled
        #     — contextual, rare. Documented gap.
        '240' => {
            name  => 'Uniform Title',
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
                    @_, 'b', ' : ' );
            },
        },

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
            name  => 'Translation of Title by Cataloging Agency',
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

        # Same §5.5 uniform-title structure and punctuation as 240
        # (Appendix B lists 240 AND 243 for $b/$j/$n). $a is the
        # collective uniform title; no subfield differences affect
        # punctuation, so this aliases 240 exactly.
        '243' => {
            name      => 'Collective Uniform Title',
            use_rules => '240',
        },

        # ISBD punct: $a : $b / $c ; $d . $e , $f , $g [h] . $n , $p : $k . $s
        #
        # DECISION / GAP: $p can be ', ' or '. ' depending on context — we pick
        # ', ' as more likely. $o (conjunction) is not decodable in MARC.
        '245' => {
            name  => 'Title Statement',
            pchrs => {
                b => ' : ',
                c => ' / ',
                d => ' ; ',
                e => '. ',
                f => ', ',
                g => ', ',
                k => ' : ',
                n => '. ',
                p => ', ',    # Context: could be `. ` or `, `; we pick `, `
                q => ', ',
                r => ' = ',
                s => '. ',
                t => ' = ',

                # $o (conjunction) is context-dependent and the context is
                # not encoded in MARC — not handled.
            },
            wrap => { h => [ '[', ']' ] },
        },

        # ISBD punct: $i: $a : $b / $c . $n , $p , $f = $r
        '246' => {
            name  => 'Varying Form of Title',
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

        # ISBD punct: $a : $b / $c . $n , $p , $f = $r (no $i)
        # Similar to 246 but has no $i subfield, and has $x (ISSN)
        # with no punctuation
        '247' => {
            name  => 'Former Title',
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

        # ISBD punct: $a / $c ; $d = $r = $t
        # $b is obsolete, replaced by $c and $r in the future form
        '250' => {
            name  => 'Edition Statement',
            pchrs => {
                c => ' / ',
                d => ' ; ',
                r => ' = ',
                t => ' = ',
            },
        },

        # ISBD punct: $a ; $a : $b , $c ( $e : $f , $g ) (q)
        # $e/$f/$g form a grouped parenthetical by _decorate_260_pre;
        # $3 gets ': ' via post; $q wrapped (...). Repeated $a (and $b then
        # $a) separated by ' ; ' via COMPOUND keys aa/ba.
        #
        # DECISION: use aa/ba compounds, NOT a bare single `a` — a single `a`
        # would also fire on $3$a, producing a spurious ' ;' before the post
        # ': '. See also 264.
        '260' => {
            name  => 'Publication, Distribution, etc. (Imprint)',
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

        # ISBD punct: same as 260 but WITHOUT the $e/$f/$g grouping (no cb_pre).
        # $3 ': ' via post; $q wrapped (...). Repeated $a (and $b then $a)
        # separated by ' ; ' via COMPOUND keys aa/ba.
        #
        # DECISION: aa/ba compounds, NOT a bare single `a` (would over-fire
        # on $3$a — spurious ' ;' before the post ': ').
        '264' => {
            name =>
'Production, Publication, Distribution, Manufacture, and Copyright',
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

        # ISBD punct: $a : $b ; $c + $e ($h : $i ; $j)
        # $e gets preceding + (accompanying material).
        # $h/$i/$j (details of accompanying material) are grouped in ONE
        # paren pair by _decorate_300_pre, anchored on $h (doc ex 6):
        #   $e 1 atlas $h ... $i color maps $j 37 cm
        #     ->  1 atlas (... : color maps ; 37 cm)
        # Internal separators via COMPOUND pchrs keys (like x10's nd/dc/cc):
        #   hi => ' : ' (between $h and $i)
        #   ij => ' ; ' (between $i and $j)
        #   hj => ' ; ' (between $h and $j, when no $i)
        # $a-to-$a (scores with parts) gets preceding +.
        # KNOWN GAP: a lone $i or $j (no leading $h) is the §4.14 "or" case
        #            and is left to cataloguers WITHOUT parentheses. Note that
        #            a lone $i/$j adjacent to another still gets a bare " ; "
        #            from the hi/ij/hj keys (engine fires on sf.next_sf) — see
        #            _decorate_300_pre pod (Option A; no real-world case yet).
        '300' => {
            name  => 'Physical Description',
            pchrs => {
                b  => ' : ',
                c  => ' ; ',
                e  => ' + ',
                a  => ' + ', # second+ $a in multi-$a fields (scores with parts)
                hi => ' : ',
                ij => ' ; ',
                hj => ' ; ',
            },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_300_pre',
        },

        # ISBD punct (§4.18 series statement):
        #   $b ' : '  $c ' / '  $d ' ; '  $n '. '  $p ', '  $r ' = '
        #   $t ' = '  $v ' ; '  $x ', '  $y ' = '
        # $3 gets ': ' via post; $l wrapped (...).
        # GAP: $p can be '. ' or ', ' depending on context — we pick ', '.
        '490' => {
            name  => 'Series Statement',
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

        # ISBD punct (§4.21 general note): $i ': ' via cb_pre (display text);
        # $z ' -- ' (source; §4.20 allows preceding dash OR period-space, we
        # pick ' -- ' for consistency with 520). $a N/A.
        '500' => {
            name  => 'General Note',
            pchrs => { z => ' -- ' },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§4.22 with note): $i ': ' via cb_pre (display text).
        # $a N/A. No $z.
        '501' => {
            name  => 'With Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct: (b) -- c, d
        # $b wrapped in parentheses, $c gets preceding dash,
        # $d gets preceding comma
        '502' => {
            name  => 'Dissertation Note',
            pchrs => {
                c => ' -- ',
                d => ', ',
            },
            wrap => {
                b => [ '(', ')' ],
            },
        },

        # ISBD punct (§4.24 bibliography note): $i ': ' via cb_pre (display
        # text). $a/$b N/A.
        '504' => {
            name  => 'Bibliography, etc. Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct: $t -- $t / $r  (between titles), $g wrapped in (...)
        # $t gets preceding -- when another $t or $r follows
        # $r gets preceding /
        # $i (display text) gets trailing ': ' via cb_pre
        # $n (part designation): $n gets ' -- ' when $t follows
        #   (single pchrs key `t`, fires whenever a subfield is followed by $t)
        # $t/$g get ' -- ' when $n follows via COMPOUND keys tn/gn:
        # a plain single key `n` would also fire on $i when $n
        # follows, which would be wrong. Compound keys only fire on $t/$g+n.
        '505' => {
            name  => 'Formatted Contents Note',
            pchrs => {
                r  => ' / ',
                t  => ' -- ',
                tn => ' -- ',
                gn => ' -- ',
            },
            wrap   => { g => [ '(', ')' ] },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§3.9 restrictions on access): $b/$c/$d/$e '; ',
        # $f '. ', $u ': '. $a N/A.
        '506' => {
            name  => 'Restrictions on Access Note',
            pchrs => {
                b => '; ',
                c => '; ',
                d => '; ',
                e => '; ',
                f => '. ',
                u => ': ',
            },
        },

        # ISBD punct (§3.10 scale note for graphic material): $b '; '.
        # $a N/A.
        '507' => {
            name  => 'Scale Note for Graphic Material',
            pchrs => { b => '; ' },
        },

        # ISBD punct (§4.26 creation/production credits): repeatable $a
        # separated by ' ; ' via the COMPOUND pchrs key `aa` (fires only when
        # $a follows $a). A single $a gets no punct (a naive single `a` key
        # would also fire on $3-$a / any-X-$a, over-firing like 260's aa/ba
        # lesson).
        '508' => {
            name  => 'Creation/Production Credits Note',
            pchrs => { aa => ' ; ' },
        },

        # ISBD punct (§3.11 citation references): $b/$c/$x ', '. $a/$u N/A.
        '510' => {
            name  => 'Citation References Note',
            pchrs => {
                b => ', ',
                c => ', ',
                x => ', ',
            },
        },

        # ISBD punct (§4.27 participant or performer note): repeatable $a
        # separated by ' ; ' via the COMPOUND pchrs key `aa` (fires only when
        # $a follows $a). A single $a (even after $3) gets no punct.
        '511' => {
            name  => 'Participant or Performer Note',
            pchrs => { aa => ' ; ' },
        },

        # ISBD punct (§3.12 type of report and period covered): $b '; '.
        # $a N/A. (Spec table says "colon-space" but its own example uses
        # ' ; ' — we follow the example.)
        '513' => {
            name  => 'Type of Report and Period Covered Note',
            pchrs => { b => '; ' },
        },

        # ISBD punct (§4.28 numbering peculiarities): $z '. ' (source;
        # §4.20 allows preceding dash OR period-space; 515/525 pick '. ').
        '515' => {
            name  => 'Numbering Peculiarities Note',
            pchrs => { z => '. ' },
        },

        # ISBD punct: $a $z (takes preceding -- or .)
        # $z gets ' -- ' prepended
        # (from eliminated preceding dash or period-space)
        '520' => {
            name  => 'Summary, etc.',
            pchrs => {
                z => ' -- ',
            },
        },

        # ISBD punct (§4.30 supplement note): $z '. ' (source). $a N/A.
        '525' => {
            name  => 'Supplement Note',
            pchrs => { z => '. ' },
        },

        # ISBD punct (§3.13 study program information): only $i ': ' via
        # cb_pre (display text). $a/$b/$c/$d/$x/$z N/A.
        '526' => {
            name  => 'Study Program Information Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§3.14 additional physical form available): $b/$c/$d
        # '; '. $a/$u N/A.
        # $3 lead-in: suppress a following '; ' after $3 (see 541 comment).
        '530' => {
            name  => 'Additional Physical Form Available Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
            },
        },

        # ISBD punct: accessibility note — all subfields N/A (whole field is
        # a single free-text note; NOT in the LoC/PCC spec, added in 2018 as
        # a NEW MARC field; listed here as an explicit empty block per the
        # K10plus isbd.py which also defines no punctuation for it).
        '532' => {
            name  => 'Accessibility Note',
        },

        # ISBD punct (§3.15 reproduction note): $b '. ', $c ' : ', $d ', ',
        # $e/$m/$n '. ', $f '.()' (series statement wrapped in parens with a
        # preceding period — see the '.()' engine pattern in the module pod).
        # $a N/A. Uses the ENGINE '.()' sentinel: a bare '.' is appended to
        # the preceding subfield and the $f content is wrapped in ( ).
        '533' => {
            name  => 'Reproduction Note',
            pchrs => {
                b => '. ',
                c => ' : ',
                d => ', ',
                e => '. ',
                f => '.()',
                m => '. ',
                n => '. ',
            },
        },

        # ISBD punct (§3.16 original version note): most content subfields
        # '. ', $f '.()' (parens), $p trailing ': ' (post). A subfield
        # following $p gets no extra '. ' because $p already ends in ':'
        # (engine colon-skip dedup). $a N/A.
        '534' => {
            name  => 'Original Version Note',
            pchrs => {
                b => '. ',
                c => '. ',
                e => '. ',
                f => '.()',
                k => '. ',
                l => '. ',
                m => '. ',
                n => '. ',
                o => '. ',
                t => '. ',
                x => '. ',
                z => '. ',
            },
            post => { p => ': ' },
        },

        # ISBD punct (§3.17 location of originals/duplicates): $b/$c/$d '; '.
        # $a/$g N/A. $3 lead-in suppressed via empty COMPOUND keys.
        '535' => {
            name  => 'Location of Originals/Duplicates Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
            },
        },

        # ISBD punct (§4.31 system details): $i ': ' via cb_pre (display
        # text). $a/$u N/A.
        '538' => {
            name  => 'System Details Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§3.18 terms governing use and reproduction):
        # $b/$c/$d '; ', $u ': '. $a N/A. $3 lead-in suppressed.
        '540' => {
            name  => 'Terms Governing Use and Reproduction Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                u  => ': ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
                '3u' => '',
            },
        },

        # ISBD punct (§3.19 immediate source of acquisition): $a/$b/$c/$d/$e/
        # $f/$h/$n '; '. $o N/A.
        # $3 (materials specified) is a leading control subfield — it never
        # takes a following '; '. When $3 precedes a keyed subfield, suppress
        # via explicit empty COMPOUND keys '3a'/'3b'/... (compound precedence
        # over the single key; '' appends nothing). Without these, a blanket
        # single key would append a spurious '; ' to $3 (the doc's "$3 Ref
        # print $c ..." / "$3 5 diaries $n ..." show no punct after $3).
        '541' => {
            name  => 'Immediate Source of Acquisition Note',
            pchrs => {
                a  => '; ',
                b  => '; ',
                c  => '; ',
                d  => '; ',
                e  => '; ',
                f  => '; ',
                h  => '; ',
                n  => '; ',
                '3a' => '',
                '3b' => '',
                '3c' => '',
                '3d' => '',
                '3e' => '',
                '3f' => '',
                '3h' => '',
                '3n' => '',
            },
        },

        # ISBD punct (§3.20 location of other archival materials):
        # $a/$b/$c/$e '; '. $d/$n N/A.
        # $3 lead-in: suppress a following '; ' after $3 via explicit empty
        # COMPOUND keys (see the 541 comment for the rationale).
        '544' => {
            name  => 'Location of Other Archival Materials Note',
            pchrs => {
                a  => '; ',
                b  => '; ',
                c  => '; ',
                e  => '; ',
                '3a' => '',
                '3b' => '',
                '3c' => '',
                '3e' => '',
            },
        },

        # ISBD punct (§3.21 language note): $b '; '. $a N/A. $3 lead-in
        # suppressed.
        '546' => {
            name  => 'Language Note',
            pchrs => {
                b  => '; ',
                '3b' => '',
            },
        },

        # ISBD punct (§4.32 former title complexity): $i ': ' via cb_pre
        # (display text). $a N/A.
        '547' => {
            name  => 'Former Title Complexity Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§4.33 issuing body): $i ': ' via cb_pre (display
        # text). $a N/A.
        '550' => {
            name  => 'Issuing Body Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§3.22 cumulative index/finding aids): $b/$c/$d '; ',
        # $u '. '. $a N/A. $3 lead-in suppressed.
        '555' => {
            name  => 'Cumulative Index/Finding Aids Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                u  => '. ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
                '3u' => '',
            },
        },

        # ISBD punct (§3.23 copy and version identification): $b/$c/$d/$e
        # '; '. $a N/A. $3 lead-in suppressed.
        '562' => {
            name  => 'Copy and Version Identification Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                e  => '; ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
                '3e' => '',
            },
        },

        # ISBD punct (§3.24 case file characteristics): $b/$c/$d/$e '; '.
        # $a N/A. $3 lead-in suppressed.
        '565' => {
            name  => 'Case File Characteristics Note',
            pchrs => {
                b  => '; ',
                c  => '; ',
                d  => '; ',
                e  => '; ',
                '3b' => '',
                '3c' => '',
                '3d' => '',
                '3e' => '',
            },
        },

        # ISBD punct (§4.34 linking entry complexity): repeatable $i ': '
        # via cb_pre (display text); $a repeatable but N/A (no punct between
        # $a runs; intervening $i carries the ':' ).
        # GAP: the §4.34 example's comma before a later $i ("$a ... (1977),
        # to form: ...") is NOT reproduced by any rule (belongs to neither
        # the $a value nor the $i) — we omit it following K10plus; status
        # unclear, may need review.
        '580' => {
            name  => 'Linking Entry Complexity Note',
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # ISBD punct (§3.25 accumulation and frequency of use): $a/$b '. '.
        # $3 lead-in suppressed (doc shows "$3 General subject files $a ...",
        # no '.' after $3).
        '584' => {
            name  => 'Accumulation and Frequency of Use Note',
            pchrs => {
                a  => '. ',
                b  => '. ',
                '3a' => '',
                '3b' => '',
            },
        },

        # Same pchrs/wrap as 100 but:
        #   - $v (form subdivision) gets NO punctuation
        #        (deliberately excluded)
        #   - $x, $y, $z (general/chronological/geographic subdivisions)
        #     also excluded
        '600' => {
            name  => 'Subject Added Entry – Personal Name',
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

        # Same pchrs/wrap as 110 but:
        #   - $v (form subdivision) gets NO punctuation
        #     (deliberately excluded)
        #   - $x, $y, $z (general/chronological/geographic subdivisions)
        #     also excluded Title-portion (§5.5) keys retained
        #     (as for x00=600).
        '610' => {
            name  => 'Subject Added Entry – Corporate Name',
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

        # Same as 111 but $v/$x/$y/$z (subject subdivisions) get NO punctuation
        # (111 has no $v; subject '/x/y/z are deliberately excluded).
        # Title-portion (§5.5) keys retained, as for x00=600.
        '611' => {
            name  => 'Subject Added Entry – Meeting Name',
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
            name  => 'Subject Added Entry – Uniform Title',
            pchrs => {
                e => ', ',    # 630-only: relator term (spec §5.5)
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
                    @_, 'b', ' : ' );
            },
        },

        # Only $a exists, and it is N/A -> NO punctuation. Explicit empty
        # rule block so the field is visibly 'handled' (no-op) rather than
        # accidentally overlooked.
        '648' => {
            name => 'Subject Added Entry – Chronological Term',
        },

        # ISBD punct (§5.6 Subjects):
        #   $a (topical term) N/A; $v/$x/$y/$z (form/general/chronological/
        #   geographic subdivisions) N/A. So only:
        #   $b (topical after geographic) -> '. '  (650 only)
        #   $c (location of event)        -> ', '  (650 only)
        #   $d (active dates)             -> ', '  (650 only)
        #   $e (relator term)             -> ', '  (650 + 651)
        #   $h (inverted text)            -> ', '  (new; may follow $a/$c/$x)
        #   $j (remaining text)           -> ', '  (650 only, new)
        #   $g (qualifying info)          -> one paren pair '(...)', multiple
        #       $g separated by ' : ' (spec §5.6 / §5.7). Same structural
        #       pattern as 020 $q / 210 $b / 222 $b / 240 $b, so the shared
        #       _decorate_qualifier_group_pre callback is reused.
        #
        #   NOTE (2026-09-03): a single $g wraps as '(val)' with NO leading
        #   space, matching the existing qualifier-group behaviour (020/210/
        #   222/130/240). The spec examples print 'Val (val)' with a space
        #   before '(' — this is the known subfield-concatenation spacing gap
        #   (same family as 020 '...0723804(acid-free paper)'), awaiting an
        #   ISBD-expert ruling; not fixed here.
        '650' => {
            name  => 'Topical Subject',
            pchrs => {
                b => '. ',
                c => ', ',
                d => ', ',
                e => ', ',
                h => ', ',
                j => ', ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'g', ' : ' );
            },
        },

        # $a N/A; $e (relator) -> ', '; $g qualifier group '(...)'/' : ';
        # $v/$x/$y/$z N/A. ($b is 650-only — 651 has no $b.)
        '651' => {
            name  => 'Geographic Subject',
            pchrs => {
                e => ', ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'g', ' : ' );
            },
        },

        # $a/$b/$c N/A; $v/$x/$y/$z N/A; so only $h (inverted text) -> ', '
        # and the $g qualifier group '(...)'/' : '.
        '655' => {
            name  => 'Index Term – Genre/Form',
            pchrs => {
                h => ', ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_qualifier_group_pre(
                    @_, 'g', ' : ' );
            },
        },

        # Both are the SAME shape as 655: $a/$k N/A (656) / $a N/A (657),
        # $v/$x/$y/$z N/A, so the only punctuation is $h -> ', ' and the
        # $g qualifier group. Alias to 655.
        '656' => {
            name      => 'Index Term – Occupation',
            use_rules => '655',
        },

        '657' => {
            name      => 'Index Term – Function',
            use_rules => '655',
        },

        # All subfields ($a/$b/$c/$d) are N/A -> NO punctuation. Explicit
        # empty rule block (same rationale as 648).
        '658' => {
            name => 'Index Term – Curriculum Objective',
        },

        # Identical structure to 100
        '700' => {
            name      => 'Added Entry – Personal Name',
            use_rules => '100',
        },

        # Identical structure to 110
        '710' => {
            name      => 'Added Entry – Corporate Name',
            use_rules => '110',
        },

        # Identical structure to 111
        '711' => {
            name      => 'Added Entry – Meeting Name',
            use_rules => '111',
        },

        # Same §5.5 uniform-title block as 240. 730 ADDS $i (relationship
        # information, 730 only) and $x (ISSN, 730/830... only) — both are
        # **N/A / no punctuation** per §5.5, i.e. they need NO pchrs key and
        # just pass through, which the 240 block already provides. So a
        # direct alias is exact for the implemented subfields.
        '730' => {
            name      => 'Added Entry – Uniform Title',
            use_rules => '240',
        },

        # ISBD punct (§4.35 linking-entry fields): content subfields get a
        #   preceding '. ' ($b $c $d $g $h $k $m $n $p $s $t $1) — the period
        #   lands on the PREVIOUS subfield in postfix, so N/A $a still ends
        #   its heading; $i (relationship info) ': ' via the shared
        #   display-text cb_pre. $e/$f (775), $j (786) and
        #   $o/$q/$r/$u/$v/$w/$x/$y/$z N/A (no punctuation).
        #
        # DECISIONS / GAPS:
        #   - All 16 §4.35 tags share this exact table -> 760 is canonical;
        #     761..787 alias it via use_rules.
        #   - Embedded-field $j/$1 encoding NOT processed: $j is N/A and $1
        #     takes a preceding '. ' like any content subfield.
        '760' => {
            name  => 'Main Series Entry',
            pchrs => {
                b   => '. ',
                c   => '. ',
                d   => '. ',
                g   => '. ',
                h   => '. ',
                k   => '. ',
                m   => '. ',
                n   => '. ',
                p   => '. ',
                s   => '. ',
                t   => '. ',
                '1' => '. ',
            },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
        },

        # Identical structure to 760
        '761' => {
            name      => 'Subseries Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '762' => {
            name      => 'Subseries Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '765' => {
            name      => 'Original Language Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '767' => {
            name      => 'Translation Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '770' => {
            name      => 'Supplement/Special Issue Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '772' => {
            name      => 'Supplement Parent Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '773' => {
            name      => 'Host Item Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '774' => {
            name      => 'Constituent Unit Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '775' => {
            name      => 'Other Edition Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '776' => {
            name      => 'Additional Physical Form Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '777' => {
            name      => 'Issued With Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '780' => {
            name      => 'Preceding Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '785' => {
            name      => 'Succeeding Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '786' => {
            name      => 'Data Source Entry',
            use_rules => '760',
        },

        # Identical structure to 760
        '787' => {
            name      => 'Other Relationship Entry',
            use_rules => '760',
        },

        # Same as 100 but $v (volume) gets ' ;' punctuation (600 differs)
        '800' => {

            name  => 'Series Added Entry – Personal Name',
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

        # Same as 110 but $v (volume) gets ' ;' punctuation (610 differs)
        '810' => {
            name  => 'Series Added Entry – Corporate Name',
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

        # Same as 111 but $v (volume) gets ' ;' punctuation
        # (subject 611 differs)
        '811' => {
            name  => 'Series Added Entry – Meeting Name',
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

        # Same §5.5 uniform-title block as 240, PLUS $v (volume /
        # sequential designation) which per §5.5 gets ' ; ' (830 only,
        # alongside 800/810/811). $x (ISSN) is N/A (no punct). Mirrors the
        # 800/810/811 series pattern: same base block + a `v` key.
        '830' => {
            name  => 'Series Added Entry – Uniform Title',
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
                    @_, 'b', ' : ' );
            },
        },

    };
}

1;
