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
#compare IDs in raw variation file with IDs in new name2ID file.

my %opts;
getopts('i:j:o:', \%opts);
my $old_raw_variation_file = $opts{'i'} or die "use: $0 -i old_raw_variation_file -j new_name2id -o newly_added_name2id\n";
my $new_id = $opts{'j'} or die "use: $0 -i old_raw_variation_file -j new_name2id -o newly_added_name2id\n";
my $newly_added = $opts{'o'} or die "use: $0 -i old_raw_variation_file -j new_name2id -o newly_added_name2id\n\n";

my %old_raw_variation_file;
open OLD, "./$old_raw_variation_file" or die "Cannot read $old_raw_variation_file: $!\n";
while (<OLD>){
	chomp;
	my @line = split (/\t/, $_);
	$old_raw_variation_file{"$line[0]"} = "";
}
close OLD;

open NEW, "./$new_id" or die "Cannot read $new_id: $!\n";
open OUT, ">./$newly_added.txt" or die "Cannot write in $newly_added.txt : $!\n";
while (<NEW>){
	chomp;
	my @line = split (/\t/, $_);
	if (!(exists $old_raw_variation_file{$line[1]})){
		print OUT "$_\n";
	}
}

close NEW;
close OUT;
