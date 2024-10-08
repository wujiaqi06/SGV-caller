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
