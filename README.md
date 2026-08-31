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

- `020`: ISBD
- `110`: Main Entry-Corporate Name
- `111`: Main Entry-Meeting Name
- `100`: Main Entry-Personal Name
- `610`: Subject Added Entry-Corporate Name
- `611`: Subject Added Entry-Meeting Name
- `600`: Subject Added Entry-Personal Name
- `700`: Added Entry-Personal Name
- `710`: Added Entry-Corporate Name
- `711`: Added Entry-Meeting Name
- `810`: Series Added Entry-Corporate Name
- `811`: Series Added Entry-Meeting Name
- `800`: Series Added Entry-Personal Name
- `245`: Title Statement
- `246`: Varying Form of Title
- `247`: Former Title
- `250`: Edition Statement
- `260`: Publication, Distribution, etc. (Imprint)
- `264`: Production, Publication, Distribution, Manufacture, and Copyright Notice
- `300`: Physical Description
- `490`: Series Statement
- `502`: Dissertation Note
- `505`: Formatted Contents Note
- `520`: Summary


### Why it does this

The approach follows the LoC/PCC direction to keep punctuation-light MARC for
storage/editing while generating readable ISBD-like punctuation at display
time.

For the implemented fields punctuation handling follows:

- https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf


### Technical Note

As puctuation is quite involved, so for all fields there is a quite
comprehensive test coverage in `t/`. Those tests are mainly extracted
from `Current` and `Future` lines of the reference document, so it
should be easy to verify those. The unittest are meant to ensure that
future changes to the code does not break the rules already derived
and are meant for programmers and machines.

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
_Prefix_ punctuation (automatic):
```
  245 14 $a The plays of Oscar Wilde $c  / Alan Bird
```
---

So it states first the MARC without puncutation, then the MARC as it
gets decorated by the plugin by _appending_ punctuation to a subfield
(denoted as _postfix_) and the same if the punctuation would be added
as a _prefix_ ot the subsequent field. Especially, the first form
should allow experts in the field to judge what can be done
automatically and where human expertise is required to get complex
entries right.

If needs be it is easy enough for any administrator to pass the
`md`-file through `pandoc` to generate other formats even more
digestible than Markdown.
