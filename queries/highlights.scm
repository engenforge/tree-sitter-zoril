; Keywords
[
  "as"
  "box"
  "const"
  "impl"
  "import"
  "mut"
  "static"
  "trait"
  "type"
  "unsafe"
  "use"
  "sizeof"
  "alignof"
] @keyword

[
  "break"
  "continue"
  "defer"
  "else"
  "for"
  "if"
  "in"
  "loop"
  "match"
  "return"
  "while"
] @keyword.control

[
  "import"
  "use"
  "as"
] @keyword.control.import

"fn" @keyword.function

[
  "enum"
  "struct"
  "trait"
  "type"
] @keyword.storage.type

[
  "const"
  "mut"
  "static"
  "unsafe"
] @keyword.storage.modifier

(visibility_modifier) @keyword.storage.modifier
(function_modifiers) @keyword.storage.modifier

; Types
(primitive_type) @type.builtin
(linear_type) @type.builtin

(type_identifier) @type
(type_parameter name: (type_identifier) @type.parameter)

(struct_declaration name: (type_identifier) @type)
(enum_declaration name: (type_identifier) @type)
(trait_declaration name: (type_identifier) @type)
(type_alias_declaration name: (type_identifier) @type)

; Functions
(function_declaration name: (identifier) @function)
(call_expression function: (identifier) @function.call)
(call_expression function: (field_expression field: (identifier) @function.method))
(call_expression function: (scoped_identifier name: (identifier) @function.call))
(generic_identifier (field_expression field: (identifier) @function.method))
(generic_identifier (identifier) @function.call)

; Parameters & Members
(parameter name: (identifier) @variable.parameter)
(self_parameter) @variable.builtin
(field_declaration name: (identifier) @variable.other.member)
(field_initializer name: (identifier) @variable.other.member)
(field_expression field: (identifier) @variable.other.member)

; Constants & Enums
(const_declaration name: (identifier) @constant)
(enum_variant name: (identifier) @constant)
(enum_variant_pattern variant: (identifier) @constant)

; Literals
(integer_literal) @number
(float_literal) @number.float
(boolean_literal) @constant.builtin.boolean
(string_literal) @string
(raw_string_literal) @string.special
(char_literal) @character

; Annotations & Attributes
(annotation_expression
  "@" @attribute.builtin
  name: (identifier) @attribute.builtin)

(attribute_item) @attribute
(attribute name: (identifier) @attribute)
(attribute_arg param: (identifier) @variable.parameter)

; Operators
(try_expression "?" @operator)
[
  "="
  "+="
  "-="
  "*="
  "/="
  "%="
  "+%="
  "-%="
  "*%="
  "&="
  "|="
  "^="
  "<<="
  ">>="
] @operator

[
  "+"
  "-"
  "*"
  "/"
  "%"
  "*%"
  "+%"
  "-%"
  "<<"
  ">>"
  "&"
  "|"
  "^"
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "&&"
  "||"
  "!"
  ".."
  "..="
] @operator

; Punctuation
[
  "->"
  "=>"
] @punctuation.delimiter

[
  ";"
  ":"
  ","
  "."
  "::"
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

; Comments
(line_comment) @comment.line
(block_comment) @comment.block

; Identifiers
(identifier) @variable
