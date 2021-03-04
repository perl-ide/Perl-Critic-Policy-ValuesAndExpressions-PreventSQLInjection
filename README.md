# NAME

Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection - Prevent SQL injection in interpolated strings.

# VERSION

version 2.000000

# DESCRIPTION

When building SQL statements manually instead of using an ORM, any input must
be quoted or passed using placeholders to prevent the introduction of SQL
injection vectors. This policy attempts to detect the most common sources of
SQL injection in manually crafted SQL statements, by detecting the use of
variables inside interpolated strings that look like SQL statements.

In other words, this policy searches for code such as:

    my $sql = "SELECT * FROM $table WHERE field = $value";

But would leave alone:

    my $string = "Hello $world";

# AFFILIATION

This is a standalone policy not part of a larger PerlCritic Policies group.

# CONFIGURATION

## quoting\_methods

A space-separated list of methods that are known to always return a safely
quoted result.

For example, to declare `custom_quote()` as safe, add the following to your
`.perlcriticrc`:

    [ValuesAndExpressions::PreventSQLInjection]
    quoting_methods = 'custom_quote'

By default, `quote()` and `quote_identifier` are considered safe, given their
ubiquity in code that uses DBI. Note however that specifying manually a new
list for `quoting_methods` will override those defaults, so you will have to
do this if you want to keep the two default methods but add your custom one to
the list:

    [ValuesAndExpressions::PreventSQLInjection]
    quoting_methods = 'quote quote_identifier custom_quote'

## safe\_functions

A space-separated string listing the functions that always return a safely
quoted value.

For example, to declare `quote_function()` and
`My::Package::quote_external_function()` as safe, add the following to your
`.perlcriticrc`:

    [ValuesAndExpressions::PreventSQLInjection]
    safe_functions = 'quote_function My::Package::quote_external_function'

By default, no functions are considered safe.

## prefer\_upper\_case\_keywords

A boolean indicating whether you'd prefer to detect only SELECT, INSERT, UPDATE
and DELETE or also their lower and mixed case variants. This setting will be
ignored if we find a heredoc with the `SQL` marker. Use this judiciously, but
it can help to prevent false positives like `"update account_id in test"`.

Defaults to 0.

    [ValuesAndExpressions::PreventSQLInjection]
    prefer_upper_case_keywords = 1

# MARKING ELEMENTS AS SAFE

You can disable this policy on a particular string with the usual PerlCritic
syntax:

    my $sql = "SELECT * FROM table WHERE field = $value"; ## no critic (PreventSQLInjection)

This is however not recommended, even if you know that $value is safe because
it was previously quoted with something such as:

    my $value = $dbh->quote( $user_value );

The risk there is that someone will later modify your code and introduce unsafe
variables by accident, which will then not get reported. To prevent this, this
module has a special `## SQL safe (...)` syntax described below.

## Marking variables as safe

To indicate that a variable has been manually checked and determined to be
safe, add a comment on the same line using this syntax: `## SQL safe ($var1,
$var2, ...)`.

For example:

    my $sql = "SELECT * FROM table WHERE field = $value"; ## SQL safe($value)

That said, you should always convert your code to use placeholders instead
where possible.

## Marking functions / class methods as safe

To indicate that a function or class method has been manually checked and
determined that it will always return a safe output, add comment on the same
line using the `## SQL safe(function_name`) syntax:

    my $sql = "SELECT * FROM table WHERE field = "
        . some_safe_method( $value ); ## SQL safe (&some_safe_method)

    my $sql = "SELECT * FROM table WHERE field = "
        . Package::Name::some_safe_method( $value ); ## SQL safe (&Package::Name::some_safe_method)

Note that class methods (a function called with `->` on a package name)
still need to be declared with `::` in the list of safe elements:

    my $sql = "SELECT * FROM table WHERE field = "
        . Package::Name->some_safe_method( $value ); ## SQL safe (&Package::Name::some_safe_method)

## SQL safe syntax notes

- This policy supports both comma-separated and space-separated lists to
describe safe variables. In other words, `## SQL safe ($var1, $var2, ...)` and
`## SQL safe ($var1 $var2 ...)` are strictly equivalent.
- You can mix function names and variables in the comments to describe safe elements:

        C<## SQL safe ($var1, &function_name, $var2, ...)>

# LIMITATIONS

There are **many** sources of SQL injection flaws, and this module comes with no guarantee whatsoever. It focuses on the most obvious flaws, but you should still learn more about SQL injection techniques to manually detect more advanced issues.

Possible future improvements for this module:

- Detect use of sprintf()

    This should probably be considered a violation:

        my $sql = sprintf(
            'SELECT * FROM %s',
            $table
        );

- Detect use of constants

    This should not be considered a violation, since constants cannot be modified
    by user input:

        use Const::Fast;
        const my $FOOBAR => 12;

        $dbh->do("SELECT name FROM categories WHERE id = $FOOBAR");

- Detect SQL string modifications.

    Currently, this module only analyzes strings when they are declared, and does not account for later modifications.

    This should be reviewed as part of this module:

        my $sql = "select from ";
        $sql .= $table;

    As well as this:

        my $sql = "select from ";
        $sql = "$sql $table";

-

# FUNCTIONS

## supported\_parameters()

Return an array with information about the parameters supported.

    my @supported_parameters = $policy->supported_parameters();

## default\_severity()

Return the default severity for this policy.

    my $default_severity = $policy->default_severity();

## default\_themes()

Return the default themes this policy is included in.

    my $default_themes = $policy->default_themes();

## applies\_to()

Return the class of elements this policy applies to.

    my $class = $policy->applies_to();

## prepare\_to\_scan\_document()

Sets up policy ($self) for each new document before scanning.

    my $bool = $policy->prepare_to_scan_document();

## violates()

Check an element for violations against this policy.

    my $policy->violates(
        $element,
        $document,
    );

# INTERNAL FUNCTIONS

## detect\_sql\_injections()

Detect SQL injections vulnerabilities tied to the PPI element specified.

    my $sql_injections = detect_sql_injections( $policy, $element );

## get\_function\_name()

Retrieve full name (including the package name) of a class function/method
based on a PPI::Token::Word object, and indicate if it is a call that returns
quoted data making it safe to include directly into SQL strings.

    my ( $function_name, $is_quoted ) = get_function_name( $policy, $token );

## get\_complete\_variable()

Retrieve a complete variable starting with a PPI::Token::Symbol object, and
indicate if the variable has used a quoting method to make it safe to use
directly in SQL strings.

    my ( $variable, $is_quoted ) = get_complete_variable( $policy, $token );

For example, if you have $variable->{test}->\[0\] in your code, PPI will identify
$variable as a PPI::Token::Symbol, and calling this function on that token will
return the whole "$variable->{test}->\[0\]" string.

## is\_sql\_statement()

Return a boolean indicating whether a string is potentially the beginning of a SQL statement.

    my $is_sql_statement = $self->is_sql_statement( $token );

## is\_in\_safe\_context()

Return a boolean indicating whether a string is used in a safe context (e.g., die "string").

    my $is_in_safe_context = is_in_safe_context( $token );

## get\_token\_content()

Return the text content of a PPI token.

    my $content = get_token_content( $token );

## analyze\_string\_injections()

Analyze a token representing a string and returns an arrayref of variables that
are potential SQL injection vectors.

    my $sql_injection_vector_names = analyze_string_injections(
        $policy,
        $token,
    );

## get\_safe\_elements()

Return a hashref with safe element names as the keys.

    my $safe_elements = get_safe_elements(
        $policy,
        $line_number,
    );

## parse\_comments()

Parse the comments for the current document and identify elements marked as
SQL safe.

    parse_comments(
        $policy,
        $ppi_document,
    );

## parse\_config\_parameters()

Parse the parameters from the `.perlcriticrc` file, if any are specified
there.

    parse_config_parameters( $policy );

# BUGS

Please report any bugs or feature requests through the web interface at
[https://github.com/oalders/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection/issues](https://github.com/oalders/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection/issues).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection

You can also look for information at:

- GitHub (report bugs there)

    [https://github.com/oalders/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection/issues](https://github.com/oalders/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection/issues)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection](http://cpanratings.perl.org/d/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection)

- MetaCPAN

    [https://metacpan.org/release/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection](https://metacpan.org/release/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection)

# AUTHOR

"Guillaume Aubert &lt;aubertg at cpan.org>"

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Guillaume Aubert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
