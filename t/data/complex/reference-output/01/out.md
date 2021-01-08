# Title
Paragraph below.
- --
Another Title
=============

Paragraph 1.

Paragraph 2.

## Subtitle

Another Subtitle
----------------

Paragraph 3 with some **bold** and *italic* text.
> Quote
> Quote Line 2
> Quote Line 3
> > nested quote
> > nested quote line 2
> > > third nested quote
> > > third nested quote line 2

This is an unordered list:
- foo
- bar
- baz

This is an ordered list:
1. one
   one line 2
2. two
   two line 2
3. three

This is an ordered list:
1. one
2. two
3. This is a nested list:
   * foo
   * bar
   * baz

This is a code block:

    x  x
    y    y
    z      z

This is a JSON code block:
```json
{
    "foo": "bar"
}
```

Another one with tildes
~~~json
{
    "foo": "bar"
}
~~~

# Hello, *world*!

Below is an example of JSX embedded in Markdown. <br /> **Try and change
the background color!**

<div style={{ padding: '20px', backgroundColor: 'tomato' }}>
<h3>This is JSX</h3>
</div>

# And here's another one

import { sue, fred } from '../data/authors'

export const metadata = {
authors: [sue, fred]
}

# Post about MDX
MDX is a JSX in Markdown loader, parser, and renderer for ambitious projects.
