package MLoadData;
 
use strict;
use warnings;

sub load_from_stdin{
    my @lines = <STDIN>;
    chomp $_ for @lines;
    return @lines;
}

sub load_from_file{
    my $f = shift @_;
    my $fh = &Mfilehandle($f);
    my @lines;
    while(<$fh>){
    	chomp;
        push @lines, $_;
    }
    close $fh;
    return @lines
}

sub load_from_stdin_with_head{
    my @lines = <STDIN>;
    chomp $_ for @lines;
    my $header = shift @lines;
    return (\@lines,$header);
}

sub load_from_file_with_head{
    my $f = shift @_;
    my $fh = &Mfilehandle($f);
    my @lines;
    my $header = readline $fh;
    chomp $header;
    while(<$fh>){
    	chomp;
        push @lines, $_;
    }
    close $fh;
    return (\@lines,$header)
}

sub load_from_file_hash{
    my $f = shift @_;
    my $fh = &Mfilehandle($f);
    my %h;
    while(<$fh>){
    	chomp;
        $h{$_} = 1;
    }
    close $fh;
    return %h;
}

sub load_from_file_hash_content{
    my $f = shift @_;
    my $s = shift @_;
    my $col1 = shift @_;
    my $col2 = shift @_;
    my $fh = &Mfilehandle($f);
    my %h;
    while(<$fh>){
        chomp;
	my @l = split/$s/,$_;
        $h{$l[$col1]} = $l[$col2];
    }
    close $fh;
    return %h;
}

sub load_from_file_seprately{
    my $f = shift @_;
    my $sep = shift @_;
    my $fh = &Mfilehandle($f);

    my @lines;
    my @t;
    my $c = 0;
    my $last = undef;

    while(<$fh>){
	chomp;
	$last = $_;
	if(/^$sep/){
	    next if(scalar @t == 0);
	    push @lines, (join"\n",@t);
	    @t = ();
	}else{
	    push @t, $_;
	}
    }
    unless($last =~ /^$sep/){
	push @lines, (join"\n",@t);
    }
    close $fh;
    return @lines;
}

sub Mfilehandle{
    my $ff = shift @_;
    my $ffh;
    if($ff =~ /\.gz$/){
        open $ffh, "zcat $ff |" or die "$!\n";
    }else{
        open $ffh, '<', $ff or die "$!\n";
    }
    return $ffh;
}


sub hello {
    print "Hello, World!\n";
}

1;
