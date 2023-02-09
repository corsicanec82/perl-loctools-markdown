package Loctools::Markdown::Parser;

# References:
#
# 1. Markdown: Syntax
#       https://daringfireball.net/projects/markdown/syntax
#
# 2. GitHub Flavored Markdown Spec
#       https://github.github.com/gfm/

use strict;

sub new {
    my ($class) = @_;

    my $self = {};
    bless($self, $class);

    $self->init;

    return $self;
}

sub init {
    my ($self) = @_;

    $self->{ast} = [];
    $self->{stack} = [];
    $self->{accum} = [];
    $self->{mode} = 'p';
    $self->{context} = {};
    $self->{counter} = 0;
}

sub process_accumulated {
    my ($self) = @_;

    if (scalar(@{$self->{accum}}) == 0) {
        return;
    }

    my $ast_node;

    if ($self->{mode} eq 'blockquote') {
        my @a = map {
            $_ =~ s/^>\s?//s; $_;
        } @{$self->{accum}};
        my $text = join("\n", @a);
        my $child = Loctools::Markdown::Parser->new;
        $ast_node = {
            kind => $self->{mode},
            children => $child->parse($text)
        };
    } elsif ($self->{mode} eq 'li') {
        my $text = join("\n", @{$self->{accum}});
        my $child = Loctools::Markdown::Parser->new;
        $ast_node = {
            kind => $self->{mode},
            children => $child->parse($text),
            context => $self->{context}
        };
    # } elsif ($self->{mode} eq 'pre') {
    #     $ast_node = {
    #         text_code => join('', @{$self->{accum}}) =~ s/^[\n]//r =~ s/[\n]$//r,
    #         kind => 'pre'
    #     };
    #     if (scalar keys %{$self->{context}} > 0) {
    #         $ast_node->{context} = $self->{context};
    #     }
    } else {
        my $text;
        my $kind;

        my $is_indented = 1;
        map {
            if ($is_indented) {
                $is_indented = undef unless $_ =~ m/^ {4,}/;
            }
        } @{$self->{accum}};

        if ($is_indented) {
            my @a = map {
                $_ =~ s/^ {4}//; $_;
            } @{$self->{accum}};
            $text = join("\n", @a);
            $kind = 'pre';
        } else {
            $kind = $self->{mode};
            if ($kind eq 'pre') {
                $text = join('', @{$self->{accum}}) =~ s/^[\n]//r =~ s/[\n]$//r;
            } else {
                $text = join("\n", @{$self->{accum}});
            }
        }

        if ($kind eq 'p' && $text =~ m/^<.*>$/s) {
            $kind = 'html';
        }

        if ($kind eq 'pre') {
            $ast_node = {
                text_code => $text,
                kind => $kind
            };
        } else {
            $ast_node = {
                text => $text,
                kind => $kind
            };
        }
        if (scalar keys %{$self->{context}} > 0) {
            $ast_node->{context} = $self->{context};
        }
    }

    push @{$self->{ast}}, $ast_node;
    $self->{accum} = [];
    $self->{mode} = 'p';
    $self->{context} = {};
}

sub parse {
    my ($self, $md) = @_;
    $self->init;

    my @lines = split(/(\n+)/, $md);
    if ($lines[$#lines] =~ m/^\n$/) {
        push @lines, '';
    }

    foreach my $line (@lines) {
        if ($self->{mode} ne 'pre' && $line =~ m/^([ \t]+)\S/) {
            my $spaces_len = length($1);
            my $prefix_len = 0;
            if ($self->{context} && $self->{context}->{prefix} ne '') {
                $prefix_len = length($self->{context}->{prefix});
            }
            $spaces_len -= $prefix_len;
            if ($spaces_len > 0 && $spaces_len <= 3) {
                my $spaces = ' ' x $spaces_len;
                $line =~ s/^$spaces//;
            }
        }

        my $out_line = $line;

        if ($self->{mode} ne 'pre' && $line =~ m/^\n{2,}$/) {
            process_accumulated($self);

            # Remove two line breaks
            # since we will get them back by
            # inserting a new AST block which will be
            # surrounded by newlines in the output.
            $out_line =~ s/^\n\n//s;

            push @{$self->{ast}}, {
                kind => 'whitespace',
                text => $out_line
            };
        }

        if ($self->{mode} ne 'pre' && $line =~ m/^\n+$/) {
            next;
        }

        if (scalar @{$self->{accum}} > 0) {
            if ($line =~ m/^=+$/) {
                $self->{mode} = 'h1';
                $self->{context}->{setext} = $line;
                next;
            }

            if ($line =~ m/^-+$/) {
                $self->{mode} = 'h2';
                $self->{context}->{setext} = $line;
                next;
            }
        }

        # Determine the block mode.
        my $mode = 'p';
        my $context;
        if ($line =~ m/^(#+)\s+/) {
            my $level = length($1);
            $level = 6 if $level > 6;
            $mode = 'h'.$level;
            $out_line = $line;
            $out_line =~ s/^#+\s+//;
        }

        if ($line eq '') {
            $mode = 'whitespace';
        }

        if ($line =~ m/^>/s) {
            $mode = 'blockquote';
        }

        if ($line =~ m/^((\*\s*){3,}|(-\s*){3,}|(=\s*){3,})$/) {
            $mode = 'hr';
        }

        if ($line =~ m/^(```|~~~)(.*)\s*$/) {
            $mode = 'pre';
            $context = {
                text => $1,
                info => $2
            };
            undef $out_line;
        }

        if ($self->{mode} eq 'pre' && $line eq $self->{context}->{text}) {
            process_accumulated($self);
            next;
        }

        if ($self->{mode} eq 'blockquote' && $mode eq 'p') {
            $mode = 'blockquote';
        }

        if ($line =~ m/^(\d+\.\s)/) {
            process_accumulated($self);
            $mode = 'li';
            $context = {
                prefix => $1,
                type => 'ol',
            };
            $out_line = $line;
            $out_line =~ s/\d+\.\s//;
        }

        if ($mode ne 'hr' && $line =~ m/^([\-\*]\s)/) {
            process_accumulated($self);
            $mode = 'li';
            $context = {
                prefix => $1,
                type => 'ul'
            };
            $out_line = $line;
            $out_line =~ s/[\-\*]\s//;
        }

        if ($mode eq 'p' && $self->{mode} =~ m/(pre|li)/) {
            $mode = $self->{mode};

            my $len = length($self->{context}->{prefix});
            my $spaces = ' ' x $len;
            $out_line = $line;
            $out_line =~ s/^$spaces//;
        }

        if ($mode ne $self->{mode}) {
            process_accumulated($self);
            $self->{mode} = $mode;
            $self->{context} = $context;
        }

        if (defined $out_line) {
            push @{$self->{accum}}, $out_line;
        }
    }

    process_accumulated($self);

    return $self->{ast};
}

1;
