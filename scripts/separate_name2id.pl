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
use File::Copy;
use FindBin;

my $script_dir = $FindBin::RealBin;

my %opts;
getopts('i:t:o:', \%opts);
my $input_name2id_file = $opts{'i'} or die "use: $0 -i input_name2id_file -t number_of_threads -o output_name\n";
my $number_of_threads = $opts{'t'} or die "use: $0 -i input_name2id_file -t number_of_threads -o output_name\n";
my $output_name = $opts{'o'} or die "use: $0 -i input_name2id_file -t number_of_threads -o output_name\n";

open LIST, $input_name2id_file or die $!;
my $count = 0;
#for (; <LIST>; $count++) {}
#print "Found $count lines\n";

my $sequence_for_each = int($count/$number_of_threads);
#print "Found $count lines, number of sequences per run: $sequence_for_each\n";
my @lines;
while (<LIST>){
	chomp;
	push @lines, $_;
	#print "$_\n";
}
close LIST;

my $line_number = scalar (@lines);
print "Lines $line_number\n";

my $seq_number_each_run = int ($line_number/$number_of_threads) + 1;
foreach my $i (1..$number_of_threads){
	open OUT, ">>$output_name.name_list.temp.$i" or die $!;
	my $start = ($i - 1) * $seq_number_each_run;
	my $end = $i * $seq_number_each_run - 1;
	if ($end >= $line_number){
		$end = $line_number - 1;
	}
	#print "$start, $end\n";
	my $new_list = join("\n", @lines[$start..$end]);
	print OUT "$new_list\n";
	close OUT;
}








