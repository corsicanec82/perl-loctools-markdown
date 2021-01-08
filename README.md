# Loctools::Markdown

A zero-dependency Markdown parser/builder Perl library. Built primarily for [Serge](https://serge.io/) and has localization as its primary focus. The library consists of the following modules and command-line tools:

## Loctools::Markdown::Parser
This module parses Markdown into an AST representation that is easy to iterate over and modify.

## Loctools::Markdown::Builder::MD

This module takes the same AST representation and generates Markdown documents, preserving as much original formatting as possible.

## loctools-md2json

This CLI tool converts Markdown into a JSON representation of the document. Usage:

    loctools-md2json < infile.md > outfile.json

## loctools-json2md

This CLI tool converts a JSON representation of the document back into Markdown. Usage:

    loctools-json2md < infile.json > outfile.md

## Installation

    $ cpan Loctools::Markdown

## Usage

```perl
use Loctools::Markdown::Builder::MD;
use Loctools::Markdown::Parser;

# parse Markdown text
my $parser = Loctools::Markdown::Parser->new;
my $tree = $parser->parse($markdown_text);

# modify the tree
# ...

# generate Markdown text
my $builder = Loctools::Markdown::Builder::MD->new;
my $markdown_output = $builder->build($tree);
```