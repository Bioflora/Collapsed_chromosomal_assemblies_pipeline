#! perl

use warnings;
use strict;
use Bio::SeqIO;
use Getopt::Long;

my ($v,$help,$ref);
GetOptions(
    'ref=s' => \$ref,
    'help' => \$help,
    'v' => \$v,
    );

if($help){
    &print_help();
    exit;
}

if(@ARGV != 0){
    if(! -e $ARGV[0]){
        print STDERR "Check file pls\n\n";
	&print_help();
        exit;
    }
}else{
    &print_help();
    exit;
}

my %r = &load_data($ref); 

&run(\%r,$ARGV[0]);

sub run{
    my $ref_h = shift @_;
    my $fa = shift @_;
    my %rr = %{$ref_h};
    
    my $seqio_obj = Bio::SeqIO -> new(-file => $fa, -format => "fasta");
    while(my $seq_obj = $seqio_obj -> next_seq){
        my $id = $seq_obj -> display_id;
        if($v){
	    if(!exists $rr{$id}){
		my $seq = $seq_obj -> seq;
		print">$id\n$seq\n";
	    }
	}else{
	    if(exists $rr{$id}){
		my $seq = $seq_obj -> seq;
		print">$rr{$id}\n$seq\n";
	    }
	}
    }
}

sub load_data{
    my $f = shift @_;
    my %h;
    open my $fh1,'<',$f or die "$!";
    while(<$fh1>){
        chomp;
        my @l = split/\s+/;
        if(scalar @l > 1){
            $h{$l[0]} = $l[1];
        }else{
            $h{$l[0]} = $l[0];
        }
    }
    close $fh1;
    return %h;
}

sub print_help{
    print STDERR "USAGE : perl $0 --ref [ref_file] [-v] \$fasta\n";
}
