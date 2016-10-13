#!/usr/bin/env perl

use strict;

my @replace;

while (@ARGV > 0 && $ARGV[0] =~ /^(\w+)=(.*)/) {
    my ($old, $new) = ($1, $2);
    push @replace, [$old, $new];
    shift @ARGV;
}

if (@ARGV != 2) {
    die "Usage: replace_strings K1=V1 ... Kn=Vn INFILE OUTFILE\n";
}

my ($infile, $outfile) = @ARGV;

open(my $f, '<', $infile)  || die "open($infile)";
open(my $g, '>', $outfile) || die "open($outfile)";
while (my $line = <$f>) {
    for my $entry (@replace) {
        my ($old, $new) = @$entry;
        $line =~ s/\$$old\$/$new/g;
    }
    print {$g} $line;
}

close($f) || die "close($infile)";
close($g) || die "close($outfile)";
