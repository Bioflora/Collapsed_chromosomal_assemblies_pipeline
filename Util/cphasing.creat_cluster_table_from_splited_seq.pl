#! perl

use warnings;
use strict;
use Bio::SeqIO;

if(@ARGV < 1){
    print STDERR "USAGE : perl $0 \$seq.split.fasta \$chr.lst\n";
    exit;
}

my $fa = shift;
my $fai = shift;

my @r;

open IN,'<',$fai;
while(<IN>){
    chomp;
    my @l = split/\t/;
    push @r,$l[0];
}
close IN;

my %h;
my $s_obj = Bio::SeqIO -> new (-file => $fa , -format => "fasta");
while(my $s_io = $s_obj -> next_seq){
    my $id = $s_io -> display_id;
    my @l = split/_/,$id;
    $h{$l[0]}{$l[1]} = $id;
}

for my $s (@r){
    if(!exists $h{$s}){
	print STDERR "$s not exists in $fa\n";
	next;
    }
    my $n = scalar keys %{$h{$s}};
    print "$s\t$n\t";
    my @p;
    for my $k (sort {$a <=> $b} keys %{$h{$s}}){
	push @p,$h{$s}{$k};
    }
    print join" ",@p;
    print "\n";
}
