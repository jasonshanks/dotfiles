<?php

$finder = PhpCsFixer\Finder::create()
    ->exclude('vendor')
    ->exclude('node_modules')
    ->exclude('wp-admin')
    ->exclude('wp-includes')
    ->notPath('index.php')
    ->in(getcwd());

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR2' => true,
        '@WordPress' => true, // WordPress-specific rules if you have wp-php-cs-fixer
        'array_syntax' => ['syntax' => 'long'], // WordPress prefers long arrays
        'binary_operator_spaces' => [
            'default' => 'single_space',
        ],
        'cast_spaces' => [
            'space' => 'single'
        ],
        'concat_space' => [
            'spacing' => 'one'
        ],
        'no_unused_imports' => true,
        'ordered_imports' => [
            'sort_algorithm' => 'alpha'
        ],
        'single_quote' => true,
        'trailing_comma_in_multiline' => true,
        'blank_line_after_namespace' => true,
        'blank_line_after_opening_tag' => true,
        'no_closing_tag' => true,
        'no_trailing_whitespace' => true,
        'no_trailing_whitespace_in_comment' => true,
        'single_blank_line_before_namespace' => true,
        'indentation_type' => true,
        'line_ending' => true,
        'no_whitespace_before_comma_in_array' => true,
        'normalize_index_brace' => true,
    ])
    ->setIndent("    ") // WordPress prefers tabs, but for consistency use spaces
    ->setLineEnding("\n")
    ->setFinder($finder);
