package Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::DACH;

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

Koha::Filter::MARC::ISBD4MARCPunctuation::RuleSet::DACH

=head1 DESCRIPTION

The I<D-A-CH> ISBD punctuation rule set. This is a self-contained reading
derived from the D-A-CH (Germany, Austria, Switzerland) ISBD rules, as encoded
in the reference files I<isbd.py> and I<add_isbd_punctuation.py> (project root),
which mirror the DNB/MARC21 practice. The set identifier used in the code and
in C<rules_for()> is C<DACH>; C<D-A-CH> is its display name.

This module is one of several possible I<rule sets> selectable by the plugin.
Each rule set is a self-contained hash in the shape of the legacy C<RULES>
constant: keys C<pchrs>, C<post>, C<wrap>, C<cb_pre>, C<cb_post>, C<use_rules>. This
set is FULLY self-contained: every tag's data comes from I<isbd.py>; it never
inherits from or references C<LoCPCC.pm> at load/runtime. Where a value happens
to coincide with the C<LoC/PCC> set, that is intentional (both sets use the same
punctuation for those fields).

Shared structural callbacks (the C<e/f/g> grouping in 260 and the C<n/d/c>
meeting grouping in the x10/x11 name fields) are referenced by I<method-name
string> and resolved via C<can()> by the engine (see
ISBD4MARCPunctuation::_resolve_cb). This keeps this data file a readable
mixture of pure data plus self-contained closures a no code duplication.

=cut

sub rules {
    return {

        # DACH (isbd.py ISBD015): $a/$z/$2 N/A; repeatable $q separated by
        # ' ; ' (plain - NOT wrapped in parens; differs from LoCPCC which groups
        # $q in one paren pair).
        '015' => {
            name  => 'National Bibliography Number',
            pchrs => { q => ' ; ' },
        },

        # DACH (isbd.py ISBD020): $a/$z N/A; $c ' : '; repeatable $q
        # separated by ' ; ' (plain - NOT wrapped in parens; differs from
        # LoCPCC which groups $q in one paren pair).
        '020' => {
            name  => 'International Standard Book Number',
            pchrs => {
                c => ' : ',
                q => ' ; ',
            },
        },

        # DACH (isbd.py ISBD024): $a/$d/$z N/A; $c ' : '; repeatable $q
        # separated by ' ; ' (plain - NOT wrapped in parens; differs from
        # LoCPCC which groups $q in one paren pair).
        '024' => {
            name  => 'Other Standard Identifier',
            pchrs => {
                c => ' : ',
                q => ' ; ',
            },
        },

        # ISBD punct: separating punctuation between subfields (§5.5):
        #   $a alone: no change (inversion comma already in $a)
        #   $c ', '  $d ', '  $e ', '  $f '. '  $j ', '
        #   $k '. '  $l '. '  $m ', '  $n '. '  $o '; '  $p ', '
        #   $q '()'  $r ', '  $s '. '  $t '. '  $v ' ;' (800 only)
        #   $i: left as-is (cataloguer ends it with ':')
        #
        # DECISIONS / GAPS:
        #   - $b (numeration) is N/A per §5.2 (e.g. John $b II -> John II,
        #     no '. '). The old `b => '. '` ghost-copied the x10 meaning
        #     (subordinate unit) into the personal-name blocks; removed.
        #   - $n '. ' / $p ', ' are the §5.5 LoC/PCC reading (aligned with
        #     x10/x11; e.g. Tolkien 700 "…rings. 2, Two towers").
        #   - §5.2 $a/$h split NOT in use: real records keep the inversion
        #     comma inside $a (e.g. "Morgan, Robert"), so $a passes through.
        # 700 (Added Entry) aliases this block.
        '100' => {
            name  => 'Main Entry – Personal Name',
            pchrs => {
                c => ', ',
                d => ', ',
                e => ', ',
                f => '. ',
                j => ', ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => ', ',   # DACH (isbd.py ISBDX00): $n ',' (LoCPCC uses '. ')
                o => '; ',
                p => '. ',   # DACH (isbd.py ISBDX00): $p '.' (LoCPCC uses ', ')
                r => ', ',
                s => '. ',
                t => '. ',
                # DACH (isbd.py) omits $h / $g -> no punctuation (placeholder)
            },
            wrap => { q => [ '(', ')' ] },   # $q qualifier wrapped (isbd.py q:'()')
        },

# DACH (isbd.py ISBDX10): name portion only - isbd.py does NOT define
# punctuation for the title-portion subfields $k/$l/$m/$f/$h/$j (LoCPCC has
# them via sec 5.5: k '. ', l '. ', m ', ', o '; ', f '. ', h '. ', j ', '
# + compound tn '. '). Per the mirror-isbd.py rule these get NO punct here;
# leave the LoCPCC values in this comment as a breadcrumb if a gap shows up.
#   $b '. '  $e ', '  $p ', '  $r ', '  $s '. '  $t '. '
#   $u '. '  (isbd.py adds $u '.'; LoCPCC leaves $u N/A)
# $n/$d/$c (meeting number/date/location) grouped in ONE paren pair by
# _decorate_x10_pre; separators via the cc/dc/nd compound keys.
#
# DECISIONS / GAPS:
#   - $n has NO broad single key: a plain `n => '. '` would over-fire on the
#     $n/$d/$c meeting group; only the COMPOUND keys fire within it (same as
#     LoCPCC; isbd.py also leaves `n` a no-op).
#   - Repeated $g: the shared _decorate_x10_pre groups them '(a : b)' (same as
#     LoCPCC). isbd.py ISBDX10 gives g:'()' which would wrap EACH $g as
#     '(a)(b)' - possibly intended, but we reuse the LoCPCC '(a : b)' grouping
#     (the extra mile LoCPCC went for repeated qualifiers). Noted for revisit.
        '110' => {
            name  => 'Main Entry – Corporate Name',
            pchrs => {
                b => '. ',
                c => ', ',
                d => ', ',
                e => ', ',
                p => ', ',
                r => ', ',
                s => '. ',
                t => '. ',
                u => '. ',   # isbd.py ISBDX10 u:'.' (LoCPCC N/A)

                # compound keys (meeting group separators), take precedence
                # over the single next_sf keys in _decorate_field
                cc => ' ; ',
                dc => ' : ',
                nd => ' : ',
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
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
      #   - Repeated $g: shared callback groups '(a : b)'; isbd.py ISBDX11
      #     g:'()' would wrap each as '(a)(b)' - possibly intended (same as x10).
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # DACH (isbd.py ISBDX30, main entry): uniform title. isbd.py treats
        # X30 DIFFERENTLY from ISBD240 (130/630/730/830 are their own dict):
        #   $d '('')'  and  $g '('')'  (wrapped individually, unlike 240's
        #     d ',' / g '.')
        #   $f '. '  $h '. '  $k '. '  $l '. '  $m ', '  $n '. '
        #   $o '; '  $p ', '  $r ', '  $s '. '  $t '. '
        #   $e/$i/$y/$z N/A (no rule)
        #   $v ' ;' and $x '. ' apply to 730/830 only -> their own blocks add them.
        # NOTE: LoCPCC 130 aliases 240; DACH does NOT (X30 != 240).
        '130' => {
            name  => 'Main Entry - Uniform Title',
            pchrs => {
                f => '. ',
                h => '. ',
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
                d => [ '(', ')' ],
                g => [ '(', ')' ],
            },
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

        # DACH (isbd.py ISBD240): uniform title.
        #   $d ', ' (NEW to DACH; LoCPCC keeps $d as a documented gap)
        #   $f '. '  $g '. '  $h '. '  $k '. '  $l '. '  $m ', '
        #   $n ', ' + compound nn '. ' (n-then-n)  -- isbd.py n:',', nn:'.'
        #   $o '; '  $p '. '  $r ', '  $s '. '
        #
        # DECISIONS / GAPS:
        #   - $b (qualifying info): isbd.py 240 has NO $b key -> no punct here
        #     (LoCPCC groups it in parens via cb_pre; dropped to mirror isbd.py).
        #   - $p '. ' (isbd.py) vs LoCPCC ', ' - follow isbd.py.
        #   - LoCPCC's $j ', ' (Appendix B) is NOT in isbd.py ISBD240 -> dropped.
        '240' => {
            name  => 'Uniform Title',
            pchrs => {
                d => ', ',
                f => '. ',
                g => '. ',
                h => '. ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => ', ',
                nn => '. ',   # $n followed by $n -> '. ' (isbd.py nn:'.')
                o => '; ',
                p => '. ',
                r => ', ',
                s => '. ',
            },
        },

        # DACH (isbd.py ISBD242): $a ' ;' (SUBSEQUENT same-author title;
        # LoCPCC left 242 $a unkeyed - added here per isbd.py), $b ' : ',
        # $c ' / ', $n '. ', $p ', '; $h wrapped [ ].  isbd.py 242 does NOT
        # define $e/$q -> dropped (LoCPCC 242 had e '. ' / q ', ').
        # $y (lang code) N/A.  $o: isbd.py notes it does not exist at LOC.
        '242' => {
            name  => 'Translation of Title by Cataloging Agency',
            pchrs => {
                a => ' ; ',
                b => ' : ',
                c => ' / ',
                n => '. ',
                p => ', ',
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

        # DACH (isbd.py ISBD245): $a N/A, $b ' : ', $c ' / ', $f ', ',
        # $k ' : ', $n '. ', $p ', ', $s '. '; $h wrapped [ ].
        # isbd.py 245 does NOT define $d/$e/$q/$r/$t -> dropped (mirror-
        # literally; LoCPCC had d ' ; ', e '. ', q ', ', r/t ' = ').
        # $o (conjunction) context-dependent, not encoded in MARC (gap).
        '245' => {
            name  => 'Title Statement',
            pchrs => {
                b => ' : ',
                c => ' / ',
                f => ', ',
                k => ' : ',
                n => '. ',
                p => ', ',    # Context: could be `. ` or `, `; we pick `, `
                ep => '. ',   # $p after $e (subsequent title by diff. author)
                s => '. ',
            },
            wrap => { h => [ '[', ']' ] },
        },

        # DACH (isbd.py ISBD246): $a N/A, $b ' : ', $n '. ', $p ', ';
        # $g wrapped ( ), $h wrapped [ ]; $i display-text ': ' via cb_pre.
        # isbd.py 246: $f ':'' (no punct - NOT ', ' as LoCPCC), and no
        # $q/$r/$t -> dropped (mirror-literally; LoCPCC had f ', ', q ', ',
        # r/t ' = ').
        '246' => {
            name  => 'Varying Form of Title',
            pchrs => {
                b => ' : ',
                n => '. ',
                p => ', ',
            },
            wrap   => { g => [ '(', ')' ], h => [ '[', ']' ] },
            cb_pre => sub {
                my ( $sf, $value ) = @_;
                return $sf eq 'i' ? "$value: " : $value;
            },
        },

        # DACH (isbd.py ISBD247): $a N/A, $b ' : ', $f ', ', $n '. ',
        # $p ', '; $g wrapped ( ), $h wrapped [ ]. isbd.py 247 does NOT
        # define $q/$r/$t -> dropped (mirror-literally; LoCPCC had q ', ',
        # r/t ' = '). No $i subfield.
        '247' => {
            name  => 'Former Title',
            pchrs => {
                b => ' : ',
                f => ', ',
                n => '. ',
                p => ', ',
            },
            wrap => { g => [ '(', ')' ], h => [ '[', ']' ] },

            # NOTE: No cb_pre — 247 has no $i subfield
        },

        # DACH (isbd.py ISBD249) - Weitere Titel bei Zusammenstellungen
        # (collective title / additional titles), GERMANY ONLY (DNB).
        # $a$v form ONE repeatable group (there can be many $a$v blocks):
        #   $a = a title (like 245 $a), $v = its statement/value (like 245 $c).
        # $b$c appear ONCE (not repeatable): $b like 245 $b, $c like 245 $c.
        # Rendering (isbd.py values):
        #   $a .. $v  -> within a block, ' /' between title and value
        #   $v .. next $a/$b -> '.' separates blocks
        #   $b .. $c  -> ' /' between the collective-title part and its value
        # isbd.py keys: a:'.', v:' /', b:'.', c:' /'
        # NOTE: '6a' (880-link) NOT handled - 880 not supported by the engine
        # (mirrors the LoCPCC 880 WON'T-DO). Documented gap.
        '249' => {
            name => 'Weitere Titel bei Zusammenstellungen (additional collective title)',
            pchrs => {
                a => '. ',
                v => ' / ',
                b => '. ',
                c => ' / ',
            },
        },

        # ISBD punct: $a / $c ; $d = $r = $t
        # DACH (isbd.py ISBD250): $a N/A; $b gets ' / '.
        # isbd.py 250 defines ONLY $b; LoCPCC's $c/$d/$r/$t are NOT defined
        # in isbd.py 250 -> no punct here (mirror-literally).
        '250' => {
            name  => 'Edition Statement',
            pchrs => {
                b => ' / ',
            },
        },

        # DACH (isbd.py ISBD254): $a N/A only - isbd.py 254 defines no
        # punctuation (LoCPCC had $r ' = ' for parallel musical presentation;
        # mirror-literally drops it). Explicit empty block (no-op).
        '254' => {
            name  => 'Musical Presentation Statement',
        },

        # DACH (isbd.py ISBD255): $a N/A; $b ' ; '.
        # isbd.py 255 has c:'(), d:'(), e:' ;' (i.e. $c/$d wrapped INDIVIDUALLY
        # and $e a preceding ' ;') - but we KEEP the LoCPCC c/d/e paren RUN-GROUP
        # (shared _decorate_paren_group_pre) instead: isbd.py again likely did
        # not go the extra mile to group c/d/e into one paren pair. Breadcrumb:
        # LoCPCC groups (c : d ; e) with cd/de separators; isbd.py does individual ().
        # isbd.py 255 defines NO $s/$v -> dropped (LoCPCC had s/v '. ' for
        # parallel/vertical scale; mirror-literally drops them).
        '255' => {
            name  => 'Cartographic Mathematical Data',
            pchrs => {
                b  => ' ; ',
                cd => ' ; ',
                de => ' ; ',
            },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_paren_group_pre(
                    @_, [qw(c d e)] );
            },
        },

        '258' => {
            name  => 'Philatelic Issue Data',
            pchrs => { b => ' : ' },
        },

        # DACH (isbd.py ISBD260): $a ' ;' (subsequent places) via aa/ba
        # compounds, $b ' : ', $c ', '; $3 ': ' via post; $e/$f/$g grouped in
        # parens by _decorate_260_pre (isbd.py enclose_in_parentheses(e,f,g)).
        # isbd.py 260 does NOT define $r/$t/$q -> dropped (LoCPCC had r/t ' = '
        # + wrap q; mirror-literally omits them). aa/ba (not bare `a`) so a
        # $3$a doesn't over-fire a ' ;' before the post ': '.
        '260' => {
            name  => 'Publication, Distribution, etc. (Imprint)',
            pchrs => {
                aa => ' ; ',
                ba => ' ; ',
                b  => ' : ',
                c  => ', ',
            },
            post   => { 3 => ': ' },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_260_pre',
        },

        # DACH (isbd.py ISBD264): $a ' ;' (subsequent places) via aa/ba
        # compounds, $b ' : ', $c ', '; $3 ': ' via post. $r/$t (parallel
        # imprint) and $q (address) are NOT defined in isbd.py 264 -> dropped
        # (LoCPCC has r ' = '/t ' = '/wrap q; mirror-literally omits them).
        # aa/ba compounds (NOT a bare single `a`) so a $3$a doesn't over-fire
        # a ' ;' before the post ': '.
        '264' => {
            name =>
'Production, Publication, Distribution, Manufacture, and Copyright',
            pchrs => {
                aa => ' ; ',
                ba => ' ; ',
                b  => ' : ',
                c  => ', ',
            },
            post => { 3 => ': ' },
        },

        # ISBD punct: $a : $b ; $c + $e ($h : $i ; $j)
        # $e gets preceding + (accompanying material).
        # $h/$i/$j (details of accompanying material) are grouped in ONE
        # paren pair by _decorate_300_pre, anchored on $h (doc sec 4.14
        # example: $e 1 atlas $h ... $i color maps $j 37 cm ->
        #   1 atlas (... : color maps ; 37 cm)).
        # Internal separators via COMPOUND pchrs keys (like x10's nd/dc/cc):
        #   hi => ' : ' (between $h and $i)
        #   ij => ' ; ' (between $i and $j)
        #   hj => ' ; ' (between $h and $j, when no $i)
        # $a+ (scores with parts) gets preceding +: isbd.py 300 uses ba/ca
        # (compound, fires after $b/$c only) - applied here per isbd.py.
        #
        # LOPCC-RULE LACKING IN isbd.py: the $h/$i/$j accompanying-material
        # group is implemented in LoCPCC (from reference doc sec 4.14) but is
        # ABSENT from isbd.py 300 (which is bare b/c/e + ba/ca, no $h). We KEEP
        # it in DACH (doc-backed; $h/$i/$j are the new sec 4.14 subfields).
        # KNOWN GAP: a lone $i or $j (no leading $h) is the §4.14 "or" case
        #            and is left to cataloguers WITHOUT parentheses (same as
        #            LoCPCC; see _decorate_300_pre pod).
        '300' => {
            name  => 'Physical Description',
            pchrs => {
                b  => ' : ',
                c  => ' ; ',
                e  => ' + ',
                ba => ' + ',  # $a after $b (scores with parts; isbd.py ba:' +')
                ca => ' + ',  # $a after $c (isbd.py ca:' +')
                hi => ' : ',
                ij => ' ; ',
                hj => ' ; ',
            },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_300_pre',
        },

        # ISBD punct (§3.5): $a N/A; $b (additional information) gets '; '.
        # (glued semicolon, matching the doc Current form "M, 8:30-6:00; $b").
        '307' => {
            name  => 'Hours, etc.',
            pchrs => { b => '; ' },
        },

        # DACH (isbd.py ISBD310): $a N/A, $b ', '. isbd.py 310 defines no
        # $n (LoCPCC wrapped $n in parens for qualifying info; mirror-literally
        # drops it).
        '310' => {
            name  => 'Current Publication Frequency',
            pchrs => { b => ', ' },
        },

        # DACH (isbd.py ISBD321): identical to 310 - $b ', ' only, no $n.
        '321' => {
            name  => 'Former Publication Frequency',
            pchrs => { b => ', ' },
        },

        # DACH (isbd.py ISBD343): $a N/A; $b/$c/$d/$e/$g/$h/$i '; '.
        # isbd.py 343 has NO $f (LoCPCC 343 $f '; ' dropped; mirror-literally).
        '343' => {
            name  => 'Planar Coordinate Data',
            pchrs => {
                b => '; ',
                c => '; ',
                d => '; ',
                e => '; ',
                g => '; ',
                h => '; ',
                i => '; ',
            },
        },

        # ISBD punct (§3.7): $c N/A; $a and $b each get '; ' (glued; the
        # separator also fires after a N/A $c, per doc "$c Series; $a...").
        '351' => {
            name  => 'Organization and Arrangement of Materials',
            pchrs => {
                a => '; ',
                b => '; ',
            },
        },

        # ISBD punct (§4.18 series statement):
        #   $b ' : '  $c ' / '  $d ' ; '  $n '. '  $p ', '  $r ' = '
        #   $t ' = '  $v ' ; '  $x ', '  $y ' = '
        # $3 gets ': ' via post; $l wrapped (...).
        # GAP: $p can be '. ' or ', ' depending on context — we pick ', '.
        # ISBD punct (§3.8): $a N/A; $b ' : ' (first) / ', ' (repeated after
        # $c) via COMPOUND ab/cb; $g ', '; $i ' : '; $q ' ; '; $c = INDIVIDUAL
        # paren wrap (NOT in the d/e/f group); $d/$e/$f = one paren run-group
        # (shared _decorate_paren_group_pre) with ' x ' separators via COMPOUND
        # de/ef. DECISION: $c stays a SEPARATE wrap (doc ex 2 shows individual
        # (13671) (20171) pairs), not folded into the d/e/f group.
        '352' => {
            name  => 'Digital Graphic Representation',
            pchrs => {
                ab => ' : ',
                cb => ', ',
                g  => ', ',
                i  => ' : ',
                q  => ' ; ',
                de => ' x ',
                ef => ' x ',
            },
            wrap   => { c => [ '(', ')' ] },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_paren_group_pre(
                    @_, [qw(d e f)] );
            },
        },

        # DACH (isbd.py ISBD362): $a N/A, $z '. ' only. isbd.py 362 is
        # MINIMAL ({a:'', z:'.'}) - LoCPCC's fuller new-sequence/display-text
        # machinery (bb/bc/dc/e/f/i compounds + $d paren run-group) is NOT in
        # isbd.py 362 -> reduced here (mirror-literally; breadcrumb: LoCPCC had
        # bb ' ; ', bc/dc/f '- ', e ' = ', i empty, $d paren group).
        '362' => {
            name  => 'Dates of Publication and/or Sequential Designation',
            pchrs => {
                z => '. ',
            },
        },

        # DACH (isbd.py ISBD490): $l '()' (wrapped), $v ' ;', $x ', ';
        # $3 ': ' via post. isbd.py 490 defines ONLY these - LoCPCC's
        # $b/$c/$d/$n/$p/$r/$t/$y are NOT in isbd.py 490 -> dropped
        # (mirror-literally; breadcrumb: LoCPCC had b ' : ', c ' / ', d ' ; ',
        # n '. ', p ', ', r/t ' = ', y ' = ').
        '490' => {
            name  => 'Series Statement',
            pchrs => {
                v => ' ;',
                x => ', ',
            },
            post => { 3 => ': ' },
            wrap => { l => [ '(', ')' ] },
        },

        # DACH (isbd.py ISBD500): $a N/A only - no $z source subfield.
        # $i display-text ': ' kept via cb_pre (LoCPCC feature; isbd.py 500 =
        # {a:''} omits $i - in many German catalogues $i is a static display
        # string, so keeping it is useful). LoCPCC's $z ' -- ' dropped.
        '500' => {
            name  => 'General Note',
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

        # DACH (isbd.py ISBD502): (b) - c, d.
        # $b wrapped (), $c preceded by SINGLE dash ' -' (isbd.py c:' -';
        # LoCPCC uses double ' -- '), $d preceded comma.
        '502' => {
            name  => 'Dissertation Note',
            pchrs => {
                c => ' -',
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

        # DACH (isbd.py ISBD515): $a N/A only - isbd.py defines no $z.
        # LoCPCC 515 $z '. ' (source) dropped (mirror-literally). Empty block.
        '515' => {
            name  => 'Numbering Peculiarities Note',
        },

        # ISBD punct: $a $z (takes preceding -- or .)
        # $z gets ' -- ' prepended
        # (from eliminated preceding dash or period-space)
        # DACH (isbd.py ISBD520): $a/$c/$u N/A; $b gets '. '.
        # LoCPCC uses $z ' -- '; isbd.py 520 uses $b '.' - subfield map delta.
        '520' => {
            name  => 'Summary, etc.',
            pchrs => {
                b => '. ',
            },
        },

        # DACH (isbd.py ISBD525): $a N/A only - isbd.py defines no $z.
        # LoCPCC 525 $z '. ' (source) dropped (mirror-literally). Empty block.
        '525' => {
            name  => 'Supplement Note',
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
        # DACH isbd.py which also defines no punctuation for it).
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

        # DACH (isbd.py ISBD534): most content subfields '. ', $f '.()'
        # (parens), $k ': ' (isbd.py k:':' - LoCPCC had k '. '), $x ', '
        # (isbd.py x:',' - LoCPCC had x '. '), plus compound tc ', ' ($t then
        # $c). $p trailing ': ' via post (isbd.py says $p always ends with ':').
        # $a N/A. Mirror-literally; breadcrumbs above where we deviate from
        # LoCPCC. $z '. ' (isbd.py z:'.').
        '534' => {
            name  => 'Original Version Note',
            pchrs => {
                b => '. ',
                c => '. ',
                e => '. ',
                f => '.()',
                k => ': ',
                l => '. ',
                m => '. ',
                n => '. ',
                o => '. ',
                t => '. ',
                tc => ', ',
                x => ', ',
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
        # the $a value nor the $i) — we omit it following DACH; status
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
                c => ', ',
                d => ', ',
                e => ', ',
                f => '. ',
                h => ', ',
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            wrap   => { q => [ '(', ')' ] },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_paren_group_pre(
                    @_, ['g'] );
            },
        },

        # Same pchrs/wrap as 110 but:
        #   - $v (form subdivision) gets NO punctuation
        #        (deliberately excluded)
        #   - $x, $y, $z (general/chronological/geographic subdivisions)
        #     also excluded Title-portion (§5.5) keys retained
        #     (as for x00=600).
        # DACH (isbd.py ISBDX10, subject): $c/$d/$u ADDED 2026-09-14 to match
        # the isbd.py X10 base (c:',', d:',', u:'.') - they were missing here
        # while present in the main-entry 110. $g grouping kept via gg key +
        # shared _decorate_x10_pre.
        '610' => {
            name  => 'Subject Added Entry – Corporate Name',
            pchrs => {
                b  => '. ',
                c  => ', ',   # isbd.py ISBDX10 c (2026-09-14: was missing)
                d  => ', ',   # isbd.py ISBDX10 d (2026-09-14: was missing)
                e  => ', ',
                p  => ', ',
                r  => ', ',
                s  => '. ',
                t  => '. ',
                u  => '. ',   # isbd.py ISBDX10 u (2026-09-14: was missing)
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # Same §5.5 uniform-title block as 240/243/730/830, PLUS the ONE
        # subject-only subfield: $e (relator term, 630 only) -> ', ' per
        # §5.5. $v (volume) is NOT in 630 (830 only); $x/$y/$z subject
        # subdivisions have no punct here (uniform-title block defines none
        # of them). DACH confirms the family grouping (its ISBDX30 is
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
                t => '. ',   # 630: $t '. ' (isbd.py X30 t:'.')
            },
            wrap => {
                d => [ '(', ')' ],   # 630: $d wrapped ( ) (isbd.py X30 d:'()')
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

        # DACH (isbd.py ISBDX30, added entry): same X30 block as 130 but ADDS
        # $x '. ' (ISSN; isbd.py x:'.' for 730/830). $d/$g wrapped individually.
        # $v ' ;' is 830-only (see 830). LoCPCC 730 aliases 240; DACH does NOT.
        '730' => {
            name  => 'Added Entry - Uniform Title',
            pchrs => {
                f => '. ',
                h => '. ',
                k => '. ',
                l => '. ',
                m => ', ',
                n => '. ',
                o => '; ',
                p => ', ',
                r => ', ',
                s => '. ',
                t => '. ',
                x => '. ',
            },
            wrap => {
                d => [ '(', ')' ],
                g => [ '(', ')' ],
            },
        },

        # DACH (isbd.py ISBD7XX): content subfields get a preceding
        # '. ' ($b $c $d $g $h $k $m $n $p $s $t) - same set as LoCPCC but
        # WITHOUT $1 (isbd.py 7XX has no embedded-field $1 key). PLUS the
        # compound ab ': ' (isbd.py ab:' :' - a $b DIRECTLY after $a gets ' :'
        # instead of the '. ' that a standalone $b would take, e.g.
        # $a heading : $b title). LoCPCC 760 has only `b => '. '`, so it
        # renders $a$b with '. '; DACH mirrors isbd.py via the ab compound
        # (compound takes precedence over the single `b` key in the engine).
        # $i (relationship info) ': ' via the shared display-text cb_pre
        # (isbd.py appends ':' to $i via its I_TAGS loop - same effect).
        # $e/$f/$j/$o/$q/$r/$u/$v/$w/$x/$y/$z N/A.
        #
        # DECISIONS / GAPS:
        #   - All 15 sec 4.35 tags share this exact table -> 760 is canonical;
        #     762..787 alias it via use_rules.
        #   - Embedded-field $j/$1 encoding NOT processed.
        '760' => {
            name  => 'Main Series Entry',
            pchrs => {
                b   => '. ',
                ab  => ' : ',
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
            },
            cb_pre =>
              'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_display_text_pre',
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
                c => ', ',
                d => ', ',
                e => ', ',
                f => '. ',
                h => ', ',
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            wrap   => { q => [ '(', ')' ] },
            cb_pre => sub {
                return
                  Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_paren_group_pre(
                    @_, ['g'] );
            },
        },

        # Same as 110 but $v (volume) gets ' ;' punctuation (610 differs)
        # DACH (isbd.py ISBDX10, series): $c/$d/$u ADDED 2026-09-14 to match
        # the isbd.py X10 base (c:',', d:',', u:'.') - they were missing here
        # while present in the main-entry 110. $g grouping kept via gg key +
        # shared _decorate_x10_pre.
        '810' => {
            name  => 'Series Added Entry – Corporate Name',
            pchrs => {
                b  => '. ',
                c  => ', ',   # isbd.py ISBDX10 c (2026-09-14: was missing)
                d  => ', ',   # isbd.py ISBDX10 d (2026-09-14: was missing)
                e  => ', ',
                p  => ', ',
                r  => ', ',
                s  => '. ',
                t  => '. ',
                u  => '. ',   # isbd.py ISBDX10 u (2026-09-14: was missing)
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
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
                gg => ' : ',   # repeated $g qualifier -> (a : b) (2026-09-09)
            },
            cb_pre => 'Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_x10_pre',
        },

        # DACH (isbd.py ISBDX30, series added entry): same X30 block as 130
        # but ADDS $v ' ;' (volume; isbd.py v:' ;' for 830) and $x '. ' (ISSN;
        # x:'.' for 830). $d/$g wrapped individually. NO $b group (isbd.py X30
        # omits $b). LoCPCC 830 has its own block with a $b cb_pre group;
        # DACH mirrors isbd.py and drops it.
        '830' => {
            name  => 'Series Added Entry - Uniform Title',
            pchrs => {
                f => '. ',
                h => '. ',
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
                x => '. ',
            },
            wrap => {
                d => [ '(', ')' ],
                g => [ '(', ')' ],
            },
        },

    };
}

1;
