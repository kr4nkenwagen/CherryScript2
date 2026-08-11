module.exports = grammar({
  name: 'cherry',

  // Treat these like whitespace
  extras: $ => [
    /\s/,
    $.comment,
  ],

  rules: {
    // A file is just a repeating list of tokens
    source_file: $ => repeat($._token),

    _token: $ => choice(
      $.keyword,
      $.identifier,
      $.number,
      $.string,
      $.operator,
      $.punctuation
    ),

    // Based on your consume_comment: starts with # and ends at \n or another #
    comment: $ => /#[^\n#]*#?/,

    // Based on consume_string: supports both " and '
    string: $ => choice(
      seq('"', /[^"]*/, '"'),
      seq("'", /[^']*/, "'")
    ),

    // Based on consume_number: supports integers and floats
    number: $ => /\d+(\.\d+)?/,

    // Based on consume_reserved_word
    keyword: $ => choice(
      'and', 'break', 'class', 'const', 'continue', 'else', 'err',
      'for', 'false', 'fn', 'if', 'null', 'nil', 'module', 'or', 'out',
      'println', 'print', 'return', 'remove', 'super', 'this', 'true', 
      'var', 'while', 'len', 'in', 'key', "rm", "exists", "sleep", "time"
    ),

    // Based on your switch statements for operators
    operator: $ => choice(
      ':^', '..', '-=', '+=', '/=', '*=', '!=', '==', '>=', '<=', '&&', '||',
      '-', '+', '%', '/', '*', '!', '=', '>', '<', '->', '<-'
    ),

    // Standard punctuation characters from your lexer
    punctuation: $ => choice(
      '(', ')', '{', '}', '[', ']', ',', ':', '.', ';'
    ),

    // Based on consume_identifier
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
  }
});
