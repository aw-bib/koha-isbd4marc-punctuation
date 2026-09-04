# ISBD4MARC Punctuation (HKS3)

This plugin adds a record processor filter for XSLT display processing via the
`xslt_record_processor_filters` hook.

## Hook

The plugin registers the `ISBD4MARCPunctuation` filter during XSLT processing.

- `Koha/Filter/MARC/ISBD4MARCPunctuation.pm`

## Documentation

### What it does

The filter adds ISBD punctuation for display when a MARC record was cataloged
without punctuation. It runs in XSLT display processing and does not change
stored MARC records.

Trigger condition:

- `Leader/18` is `n` or `c`

Implemented fields:

- `020`: International Standard Book Number
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
- `260`: Publication, Distribution, etc. (Imprint)
- `264`: Production, Publication, Distribution, Manufacture, and Copyright Notice
- `300`: Physical Description
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
- `532`: Accessibility Note
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
- `800`: Series Added Entry – Personal Name
- `810`: Series Added Entry – Corporate Name
- `811`: Series Added Entry – Meeting Name
- `830`: Series Added Entry – Uniform Title


### Why it does this

The approach follows the LoC/PCC direction to keep punctuation-light MARC for
storage/editing while generating readable ISBD-like punctuation at display
time.

For the implemented fields punctuation handling follows:

- https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf

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

#### Rule sets

The punctuation rules are organised as **rule sets**, one per
catalogue tradition. Currently there is one set, **`LoC/PCC`** (the
default, following the reference document above). A `None` set (no
automatic punctuation) is also supported.

- Each set lives in its own package under
  `Koha/Filter/MARC/ISBD4MARCPunctuation/RuleSet/` and is just data
  (`pchrs` / `post` / `wrap` / `cb_pre` / `cb_post` / `use_rules` per
  tag).
- The engine loads the active set via `rules_for()`; `ruleset()`
  gets/sets the active set and defaults to `LoC/PCC`.
- Shared structural callbacks (e.g. the `$n/$d/$c` meeting-group and
  `$e/$f/$g` imprint grouping) stay in the engine and are referenced
  from the rule data by name, so rule-set files stay readable data.

**To add a new field** to the current (`LoC/PCC`) set: add its rule
block to `RuleSet/LoCPCC.pm` (data only; reuse the shared grouping
callbacks where relevant), then add a test in the matching
`t/1X-field-*.t` following the `$SET` convention and a `# render:`
marker, and regenerate the example report.

**To add a whole new rule set**: create `RuleSet/<Name>.pm` exposing
`rules()` and register it in `rules_for()` (see `RuleSets.md` at the
project root for the design).
