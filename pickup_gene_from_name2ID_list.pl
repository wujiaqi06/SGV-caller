#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('i:j:o:', \%opts);
my $input_name_pair = $opts{'i'} or die "use: $0 -i name2id -j gene_ID_list -o output_file\n";
my $gene_ID_list = $opts{'j'} or die "use: $0 -i name2id -j gene_ID_list -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i name2id -j gene_ID_list -o output_file\n";

open LIST, "./$gene_ID_list" or die "Cannot read $gene_ID_list: $!\n";
my @genes;
my %genes;
while(<LIST>){
	chomp;
	push @genes, $_;
	$genes{$_} = "";
}

open ALL, "./$input_name_pair" or die "Cannot read $input_name_pair: $!\n";
open OUT, ">./$output_file" or die "Cannot write in $output_file: $!\n";
while (<ALL>){
	chomp;
	my @line = split (/\t/, $_);
	if (exists $genes{$line[1]}){
		print OUT "$_\n";
	}
}
close ALL;
close OUT;
close LIST;