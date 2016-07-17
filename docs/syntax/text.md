# Syntax: Text

## Piped text

The simplest way of adding plain text to templates is to prefix the line with a `|` character.

```jade
| Plain text can include <strong>html</strong>
p
  | It must always be on its own line
```

## Inline in a Tag

Since it's a common use case, you can put text in a tag just by adding it inline after a space.

```jade
p Plain text can include <strong>html</strong>
```

## Block text

Often you might want large blocks of text within a tag. A good example is with inline scripts or styles. To do this, just add a `.` after the tag (with no preceding space):

```jade
script.
  if (usingExpug)
    console.log('you are awesome')
  else
    console.log('use expug')
```

<!-- Based on http://jade-lang.com/reference/plain-text/ -->
