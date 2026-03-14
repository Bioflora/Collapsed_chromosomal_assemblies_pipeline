#! perl

use warnings;
use strict;
use MLoadData;
use File::Basename;
use Cwd qw(abs_path getcwd);

my $dir = shift;
my $parameter = shift;
if(! $dir || ! $parameter){
    print STDERR "perl $0 \$dir \$depth_interval\n";
    exit;
}
my @parameter_list = split/,/,$parameter;

if ($parameter_list[0] != 0){
    unshift @parameter_list, 0;
}else{
    print STDERR "\$depth_interval can not be 0\n";
    exit;
}

my @fs = sort{$a cmp $b} grep {/.split.file$/} `find $dir/`;
exit if scalar @fs == 0;

print "Chr\t0";
for (my $i = 1; $i < scalar @parameter_list; $i++){
    print "\t$parameter_list[$i-1]\-$parameter_list[$i]";
}
print "\t$parameter_list[-1]-inf\tnum\n";

for my $f (@fs){
    chomp $f;
    $f = abs_path($f);
    (my $fn = basename $f) =~ s/\..*//;
    my $fd = dirname $f;
    my @fc_r = MLoadData::load_from_file_with_head($f);
    my @fc = @{$fc_r[0]};

    my @c;
    for(my $j = 0;$j <= scalar @parameter_list; $j ++){
        push @c,0;
    }
    for my $tmp_l (@fc){
        my @l = split/\t/,$tmp_l;
	if($l[3] == 0){
            $c[0] += 1;
        }
        for (my $i = 1; $i < scalar @parameter_list; $i++){
            if ($l[3] <= $parameter_list[$i] && $l[3] > $parameter_list[$i-1]){
                $c[$i] += 1
            }
        }
        if($l[3] > $parameter_list[-1]){
            $c[-1] += 1;
        }
    }
    my $total = scalar @fc;
    next if $total == 0;
    my @r;
    for (my $i = 0; $i< (scalar @c);$i += 1){
	    push @r, sprintf("%.4f",$c[$i]/$total);
    }
    print "$fn\t";
    print join"\t",@r;
    print "\t$total\n";
}
