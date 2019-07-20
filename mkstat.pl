#!/usr/bin/env perl
use strict;
use utf8;
#use encoding 'utf8';

die "Usage: $0 langcode\n" if $ARGV[0] eq '';
my $lang = $ARGV[0];

my $filename = "samples/$lang.sample";

my $total = 0;
my %ngram;

sub process_Ngram($$) {
    my ($prefix, $suffix) = @_;

    $total++;
    $ngram{$prefix}{$suffix} ||= 0;
    $ngram{$prefix}{$suffix}++;
}

my $fd;
open($fd, $filename) or die "Can't open $filename: $!\n";

while (my $line = readline($fd)) {
    my $last = ' ';
    for my $c (split('', $line)) {
        $c = ' ' if $c !~ /[[:alpha:]]/;
        $c = lc($c);
        next if $c eq ' ' and $last eq ' ';

        process_Ngram($last, $c);
        $last = $c;
    }
    process_Ngram($last, ' ');
}

close($fd);

print "\$ngram{$lang} = {\n";
for my $k (sort keys %ngram) {
    print "\t'$k' => { ";
    for my $l (sort keys %{$ngram{$k}}) {
        print "'$l' => " . ($ngram{$k}{$l} / $total) . ",\t";
    }
    print "},\n";
}
print "};\n";

# for i in de en hu pt; do ./mkstat.pl $i >>langs.pm; done
