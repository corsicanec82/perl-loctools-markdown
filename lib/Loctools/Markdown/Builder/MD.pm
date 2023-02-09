package Loctools::Markdown::Builder::MD;

use strict;

sub new {
    my ($class) = @_;

    my $self = {};
    bless($self, $class);

    return $self;
}

sub build {
    my ($self, $ast) = @_;

    my @out;

    foreach my $node (@$ast) {
        if ($node->{kind} eq 'whitespace') {
            push @out, $node->{text};
            next;
        }

        if ($node->{kind} eq 'hr') {
            push @out, $node->{text};
            next;
        }

        if ($node->{kind} eq 'p') {
            push @out, wrap($node->{text}, 80);
            next;
        }

        if ($node->{kind} eq 'html') {
            push @out, $node->{text};
            next;
        }

        if ($node->{kind} =~ m/^h(\d+)$/) {
            if ($node->{context} && $node->{context}->{setext} ne '') {
                push @out, $node->{text}, $node->{context}->{setext};
            } else {
                my $prefix = ('#' x $1) . ' ';
                push @out, $prefix.$node->{text};
            }
            next;
        }

        if ($node->{kind} eq 'pre') {
            if ($node->{context} && $node->{context}->{text} ne '') {
                my $fence = $node->{context}->{text};
                push @out, $fence.$node->{context}->{info}."\n".$node->{text_code}."\n".$fence;
            } else {
                my $text = $node->{text_code};
                $text =~ s/\n/\n    /sg;
                push @out, '    '.$text;
            }
            next;
        }

        if ($node->{kind} eq 'li') {
            my $builder = Loctools::Markdown::Builder::MD->new;
            my $text = $builder->build($node->{children});
            my $prefix = $node->{context}->{prefix};
            my $padding = ' ' x (length($prefix));
            $text =~ s/\n/\n$padding/sg;
            push @out, $prefix.$text;
            next;
        }

        if ($node->{kind} eq 'blockquote') {
            my $builder = Loctools::Markdown::Builder::MD->new;
            my $text = $builder->build($node->{children});
            my $prefix = '> ';
            my $padding = '> ';
            $text =~ s/\n/\n$padding/sg;
            push @out, $prefix.$text;
            next;
        }
    }

    return join("\n", @out);
}

# Implementation for this function was taken from Serge::Util.
sub wrap {
    my ($s, $length) = @_;
    die "length should be a positive integer" unless $length > 0;

    return ('') if $s eq '';

    # Wrap by '\n' explicitly
    if ($s =~ m{^(.*?)\n(.+)$}s) {
        my $a = $1; # if $1 and $2 are used directly, this won't work
        my $b = $2;
        return wrap($a, $length), wrap($b, $length);
    }

    # The following regexp was taken from the Translate Toolkit, file textwrap.py
    my @a = split(/(\s+|[^\s\w]*\w+[a-zA-Z]-(?=\w+[a-zA-Z])|(?<=[\w\!\"\'\&\.\,\?])-{2,}(?=\w))/, $s);

    my @lines;
    my $accum = '';
    while (scalar(@a) > 0) {

        # Take the next chunk and append the
        # following whitespace chunk to it, if any
        my $chunk = shift @a;
        if (@a > 0 && $a[0] =~ m/^\s*$/) {
            $chunk .= shift @a;
        }

        if (length($accum) + length($chunk) > $length) {
            push @lines, $accum if $accum ne '';

            while (length($chunk) >= $length) {
                push @lines, substr($chunk, 0, $length, '');
            }

            $accum = $chunk;
        } else {
            $accum .= $chunk;
        }
    }
    push @lines, $accum if $accum ne '';

    return @lines;
}


1;
