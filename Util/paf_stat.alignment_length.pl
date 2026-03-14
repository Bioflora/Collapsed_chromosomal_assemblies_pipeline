#! perl

use warnings;
use strict;
use MLoadData;
use MCE::Loop;
use File::Basename;
use Getopt::Long;
use Cwd;

my $h_dir = getcwd();
my($paf,$len_q,$len_m,$len_r,$thread,$prop_q,$prop_r);
GetOptions(
    'paf=s' => \$paf,
    'min_length_query=s' => \$len_q,
    'min_length_match=s' => \$len_m,
    'min_length_ref=s' => \$len_r,
    'thread=s' => \$thread,
    'pq=s' => \$prop_q,
    'pr=s' => \$prop_r
    );

$len_q //= 10000;
$len_m //= 5000;
$len_r //= 50000;
$thread //= 1;
$prop_q //= 0.1;
$prop_r //= 0.1;

if(!$paf){
    print STDERR "\nUSAGE: perl $0 --paf paf [--thread 1 --min_length_query 10000 --min_length_match 5000 --min_length_ref 50000 --pr 0.1 --pq 0.1]\n";
    exit;
}

(my $paf_n = basename $paf) =~ s/\.paf//;
my @paf_d = MLoadData::load_from_file($paf);
my @paf_info = &pre_reformat_paf(\@paf_d);
my %paf_seq_len = %{$paf_info[0]};
my %paf_align = %{$paf_info[1]};

if($thread > 1){
    MCE::Loop::init {max_workers => $thread, chunk_size => 1};
    mce_loop {&run($_)} (keys %paf_align);
}else{
    for my $k (keys %paf_align){
        &run($k)
    }
}

sub run{
    my $ref = shift @_;
    my @a_query = @{$paf_align{$ref}{query}};
    my @a_target =  @{$paf_align{$ref}{target}};
    my @seq_n = split/\-/,$ref;
    my %b_query = %{&block_merge(\@a_query)};
    my %b_target = %{&block_merge(\@a_target)};
    my $lb_query = &block_cal(\%b_query);
    my $lb_target = &block_cal(\%b_target);
    my $lt_query = $paf_seq_len{$seq_n[0]};
    my $lt_target = $paf_seq_len{$seq_n[1]};
    my $r_query = sprintf("%.3f",($lb_query/$lt_query));
    my $r_target = sprintf("%.3f",($lb_target/$lt_target));
    if($r_query > $prop_q && $r_target > $prop_r){
	print join"\t",($seq_n[0],$lb_query,$lt_query,$r_query,$seq_n[1],$lb_target,$lt_target,$r_target."\n");
    }
    #print "\n";
}

sub block_cal{
    my $ref = shift @_;
    my %arr = %{$ref};
    my $len = 0;
    for my $i (sort {$a <=> $b} keys %arr){
	$len = $len + ${$arr{$i}}[1] - ${$arr{$i}}[0] + 1;
    }
    
    return $len;
}
	

sub block_merge{
    my $ref = shift @_;
    my @arr = sort {${$a}[0] <=> ${$b}[0]} @{$ref};
    my %arr_n;
    
    my $s = ${$arr[0]}[0];
    my $e = ${$arr[0]}[1];
    my $c = 0;
        
    for(my $i = 1;$i < @arr; $i ++){
	if($s <= ${$arr[$i]}[1] && ${$arr[$i]}[0] <= $e){
	    $s = ($s < ${$arr[$i]}[0])? $s : ${$arr[$i]}[0];
	    $e = ($e > ${$arr[$i]}[1])? $e : ${$arr[$i]}[1];
	}else{
	    $arr_n{$c} = [$s,$e];
	    $s = ${$arr[$i]}[0];
	    $e = ${$arr[$i]}[1];
	    $c += 1;
	}
    }
    
    die "error!\n" if exists $arr_n{$c};
    $arr_n{$c} = [$s,$e];
    return (\%arr_n);
}

sub pre_reformat_paf{
    my $ref = shift @_;
    my @dd = @{$ref};
    my %h1;
    my %h2;
    for my $dd_i (@dd){
        my @l = split/\t/,$dd_i;
        next if ($l[10] < $len_m);
        next if ($l[1] < $len_q);
	next if ($l[6] < $len_r);
        $h1{$l[0]} = $l[1];
	$h1{$l[5]} = $l[6];
	push @{$h2{"$l[0]-$l[5]"}{query}},[$l[2],$l[3]];
	push @{$h2{"$l[0]-$l[5]"}{target}},[$l[7],$l[8]];
    }
    return (\%h1,\%h2);
}
