#!perl

use strict;
use warnings;

use Test::More;
use Test::Needs qw( Test::EOL );

# Check the line endings.
Test::EOL::all_perl_files_ok( { trailing_whitespace => 0 } );
