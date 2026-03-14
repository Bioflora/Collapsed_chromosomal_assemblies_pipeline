#! perl

use warnings;
use strict;
use MLoadData;
use List::Util qw/max/;

if(scalar @ARGV != 3){
    print STDERR "USAGE : perl $0 \$agp \$seq_lst \$seq_len\n";
    exit;
}
my $f1 = shift;
my $f2 = shift;
my $f3 = shift;

my %len = MLoadData::load_from_file_hash_content($f3,"\t",0,1);
my @ls = MLoadData::load_from_file($f1);
#my %lst = MLoadData::load_from_file_hash_content($f2,"\t",0,0);

my $max_num = 0;
my $max_l = 0;
my @nn;
for my $t (@ls){
    my @l = split/\t/,$t;
    (my $current_n = $l[0]) =~ s/[^\d]+//;
    $current_n =~ s/^0+//;
    $max_num = ($max_num >= $current_n)?$max_num:$current_n;
    $max_l = $l[3];
    print $t."\n";
#    if(exists $lst{$l[5]}){
#	push @nn, $l[5];
#    }
}

open IN,'<',$f2;
while(<IN>){
    chomp;
    $max_num += 1;
    $max_l += 1;
    my @p;
    if($max_num<10){
	@p = ("Chr0$max_num",1,$len{$_},$max_l,"W",$_,1,$len{$_},"+");
    }else{
	@p = ("Chr$max_num",1,$len{$_},$max_l,"W",$_,1,$len{$_},"+");
    }
    print join"\t",@p;
    print "\n";
}

#for my $s (@nn){
#    $max_num += 1;
#    $max_l += 1;
#    #Chr01   2527869 4907384 9       W       utg000117l      1       2379516 +
#    my @p = ("Chr$max_num",1,$len{$s},$max_l,"W",$s,1,$len{$s},"+");
#    print join"\t",@p;
#    print "\n";
#}
