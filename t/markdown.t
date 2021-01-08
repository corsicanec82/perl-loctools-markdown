#!/usr/bin/env perl

use strict;

# HOW TO USE THIS TEST
#
# By default, this test runs over all directories in t/data/.
# To run the test only for specific directories, pass the directory names
# to this script or assign them to the environment variable SERGE_ENGINE_TESTS
# as a comma-separated list. The following two examples are equivalent:
#
# perl t/markdown.t some_dir another_dir
# LOCTOOLS_MARKDOWN_TESTS=some_dir,another_dir prove t/markdown.t

BEGIN {
    use Cwd qw(abs_path);
    use File::Basename;
    use File::Spec::Functions qw(catfile);
    map { unshift(@INC, catfile(dirname(abs_path(__FILE__)), $_)) } qw(lib ../lib);
}

use Data::Dumper;
use File::Copy::Recursive qw/dircopy/;
use File::Find qw(find);
use File::Path;
use File::Spec::Functions qw(catfile);
use Getopt::Long;
use JSON;
use Loctools::Markdown::Builder::MD;
use Loctools::Markdown::Parser;
use Test::Diff;
use Test::More;
use Text::Diff;

$| = 1; # disable output buffering

my $this_dir = dirname(abs_path(__FILE__));
my $tests_dir = catfile($this_dir, 'data');

my @md_files;

my ($init_references);

GetOptions("init" => \$init_references);

my @dirs = @ARGV;
if (my $env_dirs = $ENV{LOCTOOLS_MARKDOWN_TESTS}) {
    push @dirs, split(/,/, $env_dirs);
}

if (scalar(@dirs) == 0) {
    push @dirs, '';
}

for my $dir (@dirs) {
    find(sub {
        push @md_files, $File::Find::name if (
            -f $_
            && $_ =~ m/[\w\d\-]+\.mdx?$/
            && $File::Find::name !~ m!/(output|reference-output)/!
        );
    }, catfile($tests_dir, $dir));
}

sub delete_directory {
    my ($path, $ignore_errors) = @_;

    my $err;

    if (-e $path) {
        rmtree($path, { error => \$err });
        if (@$err && !$ignore_errors) {
            my $err_text = '';

            map {
                foreach my $key (keys %$_) {
                    $err_text .= $key.': '.$_->{$key}."\n";
                }
            } @$err;

            BAIL_OUT("Directory '".$path."' couldn't be removed\n$err_text");
        }
    }
}

for my $md_file (sort @md_files) {

    subtest "Test file: $md_file" => sub {
        my ($md_name, $md_dir, $md_suffix) = fileparse($md_file, '.md', '.mdx');

        my $output_path = catfile($md_dir, 'output', $md_name);
        my $reference_output_path = catfile($md_dir, 'reference-output', $md_name);

        my $ok = 1;

        open(MD, $md_file) or die $!;
        binmode(MD, ':utf8');
        my $text = join('', <MD>);
        close(MD);

        $text =~ s/\n+__END__.*?$/\n/s; # remove special text/comment below

        my $parser = Loctools::Markdown::Parser->new;
        my $tree = $parser->parse($text);
        ok(defined $tree, 'Markdown parsed');

        my $json = JSON->new->indent(1)->space_after(1)->canonical->encode($tree);

        my $builder = Loctools::Markdown::Builder::MD->new;
        my $out = $builder->build($tree);

        delete_directory($output_path);
        if ($init_references) {
            delete_directory($reference_output_path);
        }

        my $diff = diff(\$text, \$out, {
            STYLE => "Table",
            FILENAME_A => 'source',
            FILENAME_B => 'output'
        });

        #warn 'output_path: '. $output_path;
        mkpath($output_path);

        my $filename = catfile($output_path, 'out.json');
        open(OUT, ">$filename") or die $!;
        binmode(OUT, ':unix :utf8') or die $!;
        print OUT $json;
        close(OUT) or die $!;

        my $filename = catfile($output_path, 'out'.$md_suffix);
        open(OUT, ">$filename") or die $!;
        binmode(OUT, ':unix :utf8') or die $!;
        print OUT $out;
        close(OUT) or die $!;

        if ($diff ne '') {
            my $filename = catfile($output_path, 'out.diff.txt');
            open(OUT, ">$filename") or die $!;
            binmode(OUT, ':unix :utf8') or die $!;
            print OUT $diff;
            close(OUT) or die $!;
        }

        if ($init_references) {
            ok(dircopy($output_path, $reference_output_path), "Initialized ".$reference_output_path);
        } else {
            $ok &= dir_diff($output_path, $reference_output_path);
        }

        # Under Windows, deleting just created files may fail with 'Permission denied'
        # for an unknown reason, and only closing the process will release the file handles.
        # Since we will be removing test output at the beginning of each test anyway,
        # don't bail out this time if some files failed to be removed
        delete_directory($output_path, 1) if $ok;
    }
}

done_testing();
