package MFileIO;
 
use strict;
use warnings;

sub handle{
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
