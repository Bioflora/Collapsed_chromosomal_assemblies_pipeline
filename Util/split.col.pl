#! perl

use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use MLoadData;

my ($col1,$sep,$mode,$help,$head,$anno);
GetOptions(
           'key_col=s' => \$col1,
           'mode=s' => \$mode,
           'separation=s' => \$sep,
           'header' => \$head,
           'help' => \$help,
           'anno=s' => \$anno
          );
$col1 //= 0;
$sep //= "\t";
$mode //= "file";
$anno //="#";

if($help){
    &print_help();
    exit;
}

if($mode eq "file"){
    if($ARGV[0]){
        if(! -e $ARGV[0]){
            print STDERR "Check file pls\n\n";
            &print_help();
            exit;
        }
    }else{
        print STDERR "Need file\n\n";
        &print_help();
        exit;
    }
}

my @data;
if($mode eq "pipeline"){
    if($head){
        @data = MLoadData::load_from_stdin_with_head();
        &run($data[0],$data[1]);
    }else{
        @data = MLoadData::load_from_stdin();
        &run(\@data,"n");
    }
}elsif($mode eq "file"){
    if($head){
        @data = MLoadData::load_from_file_with_head($ARGV[0]);
        &run($data[0],$data[1]);
    }else{
        @data = MLoadData::load_from_file($ARGV[0]);
        &run(\@data,"n");
    }
}else{
    &print_help();
    exit;
}

sub run{
    my $d = shift @_;
    my $hh = shift @_;
    my @dd = @{$d};
    
    my $out_dir = (basename $ARGV[0]).".split";
    mkdir "$out_dir" if !-e "$out_dir";

    my %h;

    D:for my $i (@dd){
        next D unless length $i;
        next D if $i =~ /^$anno/;
        my @line = split/$sep/, $i;
        push @{$h{$line[$col1]}}, $i;
    }
    for my $k (keys %h){
        open O,'>',"$out_dir/$k.split.file" or die "$!";
        if($head){
            print O $hh."\n";
        }
        print O join"\n",@{$h{$k}};
        print O "\n";
        close O
    }
}

sub print_help{
    print STDERR "USAGE : perl $0 --mode [pipeline|file] --key_col [0] --separation ['\\t']  --anno ['#'] --header\n";
}