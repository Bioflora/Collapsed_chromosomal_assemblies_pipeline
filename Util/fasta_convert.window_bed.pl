#! perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

my ($fa,$window,$bamdst,$mode);
GetOptions(
           'file=s' => \$fa,
           'window=s' => \$window,
           'mode=s' => \$mode
          );

$window //= 10000;
$mode //= 1;

if(!$fa){
    print "USAGE : perl $0 --file \$fa --window [10000] --mode [0|1|bamdst]\n";
    exit;
}

my $s_obj = Bio::SeqIO -> new (-file => $fa , -format => "fasta");
while(my $s_io = $s_obj -> next_seq){
    
    my $id = $s_io -> display_id;
    my $l = $s_io -> length;
    
    if($mode eq "1"){
      D1:for(my $start = 1;$start <= $l;$start += $window){
	  my $jud = 0;
          my $end = $start + $window - 1;
	  if($end > $l){
              $jud = 1;
              $end = $l;
          }
          print "$id\t$start\t$end\n";
          last D1 if $jud == 1;
      }
    }elsif($mode eq "0"){
      D2:for(my $start = 0;$start < $l;$start += $window){
          my $jud = 0;
	  my $end = $start + $window - 1;
          if($end > $l){
              $jud = 1;
              $end = $l;
          }
          print "$id\t$start\t$end\n";
          last D2 if $jud == 1;
      }
    }elsif($mode eq "bamdst"){
      D3:for(my $start = 1;$start <= $l;$start += $window){
	  my $jud = 0;
	  my $end = $start + $window - 2;
	  if($end > $l){
	      $jud = 1;
	      $end = $l;
	  }
	  next if $start == $end;
	  print "$id\t$start\t$end\n";
	  last D3 if $jud == 1;
	  #$start -= 1
      }
    }
}
 

