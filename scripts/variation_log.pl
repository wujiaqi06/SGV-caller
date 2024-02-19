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
my $input_raw_variation_file = $opts{'i'} or die "use: $0 -i input_raw_variation_file -j input_name2ID_file -o output_name\n";
my $input_name2ID_file = $opts{'j'} or die "use: $0 -i input_raw_variation_file -j input_name2ID_file -o output_name\n";
my $output_name = $opts{'o'} or die "use: $0 -i input_raw_variation_file -j input_name2ID_file -o output_name\n";

open RAW, $input_raw_variation_file or die $!;
open ID, $input_name2ID_file or die $!;

my %raw_variation_id;
while (<RAW>){
	chomp;
	my @line = split (/\s/, $_);
	$raw_variation_id{$line[0]} = "";
}
close RAW;

my %name2ID_id;
while (<ID>){
	chomp;
	if (!/gisaid_epi_isl/){
		my @line = split (/\s/, $_);
		$name2ID_id{$line[1]} = "";
	}
}
close ID;

open OUT, ">$output_name.log.txt" or die $!;
print OUT "IDs find in $input_name2ID_file, but not in $input_raw_variation_file:\n";
foreach my $i (sort keys %name2ID_id){
	if (!(exists $raw_variation_id{$i})){
	print OUT "$i\n";
	}
}

print OUT "IDs find in $input_raw_variation_file, but not in $input_name2ID_file:\n";
foreach my $i (sort keys %raw_variation_id){
	if (!(exists $name2ID_id{$i})){
		print OUT "$i\n";
	}
}
close OUT;



