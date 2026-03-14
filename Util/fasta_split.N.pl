#! perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
use File::Basename;
use Cwd;

my $h_dir = getcwd();

my ($help,$ref,$of);
GetOptions(
    'ref=s' => \$ref,
    'help' => \$help,
    'outformat=s' => \$of,
          );
if($help){
    &print_help();
    exit;
}
$of //= "count";

if(!defined $ref){
print STDERR "need a fasta file \n\n";
&print_help();
    exit;
}

(my $nn = basename $ref) =~ s/(.*)\..*/$1/;
my $rr = &load_fasta($ref);
&split_fa_N($rr);

sub split_fa_N{
    my $s_obj = shift @_;
    mkdir $nn.".Nsplit" if ! -e $nn.".Nsplit";
    chdir $nn.".Nsplit";
    while(my $s_io = $s_obj -> next_seq){
	my $id = $s_io -> display_id;
	my $seq = $s_io -> seq;
	$seq = uc($seq);
	my $c = 0;
	while($seq =~ /([ACGTacgt]+)/g){
	    my $seq2 = $1;
	    my $end = pos($seq);  
	    my $start = $end - length($seq2) + 1;
	    if($of eq "count"){
		open O,'>',"$id\_$c.fa";
		print O ">$id\_$c\n$seq2\n";
		close O;
	    }elsif($of eq "pos"){
		open O,'>',"$id\_$start-$end.fa";
		print O ">$id\_$start-$end\n$seq2\n";
		close O;
	    }
	    $c += 1;
	}
    }
}

sub load_fasta{
    my $ss = Bio::SeqIO -> new (-file => shift , -format => "fasta");
    return $ss
}

sub print_help{
    print STDERR "USAGE : perl $0 --ref \$fa [--outformat count|pos]\n";
}
