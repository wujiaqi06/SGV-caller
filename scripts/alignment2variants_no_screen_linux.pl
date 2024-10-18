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
#version 2021.5.31
#version 2021.6.18 Can read gzip fasta file as well

my %opts;
getopts('i:j:r:o:', \%opts);
my $input_fasta = $opts{'i'} or die "use: $0 -i input_fasta -j name2id -r reference -o output_file\n";
my $name2id = $opts{'j'} or die "use: $0 -i input_fasta -j name2id -r reference -o output_file\n";
my $ref = $opts{'r'} or die "use: $0 -i input_fasta -j name2id -r reference -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_fasta -j name2id -r reference -o output_file\n";
#read reference data
my %ref_seq = &read_fasta($ref);
my @ref_name = keys %ref_seq;
my @ref;
my $ref_length = length ($ref_seq{$ref_name[0]});

open TEM, ">temp.txt";

open VARINDALL, ">$output_file.raw_variants.for_each.all.txt" or die "Cannot read ForEachSeq.all.txt: $!\n";

if ((scalar @ref_name) != 1){
	print "There are more than 1 sequence in reference file!\n";
} else {
	@ref = split (//, $ref_seq{$ref_name[0]});
}

#get name and ID number pair
open LIST, $name2id or die "Cannot read file $name2id: $!\n";
my %name2id;
while (<LIST>){
	chomp;
	s/\s+$//;
	my @line = split (/\t/, $_);
	$name2id{$line[0]} = $line[1];
}
close LIST;

if ($input_fasta =~ /\.gz$/){
	open DATA_SEQ, "gzip -dc $input_fasta |" or die "Can not read Sequence file $input_fasta: $!\n";
	} elsif ($input_fasta =~ /\.xz$/){
	open DATA_SEQ, "xz -dc $input_fasta|" or die "Can not read Sequence file $input_fasta: $!\n";
	} else {
	open DATA_SEQ, $input_fasta or die "Can not read Sequence file $input_fasta: $!\n";
}

if (-e "$output_file.seq.temp.fas"){
	system "rm $output_file.seq.temp.fas";
}

if (-e "$output_file.seq.align.fas"){
	system "rm $output_file.seq.align.fas";
}

my $id = "";
my $old_id = "";
my $seq = "";
my $count = 0;
my $seq_name;
my %vari_each_seq_all;
my %vari_each_seq_screen;
my %vari_N_sum;
my %vari_indels;
while (<DATA_SEQ>){
	chomp;
	s/\s+//g;
	if (/^>(?<seq_name>.+$)/){
		$old_id = $id;
		$id = $+{seq_name};
		if (exists ($name2id{$old_id})){
			open OUT, ">./$output_file.seq.temp.fas" or die "Cannot write in $output_file.seq.temp.fas: $!\n";
			print OUT ">$ref_name[0]\n$ref_seq{$ref_name[0]}\n";
			print OUT ">$name2id{$old_id}\n$seq\n";
			system ("mafft $output_file.seq.temp.fas > $output_file.seq.align.fas");
			close OUT;
			$seq_name = $name2id{$old_id};
		}
		$count ++;
		$seq = "";
	} else {
		$seq .= $_;
	}

	if (eof){
		if (exists $name2id{$id}){
			open OUT, ">./$output_file.seq.temp.fas" or die "Cannot write in $output_file.seq.temp.fas: $!\n";
			print OUT ">$ref_name[0]\n$ref_seq{$ref_name[0]}\n";
			print OUT ">$name2id{$id}\n$seq\n";
			system ("mafft $output_file.seq.temp.fas > $output_file.seq.align.fas");
			$seq_name = $name2id{$id};
			close OUT;
		}
	}

	if (-e "$output_file.seq.align.fas"){
		#print TEM "##$seq_name##\n";
		my %align = &read_fasta("$output_file.seq.align.fas");
		my @align_seq = keys %align;
		#print TEM "seq_aligned are @align_seq\n";
		my %var_ref;
		my %var_alt;
		##march reference location
		my @ref_align = split (//, $align{$ref_name[0]});
		delete $align{$ref_name[0]};
		my @obj_align = split (//,$align{$seq_name});
		#print TEM "sequence is $seq_name\n";
		my @ref_adj = @ref;
		for (my $i = 0; $i <= $#ref; $i ++){

			if ($ref_adj[$i] ne $ref_align[$i]){
				#my $next = $i+1;
				my $adj_loc = $i - 1;
				for (my $next = $i; $ref_align[$i] eq "-"; ){
					$ref_adj[$adj_loc] .= $ref_align[$i];
					$obj_align[$adj_loc] .= $obj_align[$i];
					splice @ref_align, $i, 1;
					splice @obj_align, $i, 1;
					#print TEM "align length $#ref_align, ref length $#ref\n";
				}
				#print TEM "current $i $ref_adj[$adj_loc], obj $obj_align[$adj_loc]\n";
				$var_ref{$i} = $ref_adj[$adj_loc];
				$var_alt{$i} = $obj_align[$adj_loc];
			}
			if ($obj_align[$i] ne $ref_align[$i]){
				my $loc = $i + 1;
				#print TEM "$seq_name\t$ref_adj[$i]\t$loc\t$obj_align[$i]\n";
				$var_ref{$loc} = $ref_adj[$i];
				$var_alt{$loc} = $obj_align[$i];
			}
		}
		my @var_loc = sort { $a <=> $b } keys %var_ref;

		##handling of insertion
		my %new_vari_ref;
		my %new_vari_alt;
		my $new_del_ref = "";
		my $new_del_alt = "";
		my $new_del_loc = "";
		foreach my $i (0..$#var_loc){
			my $adj_loc = $i - 1;
			my $dis = $var_loc[$i] - $var_loc[$adj_loc];
			#print TEM "$seq_name, $var_loc[$i], dis: $dis, $var_alt{$var_loc[$i]}, before, $var_loc[$adj_loc], $var_alt{$var_loc[$adj_loc]}\n";
			if ($dis == 1){
				if (length ($new_del_loc) == 0){
					$new_del_loc = $var_loc[$adj_loc];
				}
				$new_del_ref .= $var_ref{$var_loc[$adj_loc]};
				$new_del_alt .= $var_alt{$var_loc[$adj_loc]};
				delete $var_ref{$var_loc[$adj_loc]};
				delete $var_alt{$var_loc[$adj_loc]};
			} else {
				#print TEM "$seq_name, i: $var_loc[$i], dis: $dis, $var_alt{$var_loc[$i]}, before, $var_loc[$adj_loc], $var_alt{$var_loc[$adj_loc]}\n";
				if ($new_del_loc ne ""){
					$new_del_ref .= $var_ref{$var_loc[$adj_loc]};
					$new_del_alt .= $var_alt{$var_loc[$adj_loc]};
					delete $var_ref{$var_loc[$adj_loc]};
					delete $var_alt{$var_loc[$adj_loc]};
				}
				$var_ref{$new_del_loc} = $new_del_ref;
				$var_alt{$new_del_loc} = $new_del_alt;
				$new_del_loc = "";
				$new_del_ref = "";
				$new_del_alt = "";
			}
		}
		##write last one:
		if (exists $var_loc[-1]){
			if (((length ($new_del_loc)) != 0)&($var_loc[-1] == ($#ref + 1))){
					$new_del_ref .= $var_ref{$var_loc[-1]};
					$new_del_alt .= $var_alt{$var_loc[-1]};
					delete $var_ref{$var_loc[-1]};
					delete $var_alt{$var_loc[-1]};
					$var_ref{$new_del_loc} = $new_del_ref;
					$var_alt{$new_del_loc} = $new_del_alt;
					#print TEM "$seq_name, Last one: $new_del_loc, $new_del_alt,$new_del_ref\n";
				}
			} else {
				#print TEM "$seq_name, var are @var_loc\n";
			}
		

		delete $var_ref{""};
		delete $var_alt{""};

		if (exists $var_ref{"0"}){
			$var_ref{0} =~ s/^[ATGC-]/-/;
			#$var_alt{0} =~ s/^\S/-/;
			print TEM "$seq_name, Find 0 location, $var_ref{0}0$var_alt{0}\n";
		}
		#open VAR, ">>./var.temp.txt" or die "Cannot write in var.temp.txt: $!\n";
		if (length($seq_name) != 0){
			print VARINDALL "$seq_name\t";
			#print VARINDSCREEN "$seq_name\t";
			#print NSUM "$seq_name\t";
			my @new_loc = sort { $a <=> $b } keys %var_ref;
			my $number_var = scalar (@new_loc);
			if ($number_var == 0){
				$vari_each_seq_all{$seq_name} = "0Change";
				print VARINDALL "0change";
			} 
			#print TEM "$seq_name has $number_var variants, varLoc is @new_loc\n";
			
			my %var_ref_screen = %var_ref;
			my %var_alt_screen = %var_alt;
			foreach my $i (@new_loc){
				if ($i != 0){
					$var_ref{$i} =~ s/-//g;
					} else {
						$var_ref{$i} =~ s/-+/-/;
					}
				$var_alt{$i} =~ s/-+/-/;
				##write all variant in VARINDALL
				if (exists $vari_each_seq_all{$seq_name}){
					$vari_each_seq_all{$seq_name} .= "|$var_ref{$i}$i$var_alt{$i}";
					print VARINDALL "|$var_ref{$i}$i$var_alt{$i}";
				} else {
					$vari_each_seq_all{$seq_name} = "$var_ref{$i}$i$var_alt{$i}";
					print VARINDALL "$var_ref{$i}$i$var_alt{$i}";
				}
	
				my $var_length = length($var_ref{$i});
				my $final_loc = $i + $var_length - 1;
			}
			print VARINDALL "\n";
		}
		system "rm $output_file.seq.align.fas";
		system "rm $output_file.seq.temp.fas";
		#system "rm $output_file.seq.temp.fas";
	}
}

close VARINDALL;
close DATA_SEQ;

sub read_fasta{
	open READ_SEQ, "@_" or die "Can not read Sequence file: $!\n";
	#open SEQ_INFO, ">>Sequence_Info.txt" or die "Can not read Sequence file: $!\n";
	my %sequences;
	my $id;
	my $count = 0;
	my $seq_length;
	while (<READ_SEQ>){
	chomp;
	s/\s+//;
	if ($_ =~ /^>(?<seq_name>.+$)/){
		$id  = $+{seq_name};
		$count += 1;
	}else{
		$sequences{$id} .= uc ($_);
		$seq_length = length ($sequences{$id});
		}
	}
	#print "Successfuly read @_, in total $count sequences.\n";
	#print SEQ_INFO "Successfuly read @_, in total $count sequences.\n";
	#close SEQ_INFO;
	#print "\n";
	%sequences;
}

