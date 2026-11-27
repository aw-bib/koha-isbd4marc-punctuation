# ISBD4MARC Punctuation (HKS3)

This plugin adds a record processor filter for XSLT display processing via the
`xslt_record_processor_filters` hook.

## Hook

The plugin registers the `ISBD4MARCPunctuation` filter during XSLT processing.

- `Koha/Filter/MARC/ISBD4MARCPunctuation.pm`

The hook was implemented in 
https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=40972
and released in 26.05 and pushed to 25.11.x

## Documentation

### What it does

The filter adds ISBD punctuation for display when a MARC record was cataloged
without punctuation. It runs in XSLT display processing and does not change
stored MARC records.

Trigger condition:

- `Leader/18` is `n` or `c`

Implemented fields:

- `015`: National Bibliography Number
- `020`: International Standard Book Number
- `024`: Other Standard Identifier
- `100`: Main Entry – Personal Name
- `110`: Main Entry – Corporate Name
- `111`: Main Entry – Meeting Name
- `130`: Main Entry – Uniform Title
- `210`: Abbreviated Title
- `222`: Key Title
- `240`: Uniform Title
- `242`: Translation of Title by Cataloging Agency
- `243`: Collective Uniform Title
- `245`: Title Statement
- `246`: Varying Form of Title
- `247`: Former Title
- `250`: Edition Statement
- `254`: Musical Presentation Statement
- `255`: Cartographic Mathematical Data
- `258`: Philatelic Issue Data
- `260`: Publication, Distribution, etc. (Imprint)
- `264`: Production, Publication, Distribution, Manufacture, and Copyright Notice
- `300`: Physical Description
- `307`: Hours, etc.
- `310`: Current Publication Frequency
- `321`: Former Publication Frequency
- `343`: Planar Coordinate Data
- `351`: Organization and Arrangement of Materials
- `352`: Digital Graphic Representation
- `362`: Dates of Publication and/or Sequential Designation
- `490`: Series Statement
- `500`: General Note
- `501`: With Note
- `502`: Dissertation Note
- `504`: Bibliography, etc. Note
- `505`: Formatted Contents Note
- `506`: Restrictions on Access Note
- `507`: Scale Note for Graphic Material
- `508`: Creation/Production Credits Note
- `510`: Citation/References Note
- `511`: Participant or Performer Note
- `513`: Type of Report and Period Covered Note
- `515`: Numbering Peculiarities Note
- `520`: Summary, etc.
- `525`: Supplement Note
- `526`: Study Program Information Note
- `530`: Additional Physical Form Available Note
- `533`: Reproduction Note
- `534`: Original Version Note
- `535`: Location of Originals/Duplicates Note
- `538`: System Details Note
- `540`: Terms Governing Use and Reproduction Note
- `541`: Immediate Source of Acquisition Note
- `544`: Location of Other Archival Materials Note
- `546`: Language Note
- `547`: Former Title Complexity Note
- `550`: Issuing Body Note
- `555`: Cumulative Index/Finding Aids Note
- `562`: Copy and Version Identification Note
- `565`: Case File Characteristics Note
- `580`: Linking Entry Complexity Note
- `584`: Accumulation and Frequency of Use Note
- `600`: Subject Added Entry – Personal Name
- `610`: Subject Added Entry – Corporate Name
- `611`: Subject Added Entry – Meeting Name
- `630`: Subject Added Entry – Uniform Title
- `648`: Subject Added Entry – Chronological Term
- `650`: Subject Added Entry – Topical Term
- `651`: Subject Added Entry – Geographic Name
- `655`: Index Term – Genre/Form
- `656`: Index Term – Occupation
- `657`: Index Term – Function
- `658`: Index Term – Curriculum Objective
- `700`: Added Entry – Personal Name
- `710`: Added Entry – Corporate Name
- `711`: Added Entry – Meeting Name
- `730`: Added Entry – Uniform Title
- `760`: Main Series Entry
- `762`: Subseries Entry
- `765`: Original Language Entry
- `767`: Translation Entry
- `770`: Supplement/Special Issue Entry
- `772`: Supplement Parent Entry
- `773`: Host Item Entry
- `774`: Constituent Unit Entry
- `775`: Other Edition Entry
- `776`: Additional Physical Form Entry
- `777`: Issued With Entry
- `780`: Preceding Entry
- `785`: Succeeding Entry
- `786`: Data Source Entry
- `787`: Other Relationship Entry
- `800`: Series Added Entry – Personal Name
- `810`: Series Added Entry – Corporate Name
- `811`: Series Added Entry – Meeting Name
- `830`: Series Added Entry – Uniform Title

The list above is the `LoC/PCC` set. The `D-A-CH` set covers the same tags plus
the following two, which exist only in that set:

- `249`: Former Title
- `532`: Accessibility Note

They are listed separately because they are not `LoC/PCC` fields: `249` is a
pre-246 variant used in German-speaking practice, and `532` is a MARC field
added in 2018 that the PCC reference document does not cover.

### Why it does this

The approach follows the LoC/PCC direction to keep punctuation-light MARC for
storage/editing while generating readable ISBD-like punctuation at display
time.

For the implemented fields punctuation handling follows:

- https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf

### Reference coverage

Every example given in the reference document (its `Current` / `Future`
pairs, per field) is covered by the test suite, either pinned verbatim
(`# render: [doc section X.Y #N]` markers) or classified as derived,
NOT-HANDLED, or a documented DECISION. The one section deliberately left
out is **section 4.1** (the leader/18 byte): it is not a MARC field, so it
cannot be rendered by the field hooks, and its `Current`/`Future` describe
the punctuation-omission trigger the plugin keys on rather than a field
render. Its logic is exercised directly in `t/22-filter.t`. `t/99` asserts
this coverage stays complete on every run (see below).

### Librarians Note

For documentation and especially to make it easier for _librarians_ to
check the correctness every test holds a line that gives the
literal field that is handled in this test _without_ the punctuation.
E.g. the 245 regression tests have a line

  `# render: 245 14 $a The plays of Oscar Wilde $c Alan Bird`

So the acompanying test will render a title statement of this form and
add the neccesary punctuation.

`scripts/render_examples.pl` can be used to extract these lines from
the unit tests, pass them through the plugin and write the results to
a simple markdown file called `koha-isbd4marc-puncuation-output.md` in
the examples-folder. This file is sorted by MARC tags and gives the
output in a more librarian friendly form. The example above would
yield the following block:

---
No punctuation (LDR/18 = c or n):
```
  245 14 $a The plays of Oscar Wilde $c Alan Bird
```
_Postfix_ punctuation (automatic):
```
  245 14 $a The plays of Oscar Wilde /  $c Alan Bird
```
_Combined string_ (concatenation of the postfix values):
```
  The plays of Oscar Wilde /  Alan Bird
```
---

So it states first the MARC without puncutation, then the MARC as it
gets decorated by the plugin by _appending_ punctuation to a subfield
(denoted as _postfix_), and finally the concatenated display string.
(The `prefix` mode — adding punctuation to the start of the subsequent
subfield — produces the same combined string, so it is not shown
separately.) Especially, the first form should allow experts in the
field to judge what can be done automatically and where human
expertise is required to get complex entries right.

If needs be it is easy enough for any administrator to pass the
`md`-file through `pandoc` to generate other formats even more
digestible than Markdown.

### Technical Notes

#### Automatic tests

As puctuation is quite involved, so for all fields there is a quite
comprehensive test coverage in `t/`. Those tests are mainly extracted
from `Current` and `Future` lines of the reference document, so it
should be easy to verify those. The unittest are meant to ensure that
future changes to the code does not break the rules already derived
and are meant for programmers and machines.

#### Reproducing the coverage gate

The test suite is driven by the `Current` / `Future` examples in the
reference document, so a gate (`t/99-doc-coverage.t`) proves on every
run that every in-scope example is still covered. The tool chain is:

1. **Reference document.** The `.pdf` is fetched from the LoC/PCC page
   above and converted to plain text with `pdftotext`; the text file
   (`isbdmarc2016.txt`, project root) is what the tooling reads.
   `scripts/fetch_reference_doc.pl` does this in one step (downloads only
   when the file is absent); `./run_tests.sh` calls it automatically when
   the text is missing.
2. **Index.** `scripts/build_doc_index.pl` turns that text file into a
   JSON index of `Current` / `Future` pairs keyed by section (`X.Y`).
3. **Coverage table.** `scripts/doc_coverage.pl` reads the `# render:`
   markers in `t/*.t` (the single source of truth) and emits
   `docs/doc_coverage.yaml`.
4. **Gate.** `t/99-doc-coverage.t` (a) regenerates the YAML and checks
   it is byte-identical to the committed one, and (b) builds the index
   at test time and asserts every in-scope section is fully covered,
   allowing only the declared section-4.1 exclusion.

Run the whole suite with `./run_tests.sh`. The reference document and
its text form are not committed to the repository for copyright
reasons; keep `isbdmarc2016.txt` at the project root (next to this
repo) — the default the tooling and tests use — or point `ISBD_REF_DOC`
at its location if you keep it elsewhere. If it is missing, the suite
fetches+prepares it once, or `t/99` explains how when run on its own.

#### Rule sets

The punctuation rules are organised as **rule sets**, one per
catalogue tradition. Currently there are two sets:
- **`LoC/PCC`** (the default, following the reference document above)
- **`D-A-CH`** (the German, Austrian and Swiss cataloguing practice,
  as applied by the German union catalogues). These rules were kindly
  provided by BSZ and are used in their migration scripts.

A `None` set (no automatic punctuation) is also supported. Each set is
fully self-contained: `LoC/PCC` follows the reference document above, and
`D-A-CH` mirrors the `isbd.py` reference that BSZ use in their migration
scripts (the two are independent data, not programmatic deltas of each
other). The `D-A-CH`-only fields `249` and `532` live only in that set.

Note on naming: the set's *identifier* in the code (package and file name,
the `rules_for()` argument, the test suites) is `DACH` - ASCII and without
hyphens. `D-A-CH` is its *display name*, i.e. the spelling used in user-facing
text such as this README, and it is reported by `ruleset_label('DACH')`. In
other words: **the `D-A-CH` rules are implemented in the `DACH` module.**

- Each set lives in its own package under
  `Koha/Filter/MARC/ISBD4MARCPunctuation/RuleSet/` and is just data
  (`pchrs` / `post` / `wrap` / `cb_pre` / `cb_post` / `use_rules` per
  tag).
- The engine loads the active set via `rules_for()`; `ruleset()`
  gets/sets the active set and defaults to `LoC/PCC`; `rulesets()` lists
  the known set identifiers and `ruleset_label()` maps an identifier to
  its display name.
- Shared structural callbacks (e.g. the `$n/$d/$c` meeting-group and
  `$e/$f/$g` imprint grouping) stay in the engine and are referenced
  from the rule data by name, so rule-set files stay readable data.
- The coverage/render tooling (`scripts/doc_coverage.pl`,
  `scripts/render_examples.pl`) is segmented by set: they pick up each
  test file's `my $SET = ...` declaration, default to the LoC/PCC
  markers, and accept a `--set=DACH` flag to run on the D-A-CH marker
  set (so the LoC/PCC coverage table and report stay pure).

**To add a new field** to the current (`LoC/PCC`) set: add its rule
block to `RuleSet/LoCPCC.pm` (data only; reuse the shared grouping
callbacks where relevant), then add a test in the matching
`t/1X-field-*.t` following the `$SET` convention and a `# render:`
marker, and regenerate the example report.

**To add a whole new rule set**: create `RuleSet/<Name>.pm` exposing
`rules()` and register it in the rule-set table in
`ISBD4MARCPunctuation.pm` (`%SETS`: identifier, `rules` and `label`).

#### Building the plugin archive

Koha installs a plugin from a `.kpz` archive - a zip whose paths start
with `Koha/`. `configure.tt` lives in a *subdirectory* next to the
plugin module, so an archive built by hand from a `*.pm` glob would
silently omit it and the Configure screen would fail with a template
error. Build the archive with:

```bash
./scripts/build_kpz.sh            # -> ../isbd4marcpunctuation.kpz
./scripts/build_kpz.sh /tmp/out   # -> /tmp/out/isbd4marcpunctuation.kpz
```

The script packs the code, then **verifies the archive contents** and
refuses to leave a stale or incomplete `.kpz` behind: it fails if the
plugin module, the template, the filter or any rule-set module is
missing, or if the archive holds paths outside `Koha/`.

Template syntax errors are otherwise invisible until someone clicks
Configure on a live server, because the test suite does not render the
template. `./scripts/check_templates.sh` compiles every `.tt` under
`Koha/` with the real Template Toolkit parser (Koha's shared includes
are stubbed, as they are not part of this repository).

#### Configuring the plugin

Once installed, the plugin offers a **Configure** screen in the staff
interface (Administration → Manage plugins → ISBD4MARC Punctuation →
Actions → Configure). Two settings are stored for the **whole Koha
instance** - the configuration is not per record:

| Setting | Values | Default | Meaning |
|---------|--------|---------|---------|
| `ruleset` | `LoC/PCC`, `D-A-CH`, `None` | `LoC/PCC` | which rule set is applied |
| `attach_mode` | `postfix`, `prefix` | `postfix` | where the punctuation is added |

- `postfix` appends punctuation to the end of a subfield, depending on the
  subfield that follows. `prefix` prepends it to the following subfield,
  which avoids dangling punctuation when a subfield is not displayed.
  It is clearer, but prefix punctuation is stored differently in the
  record - choose one mode and keep it.
- The settings are stored as one JSON value under the plugin's
  `isbd_config` key. The filter reads them through the plugin object, so
  a change applies without restarting Koha.
- Nothing is ever stored unvalidated: an unknown rule set or mode falls
  back to `LoC/PCC` / `postfix`.
- If the plugin is disabled or has no stored settings, the filter falls
  back to the same defaults, so the plugin stays usable without any
  configuration.

#### Trying it out

On a freshly installed Koha, field `250` is a convenient way to see what
the plugin does. Take a record with leader/18 set to `c` or `n` (the
plugin changes nothing otherwise) and an edition statement such as
`250 $a 2. Aufl. $b [Bearb.]`:

| Rule set | Displays as |
|----------|-------------|
| `LoC/PCC` | `2. Aufl. [Bearb.]` |
| `D-A-CH`  | `2. Aufl. / [Bearb.]` |

Switch the rule set on the Configure screen and reload the record; the
separator changes without a restart.

Be aware that **most subfield differences between the rule sets are not
visible in a stock Koha**: its intranet detail view renders only part of
each field, and some of the fields the rules cover are not shown there at
all. A record that looks identical under both rule sets is therefore not
proof that nothing changed - the punctuation is applied to the record
itself, and the rule-by-rule evidence lives in the test suite (`t/`).
Sites with a customised XSLT will see a different subset still.

## What is not automated

The plugin automates the mechanical punctuation rules according to
standards. Where the correct punctuation depends on human judgement
punctuation should be done manually and leader/18 set accordingly. The
following cases are known to be too difficult for automatic
punctuation:

1. **Conjunctions `$o` (245, 242)** — same author titles and alternative
titles can not be distinguished from MARC. (cf. section 4.6)
```
Current: 245 00 $a Lord Macaulay's essays ; $b and, Lays of ancient Rome.
Future: 245 00 $a Lord Macaulay's essays $o and $a Lays of ancient Rome
```
```
Current: 245 10 $a Under the hill, or, The story of Venus and Tannhauser.
Future: 245 10 $a Under the hill $o or $q The story of Venus and Tannhauser
```
2. **Same-author `$a` (242)** — *same* author/shared authorship is a
judgement the data does not carry.
3. **Part names `$p` (130, 240, 242, 490)** — the plugin consistently
uses `, `.
4. **Date of treaty signing `$d` (240)** — the rule is unclear.
5. **Already-punctuated data (260 `$e/$f/$g`)** — existing parentheses
cannot be detected and would be duplicated.
6. **Lone `$i`/`$j` (300)** — accompanying-material details without a
leading `$h` are not parenthesized and a bare ` ; ` may leak.
7. **Alternate script `880`** — not handled. (cf. section 3.26)
```
Current: 260 ## $6 880-12 $a Moskva : $b Izd-vo "Nauka", $c 1982.
         880 ## $6 260-12/(N $a Москва : $b Изд-во "Наука", $c 1982.
Future: 260 ## $6 880-12 $a Moskva $b Izd-vo "Nauka" $c 1982
         880 ## $6 260-12/(N $a Москва $b Изд-во "Наука" $c 1982
```

For the others there are no examples in the reference document. Real
world test cases would be helpful.

### Qualifier `$g` combined with other subfields (manual)

Repeated `$g` qualifiers are grouped as `(a : b)` automatically (see
the implemented fields above). However, the following LoC records
combine `$g` with other subfields (a date `$d`, or a trailing
qualifier) in a single parenthetical in ways the automatic rules can
not model. These need manual punctuation (leader/18 manual):

```
Current: 110 1# $a Minnesota. $b Constitutional Convention $d (1857 : $g Republican)
Current: 710 1# $a Minnesota. $b Constitutional Convention $d (1857 : $g Republican)
Current: 111 2# $a National Conference on Physical Measurement of the Disabled, $n 2nd, $c Mayo Clinic, $d 1981, $g Projected, not held.
Current: 710 1# $a France. $t Treaties, etc. $g Poland, $d 1948 Mar. 2. $k Protocols, etc., $d 1951 Mar. 6.
Current: 710 1# $a Algeria. $t Treaties, etc. $g England and Wales, $d 1682 Apr. 20.
```

