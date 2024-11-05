
<?php
$finder = PhpCsFixer\Finder::create()
  ->exclude('vendor')  // Add this to exclude vendor directory
  ->exclude('node_modules')  // Add this if you have node_modules
  ->in(__DIR__);

return (new PhpCsFixer\Config())
  ->setRules([
    '@PSR2' => true,
    '@WordPress' => true,
    // WordPress specific rules
    'array_syntax' => ['syntax' => 'long'],  // WordPress prefers long array syntax
    'binary_operator_spaces' => [
      'operators' => [
        '=>' => 'align_single_space_minimal',
        '=' => 'single_space',
      ],
    ],
    'cast_spaces' => ['space' => 'single'],
    'concat_space' => ['spacing' => 'one'],  // WordPress prefers spaces around concatenation
    'lowercase_keywords' => true,
    'method_argument_space' => [
      'on_multiline' => 'ensure_fully_multiline',
      'keep_multiple_spaces_after_comma' => false,
    ],
    'no_unused_imports' => true,
    'ordered_imports' => [
      'sort_algorithm' => 'alpha',
      'imports_order' => ['class', 'function', 'const'],
    ],
    'single_quote' => true,  // WordPress prefers single quotes
    'ternary_operator_spaces' => true,
    'visibility_required' => true,

    // Additional WordPress-friendly rules you might want to uncomment
    'blank_line_after_namespace' => true,
    'blank_line_after_opening_tag' => true,
    'no_closing_tag' => true,  // WordPress coding standards
    'no_trailing_whitespace' => true,
    'no_trailing_whitespace_in_comment' => true,
    'single_blank_line_before_namespace' => true,
    'indentation_type' => true,
    'line_ending' => true,
    'no_trailing_comma_in_singleline_array' => true,
    'no_whitespace_before_comma_in_array' => true,
    'normalize_index_brace' => true,
    'phpdoc_indent' => true,
    'phpdoc_scalar' => true,
    'phpdoc_separation' => true,
    'phpdoc_trim' => true,
  ])
  ->setIndent("    ")  // WordPress uses 4 spaces for indentation
  ->setLineEnding("\n")
  ->setFinder($finder)
  ->setUsingCache(true)  // Enable caching for better performance
  ->setRiskyAllowed(true);  // Allow risky rules
