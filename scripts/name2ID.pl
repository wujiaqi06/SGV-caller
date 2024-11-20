#!/usr/bin/env perl -w
# MIT License
# 
# Copyright (c) 2024 Jiaqi Wu (wujiaqi@hiroshima-u.ac.jp) and So Nakagawa (so@tokai.ac.jp)
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
getopts('i:o:', \%opts);
my $input_file = $opts{'i'} or die "use: $0 -i input_info_file.gz/.tar.xz -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_info_file.gz/.tar.xz -o output_file\n";

if ($input_file =~ /\.gz$/){
	open IN, "gzip -dc $input_file |" or die "Cannot read $input_file: $!\n";
	} elsif ($input_file =~ /\.xz$/){
	open IN, "xz -dc $input_file|" or die "Cannot read $input_file: $!\n";
} 

open OUT, ">./$output_file.txt" or die "Cannot write $output_file.txt: $!\n";

while (<IN>){
	chomp;
	#if (!/strain/){
		my @line = split (/\t/, $_);
		$line[0] =~ s/\s/_/g;
		if ($input_file =~ /\.gz$/){
			print OUT "$line[0]\t$line[2]\n";
			} elsif ($input_file =~ /\.xz$/){
				my $name = "$line[0]|$line[3]|$line[15]";
				print OUT "$name\t$line[2]\n";
			}
}
close IN;
close OUT;
