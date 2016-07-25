# Syntax: Doctype

`doctype html` is shorthand for `<!doctype html>`. It's only allowed at the beginning of the document.

```jade
doctype html
```

These other doctypes are available:

| Expug          | HTML                                      |
| ---            | ---                                       |
| `doctype html` | `<!DOCTYPE html>`                         |
| `doctype xml`  | `<?xml version="1.0" encoding="utf-8" ?>` |

## Custom doctypes

You may use other doctypes.

```jade
doctype html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
```

## Also see

- <http://jade-lang.com/reference/comments/>
