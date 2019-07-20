#!/usr/bin/env perl
use strict;
use utf8;
use Data::Dumper;
#use encoding 'utf8';
use lib '.';
use langs;

my $DEBUG = 0;

# lanugages
my @langs = keys(%ngram);
my $num_langs = scalar(@langs);

## the probabilities for each language (initially even distribution)
my %p = map { $_ => (1.0 / $num_langs) } @langs;

if ($DEBUG) {
    print "-- Initial state\n";
    for my $lang (@langs) {
        print "\t$lang: p=$p{$lang}\n";
    }
}


# Let X mean a 2-gram (eg. 'n' -> 'h'), and L mean a language (eg. 'pt').
#
# Bayes:
#
# (1):      P(L & X) = P(L | X) * P(X)
# (2):      P(L & X) = P(X | L) * P(L)
# 
# (1)+(2):  P(L | X) * P(X) = P(X | L) * P(L)
#
# (3):      P(L | X) = P(L) * P(X | L) / P(X)
#
# (3) chained: P(L | X1 & X2 & ... Xn) = P(L) * (P(X1 | L) / P(X1)) * (P(X2 | L) / P(X2)) * ... * (P(Xn | L) / P(Xn))
#
# P(X | L)  = the probability of that N-gram X in language L
#           =~ the frequency of that N-gram X in the training set of language L
#           =~ N(X & L) / N(L) = $ngram{$lang}{$prefix}{$suffix}
#
# P(X)      = the probability of that N-gram X in general = sum(l in Ls, P(X & l)) =
#           = sum(l in Ls, P(X | l) * P(l))

sub process_ngram($$) {
    my ($prefix, $suffix) = @_;
    $DEBUG and print "-- Processing seq '$prefix' -> '$suffix'\n";

    my %pXL_pL; # list of `P(X|L) * P(L)` for each language L
    while (my ($lang, $langstat) = each(%ngram)) {
        $pXL_pL{$lang} = ($$langstat{$prefix}{$suffix} || 0) * $p{$lang};
    }

    my $pX = 0; # P(X) = the sum of those P(X|L)*P(L) items
    for my $p (values(%pXL_pL)) { $pX += $p }
    $DEBUG and print "\t    pX     = $pX\n";

    for my $lang (@langs) {
        $p{$lang} = $pXL_pL{$lang} / $pX;
        $DEBUG and print "\t$lang: pXL_pL = $pXL_pL{$lang}, p=$p{$lang}\n";
    }
}


while (my $line = readline()) {
    my $last = ' ';
    for my $c (split('', $line)) {
        $c = ' ' if $c !~ /[[:alpha:]]/;
        $c = lc($c);
        next if $c eq ' ' and $last eq ' ';

        process_ngram($last, $c);
        $last = $c;
    }
    process_ngram($last, ' ');
}

for my $lang (sort { $p{$b} <=> $p{$a} } @langs) {
    print "$lang: $p{$lang}\n";
}
