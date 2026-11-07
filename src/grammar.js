/**
 * Tree-sitter grammar definition for the Zoril systems programming language.
 * Based on the Zoril Surface Language Specification (v0.1.0-alpha).
 */

const PREC = {
  ASSIGN: 0,
  OR: 1,
  AND: 2,
  COMPARE: 3,
  BIT_OR: 4,
  BIT_XOR: 5,
  BIT_AND: 6,
  SHIFT: 7,
  ADD: 8,
  MUL: 9,
  CAST: 10,
  UNARY: 11,
  POSTFIX: 12,
  CALL: 13,
  FIELD: 14,
};

module.exports = grammar({
  name: 'zoril',

  extras: $ => [
    /\s/,
    $.line_comment,
    $.block_comment,
  ],

  externals: $ => [
    $.block_comment,
  ],

  conflicts: $ => [
    [$._type, $.generic_type],
    [$.type_identifier, $._expression],
    [$.type_identifier, $.scoped_type_identifier],
    [$.scoped_type_identifier, $._expression],
    [$.assignment_expression, $.closure_expression],
    [$._statement, $._expression],
    [$._expression, $.closure_expression],
  ],

  word: $ => $.identifier,

  rules: {
    source_file: $ => repeat($._declaration_or_statement),

    _declaration_or_statement: $ => choice(
      $._declaration,
      $._statement,
    ),

    // ------------------------------------------------------------------------
    // Declarations
    // ------------------------------------------------------------------------

    _declaration: $ => choice(
      $.import_declaration,
      $.use_declaration,
      $.const_declaration,
      $.static_declaration,
      $.type_alias_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.trait_declaration,
      $.impl_declaration,
      $.function_declaration,
    ),

    import_declaration: $ => seq(
      'import',
      field('path', $.string_literal),
      optional(seq('as', field('alias', $.identifier))),
      ';',
    ),

    use_declaration: $ => seq(
      'use',
      field('path', $.use_path),
      ';',
    ),

    use_path: $ => seq(
      repeat(seq($.identifier, '::')),
      choice(
        $.identifier,
        $.use_list,
      ),
    ),

    use_list: $ => seq(
      '{',
      commaSep($.identifier),
      optional(','),
      '}',
    ),

    const_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'const',
      field('name', $.identifier),
      ':',
      field('type', $._type),
      '=',
      field('value', $._expression),
      ';',
    ),

    static_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'static',
      optional('mut'),
      field('name', $.identifier),
      ':',
      field('type', $._type),
      '=',
      field('value', $._expression),
      ';',
    ),

    type_alias_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'type',
      field('name', $.type_identifier),
      optional(field('type_parameters', $.type_parameters)),
      optional(seq('=', field('type', $._type))),
      ';',
    ),

    struct_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'struct',
      field('name', $.type_identifier),
      optional(field('type_parameters', $.type_parameters)),
      field('body', $.field_declaration_list),
    ),

    field_declaration_list: $ => seq(
      '{',
      commaSep($.field_declaration),
      optional(','),
      '}',
    ),

    field_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      field('name', $.identifier),
      ':',
      field('type', $._type),
    ),

    enum_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'enum',
      field('name', $.type_identifier),
      optional(field('type_parameters', $.type_parameters)),
      field('body', $.enum_variant_list),
    ),

    enum_variant_list: $ => seq(
      '{',
      commaSep($.enum_variant),
      optional(','),
      '}',
    ),

    enum_variant: $ => seq(
      optional($.attribute_item),
      field('name', $.identifier),
      optional(choice(
        field('parameters', $.tuple_type),
        seq('=', field('tag', choice($.integer_literal, $.identifier))),
      )),
    ),

    trait_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      'trait',
      field('name', $.type_identifier),
      optional(field('type_parameters', $.type_parameters)),
      field('body', $.trait_body),
    ),

    trait_body: $ => seq(
      '{',
      repeat(choice(
        $.function_declaration,
        $.type_alias_declaration,
      )),
      '}',
    ),

    impl_declaration: $ => seq(
      optional($.attribute_item),
      'impl',
      optional(field('type_parameters', $.type_parameters)),
      optional(seq(field('trait', choice($.type_identifier, $.scoped_type_identifier)), 'for')),
      field('type', $._type),
      field('body', $.impl_body),
    ),

    impl_body: $ => seq(
      '{',
      repeat(choice(
        $.function_declaration,
        $.const_declaration,
        $.type_alias_declaration,
      )),
      '}',
    ),

    function_declaration: $ => seq(
      optional($.attribute_item),
      optional($.visibility_modifier),
      optional($.function_modifiers),
      'fn',
      field('name', $.identifier),
      optional(field('type_parameters', $.type_parameters)),
      field('parameters', $.parameter_list),
      optional(seq('->', field('return_type', $._type))),
      choice(
        field('body', $.block),
        ';',
      ),
    ),

    function_modifiers: $ => choice(
      'unsafe',
      'extern',
      seq('extern', $.string_literal),
      seq('unsafe', 'extern'),
      seq('unsafe', 'extern', $.string_literal),
      seq('extern', 'unsafe'),
    ),

    visibility_modifier: $ => 'pub',

    parameter_list: $ => seq(
      '(',
      commaSep(choice($.self_parameter, $.parameter, '...')),
      optional(','),
      ')',
    ),

    self_parameter: $ => seq(
      optional(choice('&', seq('&', 'mut'))),
      choice('self', 'Self'),
      optional(seq(':', field('type', $._type))),
    ),

    parameter: $ => seq(
      optional('mut'),
      field('name', $.identifier),
      ':',
      field('type', $._type),
    ),

    type_parameters: $ => seq(
      '<',
      commaSep1($.type_parameter),
      optional(','),
      '>',
    ),

    type_parameter: $ => seq(
      field('name', $.type_identifier),
      optional(seq(':', field('bound', choice($.type_identifier, $.scoped_type_identifier)))),
    ),

    attribute_item: $ => seq(
      '#',
      '[',
      commaSep1($.attribute),
      optional(','),
      ']',
    ),

    attribute: $ => seq(
      field('name', $.identifier),
      optional(seq('(', commaSep(choice($.attribute_arg, $.string_literal)), optional(','), ')')),
    ),

    attribute_arg: $ => seq(
      field('param', $.identifier),
      optional(seq('->', choice($.identifier, 'static'))),
    ),

    // ------------------------------------------------------------------------
    // Statements
    // ------------------------------------------------------------------------

    _statement: $ => choice(
      $.block,
      $.let_statement,
      $.defer_statement,
      $.return_statement,
      $.break_statement,
      $.continue_statement,
      $.expression_statement,
      $.if_expression,
      $.while_expression,
      $.loop_expression,
      $.for_expression,
      $.unsafe_block,
      $.match_expression,
    ),

    let_statement: $ => seq(
      'let',
      optional('mut'),
      field('pattern', $._pattern),
      optional(seq(':', field('type', $._type))),
      optional(seq('=', field('value', $._expression))),
      ';',
    ),

    defer_statement: $ => seq(
      'defer',
      field('expression', $._expression),
      ';',
    ),

    return_statement: $ => seq(
      'return',
      optional(field('value', $._expression)),
      ';',
    ),

    break_statement: $ => seq(
      'break',
      optional(field('value', $._expression)),
      ';',
    ),

    continue_statement: $ => seq(
      'continue',
      ';',
    ),

    expression_statement: $ => seq(
      $._expression,
      ';',
    ),

    // ------------------------------------------------------------------------
    // Types
    // ------------------------------------------------------------------------

    _type: $ => choice(
      $.primitive_type,
      $.reference_type,
      $.pointer_type,
      $.slice_type,
      $.array_type,
      $.tuple_type,
      $.generic_type,
      $.linear_type,
      $.function_type,
      $.type_identifier,
      $.scoped_type_identifier,
    ),

    primitive_type: $ => choice(
      'i8', 'i16', 'i32', 'i64',
      'u8', 'u16', 'u32', 'u64',
      'isize', 'usize',
      'f32', 'f64',
      'bool', 'char', 'unit', 'never',
    ),

    reference_type: $ => seq(
      '&',
      optional('mut'),
      field('type', $._type),
    ),

    pointer_type: $ => seq(
      '*',
      optional('mut'),
      field('type', $._type),
    ),

    slice_type: $ => seq(
      '[',
      optional('mut'),
      field('element', $._type),
      ']',
    ),

    array_type: $ => seq(
      '[',
      field('element', $._type),
      ';',
      field('length', choice($.integer_literal, $.identifier)),
      ']',
    ),

    tuple_type: $ => seq(
      '(',
      commaSep($._type),
      optional(','),
      ')',
    ),

    generic_type: $ => seq(
      field('name', choice($.type_identifier, $.scoped_type_identifier)),
      optional('::'),
      field('type_arguments', $.type_arguments),
    ),

    type_arguments: $ => seq(
      '<',
      commaSep1($._type),
      optional(','),
      '>',
    ),

    linear_type: $ => choice(
      seq('fd', '<', choice('r', 'w', 'rw'), '>'),
      'async_context',
    ),

    function_type: $ => seq(
      optional(seq('extern', optional($.string_literal))),
      'fn',
      field('parameters', $.tuple_type),
      optional(seq('->', field('return_type', $._type))),
    ),

    type_identifier: $ => choice(
      'Self',
      $.identifier,
    ),

    scoped_type_identifier: $ => choice(
      $.scoped_identifier,
      seq(
        field('path', choice('Self', $.identifier, $.scoped_identifier)),
        '::',
        field('name', $.type_identifier),
      ),
    ),

    // ------------------------------------------------------------------------
    // Expressions
    // ------------------------------------------------------------------------

    _expression: $ => choice(
      $.identifier,
      $.scoped_identifier,
      $.generic_identifier,
      $._literal,
      $.unary_expression,
      $.binary_expression,
      $.range_expression,
      $.assignment_expression,
      $.try_expression,
      $.return_expression,
      $.break_expression,
      $.continue_expression,
      $.call_expression,
      $.field_expression,
      $.index_expression,
      $.cast_expression,
      $.sizeof_expression,
      $.box_expression,
      $.annotation_expression,
      $.parenthesized_expression,
      $.tuple_expression,
      $.array_expression,
      $.struct_expression,
      $.closure_expression,
      $.block,
      $.if_expression,
      $.match_expression,
      $.while_expression,
      $.loop_expression,
      $.for_expression,
      $.unsafe_block,
    ),

    unary_expression: $ => prec(PREC.UNARY, seq(
      choice('-', '!', '*', '&', seq('&', 'mut')),
      field('argument', $._expression),
    )),

    try_expression: $ => prec(PREC.POSTFIX, seq(
      field('argument', $._expression),
      '?',
    )),

    return_expression: $ => prec.right(PREC.ASSIGN, seq(
      'return',
      optional(field('value', $._expression)),
    )),

    break_expression: $ => prec.right(PREC.ASSIGN, seq(
      'break',
      optional(field('value', $._expression)),
    )),

    continue_expression: $ => prec.right(PREC.ASSIGN, 'continue'),

    binary_expression: $ => {
      const table = [
        [PREC.MUL, choice('*', '/', '%', '*%')],
        [PREC.ADD, choice('+', '-', '+%', '-%')],
        [PREC.SHIFT, choice('<<', '>>')],
        [PREC.BIT_AND, '&'],
        [PREC.BIT_XOR, '^'],
        [PREC.BIT_OR, '|'],
        [PREC.COMPARE, choice('==', '!=', '<', '<=', '>', '>=')],
        [PREC.AND, '&&'],
        [PREC.OR, '||'],
      ];

      return choice(...table.map(([precedence, operator]) =>
        prec.left(precedence, seq(
          field('left', $._expression),
          field('operator', operator),
          field('right', $._expression),
        ))
      ));
    },

    range_expression: $ => prec.left(PREC.COMPARE, seq(
      field('start', $._expression),
      field('operator', choice('..', '..=')),
      field('end', $._expression),
    )),

    assignment_expression: $ => prec.right(PREC.ASSIGN, seq(
      field('left', $._expression),
      field('operator', choice(
        '=',
        '+=', '-=', '*=', '/=', '%=',
        '+%=', '-%=', '*%=',
        '&=', '|=', '^=', '<<=', '>>=',
      )),
      field('right', $._expression),
    )),

    call_expression: $ => prec(PREC.CALL, seq(
      field('function', $._expression),
      field('arguments', $.argument_list),
    )),

    argument_list: $ => seq(
      '(',
      commaSep($._expression),
      optional(','),
      ')',
    ),

    field_expression: $ => prec(PREC.FIELD, seq(
      field('argument', $._expression),
      '.',
      field('field', choice($.identifier, $.integer_literal)),
    )),

    generic_identifier: $ => prec(PREC.FIELD, seq(
      choice($.identifier, $.scoped_identifier, $.field_expression),
      '::',
      field('type_arguments', $.type_arguments),
    )),

    index_expression: $ => prec(PREC.POSTFIX, seq(
      field('argument', $._expression),
      '[',
      field('index', $._expression),
      ']',
    )),

    cast_expression: $ => prec(PREC.CAST, seq(
      field('value', $._expression),
      'as',
      field('type', $._type),
    )),

    sizeof_expression: $ => seq(
      choice('sizeof', 'alignof'),
      '(',
      field('type', $._type),
      ')',
    ),

    box_expression: $ => prec(PREC.UNARY, seq(
      'box',
      field('value', $._expression),
    )),

    annotation_expression: $ => prec.right(PREC.FIELD, seq(
      '@',
      field('name', $.identifier),
      optional(field('type_arguments', $.type_arguments)),
      optional(field('arguments', $.argument_list)),
    )),

    parenthesized_expression: $ => seq(
      '(',
      $._expression,
      ')',
    ),

    tuple_expression: $ => seq(
      '(',
      choice(
        seq(),
        seq($._expression, ',', commaSep($._expression), optional(',')),
      ),
      ')',
    ),

    array_expression: $ => seq(
      '[',
      choice(
        seq(commaSep($._expression), optional(',')),
        seq($._expression, ';', field('length', $._expression)),
      ),
      ']',
    ),

    struct_expression: $ => prec.dynamic(1, seq(
      field('name', choice($.type_identifier, $.scoped_type_identifier, $.generic_type)),
      field('body', $.struct_initializer),
    )),

    struct_initializer: $ => seq(
      '{',
      commaSep($.field_initializer),
      optional(','),
      '}',
    ),

    field_initializer: $ => choice(
      seq(
        field('name', $.identifier),
        ':',
        field('value', $._expression),
      ),
      field('name', $.identifier),
    ),

    closure_expression: $ => seq(
      '|',
      commaSep($.closure_parameter),
      '|',
      optional(seq('->', field('return_type', $._type))),
      field('body', choice($.block, $._expression)),
    ),

    closure_parameter: $ => seq(
      optional('mut'),
      field('name', $.identifier),
      optional(seq(':', field('type', $._type))),
    ),

    block: $ => seq(
      '{',
      repeat($._declaration_or_statement),
      optional($._expression),
      '}',
    ),

    if_expression: $ => seq(
      'if',
      choice(
        seq('let', field('pattern', $._pattern), '=', field('value', $._expression)),
        field('condition', $._expression),
      ),
      field('consequence', $.block),
      optional(seq('else', field('alternative', choice($.block, $.if_expression)))),
    ),

    match_expression: $ => seq(
      'match',
      field('value', $._expression),
      field('body', $.match_block),
    ),

    match_block: $ => seq(
      '{',
      repeat($.match_arm),
      '}',
    ),

    match_arm: $ => seq(
      field('pattern', $._pattern),
      optional(seq('if', field('guard', $._expression))),
      '=>',
      field('value', $._expression),
      optional(','),
    ),

    while_expression: $ => seq(
      'while',
      field('condition', $._expression),
      field('body', $.block),
    ),

    loop_expression: $ => seq(
      'loop',
      field('body', $.block),
    ),

    for_expression: $ => seq(
      'for',
      field('pattern', $._pattern),
      'in',
      field('value', $._expression),
      field('body', $.block),
    ),

    unsafe_block: $ => seq(
      'unsafe',
      field('body', $.block),
    ),

    // ------------------------------------------------------------------------
    // Patterns
    // ------------------------------------------------------------------------

    _pattern: $ => choice(
      $.wildcard_pattern,
      $.identifier,
      $._literal,
      $.tuple_pattern,
      $.slice_pattern,
      $.struct_pattern,
      $.enum_variant_pattern,
      $.range_pattern,
      $.or_pattern,
    ),

    wildcard_pattern: $ => '_',

    range_pattern: $ => prec(1, seq(
      choice($.integer_literal, $.char_literal, $.identifier),
      choice('..', '..='),
      choice($.integer_literal, $.char_literal, $.identifier),
    )),

    or_pattern: $ => prec.left(PREC.OR, seq(
      $._pattern,
      '|',
      $._pattern,
    )),

    tuple_pattern: $ => seq(
      '(',
      choice(
        seq(),
        seq($._pattern, ',', commaSep($._pattern), optional(',')),
      ),
      ')',
    ),

    slice_pattern: $ => seq(
      '[',
      commaSep($._pattern),
      optional(','),
      ']',
    ),

    struct_pattern: $ => seq(
      choice($.type_identifier, $.scoped_type_identifier),
      '{',
      commaSep(choice(
        seq(field('field', $.identifier), ':', field('pattern', $._pattern)),
        field('field', $.identifier),
        '..',
      )),
      optional(','),
      '}',
    ),

    enum_variant_pattern: $ => choice(
      seq(
        choice($.type_identifier, $.scoped_type_identifier),
        '.',
        field('variant', $.identifier),
        optional(field('payload', seq('(', commaSep($._pattern), optional(','), ')'))),
      ),
      seq(
        field('variant', $.identifier),
        field('payload', seq('(', commaSep($._pattern), optional(','), ')')),
      ),
    ),

    // ------------------------------------------------------------------------
    // Literals & Identifiers
    // ------------------------------------------------------------------------

    _literal: $ => choice(
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.string_literal,
      $.raw_string_literal,
      $.char_literal,
    ),

    integer_literal: $ => token(seq(
      choice(
        /[0-9][0-9_]*/,
        /0x[0-9a-fA-F][0-9a-fA-F_]*/,
        /0b[01][01_]*/,
        /0o[0-7][0-7_]*/,
      ),
      optional(choice(
        'u8', 'u16', 'u32', 'u64',
        'i8', 'i16', 'i32', 'i64',
        'usize', 'isize',
      )),
    )),

    float_literal: $ => token(seq(
      /[0-9][0-9_]*\.[0-9][0-9_]*/,
      optional(/[eE][+-]?[0-9][0-9_]*/),
      optional(choice('f32', 'f64')),
    )),

    boolean_literal: $ => choice('true', 'false'),

    string_literal: $ => token(seq(
      '"',
      repeat(choice(
        /[^"\\\n]+/,
        /\\(x[0-9a-fA-F]{2}|.)/,
      )),
      '"',
    )),

    raw_string_literal: $ => token(seq(
      'r"',
      repeat(/[^"]/),
      '"',
    )),

    char_literal: $ => token(seq(
      "'",
      choice(
        /[^'\\\n]/,
        /\\(x[0-9a-fA-F]{2}|.)/,
      ),
      "'",
    )),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    scoped_identifier: $ => prec.left(1, seq(
      field('path', choice($.identifier, $.scoped_identifier)),
      '::',
      field('name', $.identifier),
    )),

    line_comment: $ => token(seq('//', /.*/)),
  },
});

function commaSep(rule) {
  return optional(commaSep1(rule));
}

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}
