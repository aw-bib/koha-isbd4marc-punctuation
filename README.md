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

- `245`
- `246`
- `247`
- `260`
- `264`

### Why it does this

The approach follows the LoC/PCC direction to keep punctuation-light MARC for
storage/editing while generating readable ISBD-like punctuation at display
time.

For the implemented fields (`24x`, `260`, `264`), punctuation handling follows:

- https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf
