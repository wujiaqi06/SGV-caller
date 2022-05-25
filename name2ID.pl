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
my $input_file = $opts{'i'} or die "use: $0 -i input_info_file_gzip -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_info_file_gzip -o output_file\n";

open IN, "gzip -dc $input_file |" or die "Cannot read $input_file: $!\n";
open OUT, ">./$output_file.txt" or die "Cannot write $output_file.txt: $!\n";
open OUT2, ">./$output_file.ID_only.txt" or die "Cannot write $output_file.ID_only.txt: $!\n";

while (<IN>){
	chomp;
	#if (!/strain/){
		my @line = split (/\t/, $_);
		$line[0] =~ s/\s/_/g;
		print OUT "$line[0]\t$line[2]\n";
		print OUT2 "$line[2]\n";
	#}
}
close IN;
close OUT;
close OUT2;
