#!perl

=head1 PURPOSE

Check Perl files for encoding issues.

=cut

use strict;
use warnings;

use Test::More;
use Test::Needs qw( Test::Mojibake );

# Test encoding for all files.
Test::Mojibake::all_files_encoding_ok();
