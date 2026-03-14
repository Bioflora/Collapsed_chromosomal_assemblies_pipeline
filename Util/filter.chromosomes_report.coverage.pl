#! perl

use warnings;
use strict;

if(scalar @ARGV < 2) {
    print STDERR "perl $0 chromosomes.report \$cut_off [low|high] [0|4|10|30|100]\n";
    exit;
}

my $f = shift;
my $cut_off = shift;

my $mode = shift;
$mode //= "high";
my $thre_index = shift;
$thre_index //= 3;

my @thres = (0,4,10,30,100);

open IN,'<',$f;
readline IN;
while(<IN>){
    chomp;
    next if /^#/;
    $_ =~ s/^\s+//;
    my @l = split/\s+/,$_;
    my $p = join"\t",@l;
	
    my @covs = @l[4..8];
    my $cov = $covs[$thre_index];
    if($mode eq "low"){
	print $p."\n" if $cov <= $cut_off;
    }elsif($mode eq "high"){
	print $p."\n" if $cov >= $cut_off;
    }
}
