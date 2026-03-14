#! perl

use warnings;
use strict;
use MLoadData;
use List::Util qw/sum/;
use File::Basename;

if(scalar @ARGV < 1){
    print STDERR "USAGE: perl $0 \$stat \[target|query]\n";
    exit;
}
my $f1 = shift;
my $class = shift;
$class //= "query";
my @c;

if($class eq "target"){
    @c = (4,0,7);
}elsif($class eq "query"){
    @c = (0,4,3);
}else{
    print STDERR "USAGE: perl $0 \$stat \$chr_info \[target|query]\n";
    exit;
}

my @dd = MLoadData::load_from_file($f1);
my %h;

for my $tmp (@dd){
    my @l = split/\t/,$tmp;
    $h{$l[$c[0]]}{$l[$c[2]]} = $l[$c[1]];
}

D:for my $k1 (sort {$a cmp $b} keys %h){
    for my $k2 (sort {$b <=> $a} keys %{$h{$k1}}){
	print "$k1\t$h{$k1}{$k2}\t$k2\n";
	next D;
    }
}
