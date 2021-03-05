#!perl -T

use strict;
use warnings;

use Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection ();
use Test::FailWarnings -allow_deps => 1;
use Test::More;

can_ok(
    'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection',
    'default_themes',
);

isnt(
    Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection
        ->default_themes(
        ),
    undef,
    'The policy is assigned to a default theme.',
);

done_testing();
