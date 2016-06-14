# To Do

This is a work in progress.

- [95%] String -> Tokens (`tokens = Expug.Tokenizer.tokenize(str)`)
- [80%] Tokens -> AST (`ast = Expug.Compiler.compile(tokens)`) - *getting there!*
- [1%] AST -> EEx templates (`eex = Expug.Builder.build(ast)`)

Supported:

- [x] Most everything
- [x] track line/column in tokens
- [x] `,` comma-delimited attributes
- [x] Multiline attributes
- [x] HTML escaping
- [ ] auto-end on `cond do ->` etc
- [ ] value-less attributes (`textarea(spellcheck)`)
- [ ] boolean value (`textarea(spellcheck=@spellcheck)`)
- [ ] nested `-#`
- [ ] error when nesting inside `| ...`
- [ ] `/` comments
- [ ] `.` raw text (like `script.`)
- [ ] Multiline `-` and `=` expressions
- [ ] `!=` unescaped code
