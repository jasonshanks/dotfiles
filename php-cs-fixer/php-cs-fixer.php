
<?php

$finder = PhpCsFixer\Finder::create()
    ->exclude('vendor')
    ->exclude('node_modules')
    ->in(__DIR__);

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR2' => true,
        'array_syntax' => ['syntax' => 'long'],
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
    ->setIndent("    ")
    ->setLineEnding("\n")
    ->setFinder($finder);

