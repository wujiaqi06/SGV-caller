#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
#read gzip formated metadata file

my %opts;
getopts('i:j:o:', \%opts);
my $input_metadata_file = $opts{'i'} or die "use: $0 -i input_metadata_file.gz/.tar.xz -j input_ID_list_file -o output_file\n";
my $input_ID_list_file = $opts{'j'} or die "use: $0 -i input_metadata_file.gz/.tar.xz -j input_ID_list_file -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_metadata_file.gz/.tar.xz -j input_ID_list_file -o output_file\n";

if ($input_metadata_file =~ /\.gz$/){
	open IN, "gzip -dc $input_metadata_file |" or die "Cannot read $input_metadata_file: $!\n";
	} elsif ($input_metadata_file =~ /\.tar\.xz$/){
	open IN, "tar -xOf $input_metadata_file metadata.tsv|" or die "Cannot read $input_metadata_file: $!\n";
} 

open OUT, ">./$output_file.txt" or die "Cannot write $output_file.txt: $!\n";
open OUT2, ">./$output_file.ID_not_find.txt" or die "Cannot write $output_file.ID_not_find.txt: $!\n";

open LIST, $input_ID_list_file or die $!;
my %list;
while (<LIST>){
	chomp;
	$list{$_} = "";
}

my %name2ID;
while (<IN>){
	chomp;
	#if (!/strain/){
		my @line = split (/\t/, $_);
		$line[0] =~ s/\s/_/g;
		$name2ID{$line[2]}=$line[0];
}

foreach my $i (sort keys %list){
	if (exists $name2ID{$i}){
		print OUT "$name2ID{$i}\t$i\n";
	} else{
		print OUT2 "$i\n";
	}
}

close IN;
close OUT;
close OUT2;
