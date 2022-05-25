#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
#read gzip formated metadata file

my %opts;
getopts('i:o:', \%opts);
my $input_fasta_file = $opts{'i'} or die "use: $0 -i input_fasta_file_zipped -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_fasta_file_zipped -o output_file\n";

open IN, "gzip -dc $input_fasta_file |" or die "Cannot read $input_fasta_file: $!\n";
open OUT, ">./$output_file.txt" or die "Cannot write $output_file.txt: $!\n";
open OUT2, ">./$output_file.ID_only.txt" or die "Cannot write $output_file.ID_only.txt: $!\n";

while (<IN>){
	chomp;
	if (/^>(.*)/){
		my @line = split (/\t/, $_);
		$line[0] =~ s/\s/_/g;
		print OUT "$1\t$1\n";
		print OUT2 "$1\n";
	}
}
close IN;
close OUT;
close OUT2;
