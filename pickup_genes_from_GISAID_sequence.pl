#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;
#version 2021.4.9
#version 2021.6.21 Can read zipped fasta file as well.

my %opts;
getopts('i:j:o:', \%opts);
my $input_fasta = $opts{'i'} or die "use: $0 -i input_fasta -j name2id -o output_fasta\n";
my $name2id = $opts{'j'} or die "use: $0 -i input_fasta -j name2id -o output_fasta\n";
my $output_fasta = $opts{'o'} or die "use: $0 -i input_fasta -j name2id -o output_fasta\n";
#read reference data

#get name and ID number pair
open LIST, "./$name2id" or die "Cannot read file $name2id: $!\n";
my %name2id;
while (<LIST>){
	chomp;
	my @line = split (/\t/, $_);
	$name2id{$line[0]} = $line[1];
}
close LIST;

if ($input_fasta =~ /\.gz$/){
	open DATA_SEQ, "gzip -dc ./$input_fasta |" or die "Can not read Sequence file: $!\n";
} else {
	open DATA_SEQ, $input_fasta or die "Can not read Sequence file: $!\n";
	}
open OUT, ">./$output_fasta.fas" or die "Cannot write in $output_fasta.fas: $!\n";
			
my $id = "";
my $old_id = "";
my $seq = "";
my $count = 0;
my %vari_each_seq_all;
my %vari_each_seq_screen;
my %vari_N_sum;
my %vari_indels;
while (<DATA_SEQ>){
	chomp;
	if (/^>(?<seq_name>.+$)/){
		$old_id = $id;
		$id = $+{seq_name};
		if (exists ($name2id{$old_id})){
			print OUT ">$name2id{$old_id}\n$seq\n";
		}
		$count ++;
		$seq = "";
	} else {
		$seq .= $_;
	}

	if (eof){
		if (exists $name2id{$id}){
			print OUT ">$name2id{$id}\n$seq\n";
		}
	}

}

close DATA_SEQ;
close OUT;
