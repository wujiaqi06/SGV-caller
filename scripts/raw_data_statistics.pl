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
###counting of bad base in S protein is added

my %opts;
getopts('i:', \%opts);
my $input_raw_variants_file = $opts{'i'} or die "use: $0 -i input_raw_variants_file\n";
my $output_file_name = $input_raw_variants_file;

$output_file_name =~ s/(\w+)(\.gz)?\..*$/$1/;
my $output_file_s = "$output_file_name.s.static.txt";
$output_file_name .= ".raw_variants.static.txt";
my $ref_length = 29903;
my $UTR3 = 265;
my $UTR5 = 29675;
my $s_start = 21563;
my $s_end = 25384;

if ( $input_raw_variants_file =~ /\.gz$/){
	open IN, "gzip -dc $input_raw_variants_file |" or die "Cannot read $input_raw_variants_file: $!\n";
	} else{
		open IN, $input_raw_variants_file or die "Cannot read $input_raw_variants_file: $!\n";
	}
open OUT, ">./$output_file_name" or die "Cannot write in $output_file_name: $!\n";
print OUT "ID\tNO_Diff\tNO_BadBase\tS_BadBase\n";
open OUT2, ">./$output_file_s" or die $!;
print OUT2 "ID\tS_NO_Diff\tS_BadBase\n";
my $count = 0;
my $good_seq_count = 0;
while (<IN>){
	chomp;
	$count ++;
	my @line = split (/\t/, $_);
	my @var = split (/\|/, $line[1]);
	my $ref_seq = "";
	my $alt_seq = "";
	my $ref;
	my $alt;
	my $loc;

	my $s_ref = "";
	my $s_alt = "";
	foreach my $i (@var){
		if ($i =~ /(\D+)(\d+)(\D+)/){
			$ref = $1;
			$loc = $2;
			$alt = $3;
			
			if ((length ($ref) == 1)){
				#print "$ref, $alt\n";
				if (($loc > $UTR3)&($loc < $UTR5)){
					$ref_seq .= $ref;
					$alt_seq .= $alt;
					}

				if (($loc >= $s_start)&($loc <= $s_end)){
					$s_ref .= $ref;
					$s_alt .= $alt;
					}
				#print "1, $alt_seq, $ref_seq\n";
				} else{
					my @ref_loc = split (//, $ref);
					my $ref_loc_length = scalar (@ref_loc);
					my @loc = $loc..($loc + $ref_loc_length - 1);
					my @alt_loc;
					my $alt_loc_length;

					if ((length ($ref)) == (length ($alt))){
						@alt_loc = split (//, $alt);
						$alt_loc_length = scalar (@alt_loc);
						#print "$ref, $alt, ##@ref_loc, ##@alt_loc, ##$ref_loc_length\n";
					} elsif ((length ($ref)) > (length ($alt))){
						my $length_diff = (length ($ref)) - (length ($alt));
						$alt = $alt."-"x$length_diff;
						@alt_loc = split (//, $alt);
						$alt_loc_length = scalar (@alt_loc);
						#print "$i, $ref, $alt, ##@ref_loc, ##@alt_loc, ##$ref_loc_length, @loc\n";
					} else {
						my @alt_loc0 = split (//, $alt);
						#print "$#alt_loc0, $#ref_loc\n";
						foreach my $j (0..$#alt_loc0){
							if ($j < $#ref_loc){
								$alt_loc[$j] = $alt_loc0[$j];
							} else{
								$alt_loc[$#ref_loc] .= $alt_loc0[$j];
							}
						}
						$alt_loc_length = scalar (@alt_loc);
						#print "$i, $ref, $alt, ##@ref_loc, ##@alt_loc, ###$alt_loc_length, $ref_loc_length, @loc\n";
					}
					#print "$line[0], LOC are @loc\n";
					foreach my $j (0..$#loc){
						#print "loc $loc[$j],$ref_loc[$j], $alt_loc[$j]\n";
						if (($loc[$j] > $UTR3)&($loc[$j] < $UTR5)){
								$ref_seq .= $ref_loc[$j];
								$alt_seq .= $alt_loc[$j];
								#print "loc $loc[$j],$ref_loc[$j], $alt_loc[$j]\n$ref_seq\n";
							}

						if (($loc[$j] >= $s_start)&($loc[$j] <= $s_end)){
								$s_ref .= $ref_loc[$j];
								$s_alt .= $alt_loc[$j];
							}
						}
				}
				#print "2, $alt_seq, $ref_seq\n";
		}
	}

	#print "$line[0], $alt_seq, $ref_seq, $s_ref, $s_alt\n";

	$ref_seq =~ s/-//g;
	my $ref_seq_length = length($ref_seq);
	my $alt_seq_bad = $alt_seq;
	$alt_seq_bad =~ s/[ATCG-]//g;
	my $diff = $ref_seq_length;
	my $bad_base_number = length($alt_seq_bad);
	my $diff_freq = $ref_seq_length/$ref_length;
	my $bad_base_freq = $bad_base_number/$ref_length;
	#print OUT "$line[0]\t$diff\t$bad_base_number\n";
	if ($bad_base_number == 0){
		$good_seq_count ++;
	}
	
	$s_ref =~ s/-//g;
	my $s_length = length($s_ref);
	my $s_seq_bad = $s_alt;
	$s_alt =~ s/[ATCG-]//g;
	my $s_diff = $s_length;
	my $s_bad_base_number = length($s_alt);
	print OUT "$line[0]\t$diff\t$bad_base_number\t$s_bad_base_number\n";
	print OUT2 "$line[0]\t$s_diff\t$s_bad_base_number\n";
	if (($count % 10000) == 0){
		print "${count}th snp: $line[0], diff: $line[0]\t$diff\t$bad_base_number\t$s_bad_base_number\n";
	}

}


