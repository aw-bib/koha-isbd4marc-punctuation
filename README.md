# Test Punctuation (HKS3)

This plugin adds a record processor filter for XSLT display processing via the
`xslt_record_processor_filters` hook. It currently provides a placeholder
filter implementation.

## Hook

The plugin registers the `TestPunctuation` filter during XSLT processing. To
implement behavior, edit:

- `Koha/Filter/MARC/TestPunctuation.pm`
