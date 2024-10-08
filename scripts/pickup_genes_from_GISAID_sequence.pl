#!/usr/bin/env perl -w
# MIT License
# 
# Copyright (c) 2024 Jiaqi Wu (wujiaqi@hiroshima-u.ac.jp)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
	open DATA_SEQ, "gzip -dc $input_fasta |" or die "Can not read Sequence file $input_fasta: $!\n";
} elsif ($input_fasta =~ /\.xz$/){
	open DATA_SEQ, "xz -dc $input_fasta |" or die "Can not read Sequence file $input_fasta: $!\n";
} else {
	open DATA_SEQ, $input_fasta or die "Can not read Sequence file $input_fasta: $!\n";
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
