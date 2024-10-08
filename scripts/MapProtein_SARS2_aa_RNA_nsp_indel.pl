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
#version 21_5_10, sequences with no variation sites before and after screening is added to aa and codon change file
#increase format of variations.info.sum.txt file(previous cds_codon_aa.all_info.txt file)
#codon shift mutation, changed from "-" to "Z"
#version 21_5_13 overlapping gene can show independently
#version 21_6_2 counting bug fixed
#version 21_7_14 RNA location become independent input file in current version.
#version 21_7_20 or ${output_folder}_RNA error corrected. it can be run in server 

my %opts;
getopts('i:j:c:r:o:', \%opts);
my $input_vari_info_file = $opts{'i'} or die "use: $0 -i input_vari_info_file -j input_reference_genome -c input_cds_annotation -r input_rna_annotation -o output_folder\n";
my $input_reference_genome = $opts{'j'} or die "use: $0 -i input_vari_info_file -j input_reference_genome -c input_cds_annotation -r input_rna_annotation -o output_folder\n";
my $input_cds_annotation_file = $opts{'c'} or die "use: $0 -i input_vari_info_file -j input_reference_genome -c input_cds_annotation -r input_rna_annotation -o output_folder\n";
my $input_RNA_info_file = $opts{'r'} or die "use: $0 -i input_vari_info_file -j input_reference_genome -c input_cds_annotation -r input_rna_annotation -o output_folder\n";
my $output_folder = $opts{'o'} or die "use: $0 -i input_vari_info_file -j input_reference_genome -c input_cds_annotation -r input_rna_annotation -o output_folder\n";

#my $input_cds_annotation_file = "NC_045512.cds.Exc1ab.overlapAdded.fas";
if (!(-e $input_cds_annotation_file)){
	print "Plese put cds file $input_cds_annotation_file in the folder!";
	break;
}
print "Reference cds is $input_cds_annotation_file\n";


## add RNA annotation
#my $input_RNA_info_file = "NC_045512.RNA.anno.txt";
if (!(-e $input_RNA_info_file)){
	print "Plese put RNA info file $input_RNA_info_file in the folder!";
	break;
}
my %RNA_info;
open RNA, $input_RNA_info_file or die $!;
while (<RNA>){
	chomp;
	my @line = split (/\t/, $_);
	$RNA_info{$line[0]} = $line[1];
}
# my %RNA_info = (
# 	"5UTR" => "1..265",
# 	"3UTR" => "29675..29903",
# 	"Non_Coding_ORF1ab_S" => "21556..21562",
# 	"Non_Coding_S_ORF3a" => "25385..25392",
# 	"Non_coding_ORF3a_E" => "26221..26244",
# 	"Non_Coding_E_M" => "26473..26522",
# 	"Non_Coding_M_ORF6" => "27192..27201",
# 	"Non_Coding_ORF6_ORF7a" => "27388..27393",
# 	"Non_Coding_ORF7b_ORF8" => "27888..27893",
# 	"Non_Coding_ORF8_N" => "28260..28273",
# 	"Non_Coding_N_ORF10" => "29534..29557");


if (!(-e "${output_folder}_codon")){
	mkdir "./${output_folder}_codon" or die "Cannot make folder ${output_folder}_codon: $!\n";
}

if (!(-e "${output_folder}_aa")){
	mkdir "./${output_folder}_aa" or die "Cannot make folder ${output_folder}_aa: $!\n";
}

if (!(-e "${output_folder}_rna")){
	mkdir "./${output_folder}_rna" or die "Cannot make folder ${output_folder}_rna: $!\n";
}

system ("rm ./${output_folder}_codon/*.txt");
system ("rm ./${output_folder}_aa/*.txt");
system ("rm ./${output_folder}_rna/*.txt");


my %table = (
	"AAA" => "K", 
	"AAC" => "N", 
	"AAG" => "K", 
	"AAT" => "N", 
	"ACA" => "T", 
	"ACC" => "T", 
	"ACG" => "T", 
	"ACT" => "T", 
	"AGA" => "R", 
	"AGC" => "S", 
	"AGG" => "R", 
	"AGT" => "S", 
	"ATA" => "I", 
	"ATC" => "I", 
	"ATG" => "M", 
	"ATT" => "I", 
	"CAA" => "Q", 
	"CAC" => "H", 
	"CAG" => "Q", 
	"CAT" => "H", 
	"CCA" => "P", 
	"CCC" => "P", 
	"CCG" => "P", 
	"CCT" => "P", 
	"CGA" => "R", 
	"CGC" => "R", 
	"CGG" => "R", 
	"CGT" => "R", 
	"CTA" => "L", 
	"CTC" => "L", 
	"CTG" => "L", 
	"CTT" => "L", 
	"GAA" => "E", 
	"GAC" => "D", 
	"GAG" => "E", 
	"GAT" => "D", 
	"GCA" => "A", 
	"GCC" => "A", 
	"GCG" => "A", 
	"GCT" => "A", 
	"GGA" => "G", 
	"GGC" => "G", 
	"GGG" => "G", 
	"GGT" => "G", 
	"GTA" => "V", 
	"GTC" => "V", 
	"GTG" => "V", 
	"GTT" => "V", 
	"TAA" => "*", 
	"TAC" => "Y", 
	"TAG" => "*", 
	"TAT" => "Y", 
	"TCA" => "S", 
	"TCC" => "S", 
	"TCG" => "S", 
	"TCT" => "S", 
	"TGA" => "*", 
	"TGC" => "C", 
	"TGG" => "W", 
	"TGT" => "C", 
	"TTA" => "L", 
	"TTC" => "F", 
	"TTG" => "L", 
	"TTT" => "F"
	);

my %all_vari_pattern;
my %vari_locations;
my %vari_ref;
my %vari_alt;
my $no_change = "";
my $no_change_after_screen = "";

open VARALL, "$input_vari_info_file" or die "Cannot read $input_vari_info_file: $!\n";
while (<VARALL>){
	chomp;
	#s/-/_/g;
	#s/\//_/g;
	if (!/^0change/){
		my @line = split (/\t/, $_);
		$all_vari_pattern{$line[0]} = $_;
		my @all_change = split (/\|/, $line[0]);
		foreach my $j (@all_change){
			if ($j =~ /^(\D+)(\d+)(\D+)$/){
				$vari_locations{$j} = $2;
				$vari_ref{$j} = $1;
				$vari_alt{$j} = $3;
				#print "$j\n";
			}
		}
	} else {
		#print "$_\n";
		if (/0change_after_screen/){
			$no_change_after_screen = $_;
		} else {
			$no_change = $_;
		}
	}
}
close VARALL;


#my %cds = &read_fasta($input_cds_annotation_file);
my %ref_genome = &read_fasta($input_reference_genome);
my @ref_seq = values(%ref_genome);
my $ref_seq = $ref_seq[0];
open CDS_ANNO, $input_cds_annotation_file or die $!;
my %cds;
while (<CDS_ANNO>){
	chomp;
	s/^\s+//;
	s/\s+$//;
	my @line = split (/\t/, $_);
	$line[1] =~ s/\s//g;
	my $gene_name = "$line[0]|$line[1]";
	if ($line[1]=~/(\d+)\.\.(\d+),(\d+)\.\.(\d+)/){
		#print "$1,$2,$3,$4\n";
		my $start0 = $1 - 1;
		my $length0 = $2 - $1 + 1;
		my $seq0 = substr($ref_seq, $start0, $length0);

		my $start1 = $3 - 1;
		my $length1 = $4 - $3 + 1;
		my $seq1 = substr($ref_seq, $start1, $length1);
		my $seq = $seq0.$seq1;
		$cds{$gene_name} = $seq;
		#print ">$gene_name\n$seq\n";
	} elsif ($line[1]=~/(\d+)\.\.(\d+)/){
		my $start = $1 - 1;
		my $length = $2 - $1 + 1;
		my $seq = substr($ref_seq, $start, $length);
		$cds{$gene_name} = $seq;
		#print ">$gene_name\n$seq\n";
	}
}





my %cds_info;
my %vari_gene;
my %vari_codon;
my %vari_aa;

my %vari_gene_info;
my %vari_all_gene;

foreach my $i (sort keys %cds){
	my @line = split (/\|/, $i);
	#print "$line[0]\n";
	$cds_info{$line[0]} = $line[1];
	if ($line[1] =~ /^(\d+)\.\.(\d+)$/){
		#print "gene #$i#, info $line[1], all $cds_info{$line[0]}, start $1, end $2\n";
		my $start = $1;
		my $end = $2;
		foreach my $j (sort keys %vari_locations){
			if (($vari_locations{$j} <= $end) &($vari_locations{$j} >= $start)){
				$vari_gene{"$j|$line[0]"} = "";
				#print "$j|$line[0]\n";

				my $cds_start = ($vari_locations{$j} - $start) % 3;
				my $codon_loc = $vari_locations{$j} - $start;
				my $aa_loc = int (($vari_locations{$j} - $start)/3) + 1;
				
				my $codon_ref;
				my $codon_alt;
				my $aa_ref;
				my $aa_alt;

				my $ref_length = length($vari_ref{$j});
				my $cut_length = (int ($ref_length/3) + 1) *3;
				##first codon mutation
				if ($cds_start == 0){
					#print "1st $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					
					## test sequence info and variance info marching check.
					#my $seq = substr ($cds{$i}, $codon_loc, 1);
					#print "seq_info is $seq\n";

					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);	
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 0, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}

					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}


					#print "$j\t$line[0]\t1st\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
				} elsif ($cds_start == 1){
					#print "2nd $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					$codon_loc = $codon_loc - 1;
					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 1, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}
					
					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}
					#print "$j\t$line[0]\t2nd\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
				} elsif ($cds_start == 2){
					#print "3rd $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					$codon_loc = $codon_loc - 2;
					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 2, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}

					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}
					
					#print "$j\t$line[0]\t3rd\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
				}
			}
		}
	} elsif ($line[1] =~ /^(\d+)\.\.(\d+),(\d+)\.\.(\d+)$/) {
		#print "$line[0], $line[1], $1, $2, $3, $4\n";
		my $start = $1;
		my $shift = $2;
		my $end = $4;
		foreach my $j (sort keys %vari_locations){
			if (($vari_locations{$j} <= $end) &($vari_locations{$j} >= $start)){
				$vari_gene{"$j|$line[0]"} = "";
				#print "$j\t$vari_gene{$j}\n";
				if ($vari_locations{$j} < ($shift)){
					my $cds_start = ($vari_locations{$j} - $start) % 3;
					my $codon_loc = $vari_locations{$j} - $start;
					my $aa_loc = int (($vari_locations{$j} - $start)/3) + 1;
				
					my $codon_ref;
					my $codon_alt;
					my $aa_ref;
					my $aa_alt;

					my $ref_length = length($vari_ref{$j});
					my $cut_length = (int ($ref_length/3) + 1) *3;
					if ($cds_start == 0){
					#print "1st $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					
					## test sequence info and variance info marching check.
					#my $seq = substr ($cds{$i}, $codon_loc, 1);
					#print "seq_info is $seq\n";

					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);	
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 0, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}

					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}

					#print "$j\t$line[0]\t1st\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
				} elsif ($cds_start == 1){
					#print "2nd $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					$codon_loc = $codon_loc - 1;
					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 1, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}
					
					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}
					#print CDS_ALL "$j\t$line[0]\t2nd\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
				} elsif ($cds_start == 2){
					#print "3rd $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					$codon_loc = $codon_loc - 2;
					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 2, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}

					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}
					
					#print CDS_ALL "$j\t$line[0]\t3rd\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
					}
					#print "$j, $vari_gene{$j}, $vari_codon{$j}, $vari_aa{$j}\n";
					#print "Here\n";
					
				} elsif (($vari_locations{$j} >= ($shift)) & ($vari_locations{$j} <= ($shift + 2))){
					if ((length ($vari_ref{$j}) == 1) & (length ($vari_alt{$j}) == 1)){
						#print "Pay attention! Gene $line[0] Codon Shift region, near $shift, has mutaton! $j\n";
					} else {
						#print "Pay attention! Gene $line[0] Codon Shift region, near $shift,has length change mutation, $j!\n";
					}
					my $cds_start = ($shift - $start - 2) % 3;
					my $codon_loc = $shift - $start - 2;
					my $aa_loc = int ((($shift - 2) - $start)/3) + 1;
					my $codon_ref = substr ($cds{$i}, $codon_loc, 6);
					my $aa_ref = &translate($codon_ref);

					my $mut_loc;
					my $codon_alt;
					my $aa_alt;
					if ($vari_locations{$j} > $shift){
						my $mut_loc = $vari_locations{$j} - ($shift - 2) + 1;
						$codon_alt = $codon_ref;
						substr ($codon_alt, $mut_loc, 1, $vari_alt{$j});
						$aa_alt = &translate($codon_alt);
						#print "$vari_locations{$j}, $shift, $mut_loc\n";
						$codon_ref = substr ($codon_ref, 3, 3);
						$codon_alt = substr ($codon_alt, 3, 3);
						if (!($codon_alt =~ /^-+$/)){
							$codon_alt =~ s/-//g;
						}
						$aa_ref = substr ($aa_ref, 1, 1);
						$aa_alt = substr ($aa_alt, 1, 1);
						$aa_loc = $aa_loc + 1;
						my $codon_info = "$codon_ref$aa_loc$codon_alt";
						my $aa_info = "$aa_ref$aa_loc$aa_alt";

						my $change_length_diff = (length($codon_ref)) - length($codon_alt);
						my $var_type;
						if ($aa_ref eq $aa_alt){
							$var_type = "Syn";
						} elsif ($change_length_diff == 0){
							$var_type = "Non";
						} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
							$var_type = "Del";
						} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
							$var_type = "Ins";
						} else {
							$var_type = "Shift";
						}

						if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
						}
						#print "$j\t$line[0]\t$codon_pos\t$var_type\t$codon_info\t$aa_info\n";
						
						#print CDS_ALL "$j\t$line[0]\t$codon_pos\t$var_type\t$codon_info\t$aa_info\n";
						$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					
						
					} elsif ($vari_locations{$j} == $shift){
						$codon_alt = $codon_ref;
						substr ($codon_alt, 2, 2, $vari_alt{$j} x 2);
						if (!($codon_alt =~ /^-+$/)){
							$codon_alt =~ s/-//g;
						}
						$aa_alt = &translate($codon_alt);
						
						my $codon_info = "$codon_ref$aa_loc$codon_alt";
						my $aa_info = "$aa_ref$aa_loc$aa_alt";
						
						my $codon_ref1 = substr ($codon_ref, 0, 3);
						my $codon_alt1 = substr ($codon_alt, 0, 3);
						my $aa_ref1 = substr ($aa_ref, 0, 1);
						my $aa_alt1 = substr ($aa_alt, 0, 1);
						my $codon_info1 = "$codon_ref1$aa_loc$codon_alt1";
						my $aa_info1 = "$aa_ref1$aa_loc$aa_alt1";

						my $var_type;
						if ($aa_ref1 eq $aa_alt1){
							$var_type = "Syn";
						} else {
							$var_type = "Non";
						}
						
						#print "$j\t$line[0]\t3rd\t$var_type\t$codon_info1\t$aa_info1\n";
						#print CDS_ALL "$j\t$line[0]\t3rd\t$var_type\t$codon_info1\t$aa_info1\n";
						$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info1\t$aa_info1";
						
						my $codon_ref2 = substr ($codon_ref, 3, 3);
						my $codon_alt2 = substr ($codon_alt, 3, 3);
						my $aa_ref2 = substr ($aa_ref, 1, 1);
						my $aa_alt2 = substr ($aa_alt, 1, 1);
						$aa_loc ++;
						my $codon_info2 = "$codon_ref2$aa_loc$codon_alt2";
						my $aa_info2 = "$aa_ref2$aa_loc$aa_alt2";

						if ($aa_ref2 eq $aa_alt2){
							$var_type = "Syn";
						} else {
							$var_type = "Non";
						}
						
						#print "$j\t$line[0]\t1st\t$var_type\t$codon_info2\t$aa_info2\tCDS\n";
						#print CDS_ALL "$j\t$line[0]\t1st\t$var_type\t$codon_info2\t$aa_info2\n";
						$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info2\t$aa_info2";
					}
					
					#print "$j $codon_ref, $aa_ref, $aa_loc, $codon_alt, $aa_alt\n";
				} elsif ($vari_locations{$j} > ($shift + 2)) {
					#print "$shift, $vari_locations{$j}, find!\n";
					my $cds_start = ($vari_locations{$j} - $start + 1) % 3;
					my $codon_loc = $vari_locations{$j} - $start + 1;
					my $aa_loc = int (($vari_locations{$j} - $start)/3 + 1) + 1;
				
					my $codon_ref;
					my $codon_alt;
					my $aa_ref;
					my $aa_alt;

					my $ref_length = length($vari_ref{$j});
					my $cut_length = (int ($ref_length/3) + 1) *3;
					if ($cds_start == 0){
					#print "1st $i, $j, gene $line[0], codon start is $cds_start, location $vari_locations{$j}, ref $vari_ref{$j}, alt, $vari_alt{$j}\n";
					
					## test sequence info and variance info marching check.
					#my $seq = substr ($cds{$i}, $codon_loc, 1);
					#print "seq_info is $seq\n";

					$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);	
					$aa_ref = &translate($codon_ref);
					$codon_alt = $codon_ref;
					substr $codon_alt, 0, $ref_length, $vari_alt{$j};
					if (!($codon_alt =~ /^-+$/)){
						$codon_alt =~ s/-//g;
					}
					$aa_alt = &translate($codon_alt);
					my $codon_info = "$codon_ref$aa_loc$codon_alt";
					my $aa_info = "$aa_ref$aa_loc$aa_alt";
					$vari_codon{$j} = $codon_info;
					$vari_aa{$j} = $aa_info;
					my $change_length_diff = (length($codon_ref)) - length($codon_alt);
					my $var_type;
					if ($aa_ref eq $aa_alt){
						$var_type = "Syn";
					} elsif ($change_length_diff == 0){
						$var_type = "Non";
					} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
						$var_type = "Del";
					} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
						$var_type = "Ins";
					} else {
						$var_type = "Shift";
					}

					if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
					}

					#print "$j\t$line[0]\t1st\t$var_type\t$codon_info\t$aa_info\n";
					#print CDS_ALL "$j\t$line[0]\t1st\t$var_type\t$codon_info\t$aa_info\n";
					$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
					#print "codon info, $codon_info; aa info, $aa_info\n";
					} elsif ($cds_start == 1){
						$codon_loc = $codon_loc - 1;
						$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
						$aa_ref = &translate($codon_ref);
						$codon_alt = $codon_ref;
						substr $codon_alt, 1, $ref_length, $vari_alt{$j};
						if (!($codon_alt =~ /^-+$/)){
							$codon_alt =~ s/-//g;
						}
						$aa_alt = &translate($codon_alt);
						$aa_loc = $aa_loc - 1;
						my $codon_info = "$codon_ref$aa_loc$codon_alt";
						my $aa_info = "$aa_ref$aa_loc$aa_alt";
						$vari_codon{$j} = $codon_info;
						$vari_aa{$j} = $aa_info;
						my $change_length_diff = (length($codon_ref)) - length($codon_alt);
						my $var_type;
						if ($aa_ref eq $aa_alt){
							$var_type = "Syn";
						} elsif ($change_length_diff == 0){
							$var_type = "Non";
						} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
							$var_type = "Del";
						} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
							$var_type = "Ins";
						} else {
							$var_type = "Shift";
						}
						
						if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
						$var_type = "Stop";
						}
						#print "$j\t$line[0]\t2nd\t$var_type\t$codon_info\t$aa_info\tCDS\n";
						#print CDS_ALL "$j\t$line[0]\t2nd\t$var_type\t$codon_info\t$aa_info\n";
						$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
						#print "codon info, $codon_info; aa info, $aa_info\n";
						} elsif ($cds_start == 2){
							$codon_loc = $codon_loc - 2;
							$codon_ref = substr ($cds{$i}, $codon_loc, $cut_length);
							$aa_ref = &translate($codon_ref);
							$codon_alt = $codon_ref;
							substr $codon_alt, 2, $ref_length, $vari_alt{$j};
							if (!($codon_alt =~ /^-+$/)){
								$codon_alt =~ s/-//g;
							}
							$aa_alt = &translate($codon_alt);
							$aa_loc = $aa_loc - 1;
							my $codon_info = "$codon_ref$aa_loc$codon_alt";
							my $aa_info = "$aa_ref$aa_loc$aa_alt";
							$vari_codon{$j} = $codon_info;
							$vari_aa{$j} = $aa_info;
							my $change_length_diff = (length($codon_ref)) - length($codon_alt);
							my $var_type;
							if ($aa_ref eq $aa_alt){
								$var_type = "Syn";
							} elsif ($change_length_diff == 0){
								$var_type = "Non";
							} elsif (($change_length_diff > 0)&($change_length_diff%3 == 0)){
								$var_type = "Del";
							} elsif (($change_length_diff < 0)&($change_length_diff%3 == 0)){
								$var_type = "Ins";
							} else {
								$var_type = "Shift";
							}

							if (($aa_alt =~ /\*/)&($var_type ne "Syn")){
							$var_type = "Stop";
							}
							#print "$j\t$line[0]\t3rd\t$var_type\t$codon_info\t$aa_info\tCDS\n";
							#print CDS_ALL "$j\t$line[0]\t3rd\t$var_type\t$codon_info\t$aa_info\n";
							$vari_gene_info{"$line[0]\t$j"} = "$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info";
							#print "codon info, $codon_info; aa info, $aa_info\n";
						}
				}
			}
		}
	}
}

foreach my $i (sort keys %RNA_info){
	my @start_end = split (/\.\./, $RNA_info{$i});
	foreach my $j (sort keys %vari_locations){
		if (($vari_locations{$j} >= $start_end[0]) & ($vari_locations{$j} <= $start_end[1])){
			$vari_gene{"$j|$i"} = "";
			#print "$j|$i\n";
			my $var_type;
			my $ref_length = length ($vari_ref{$j});
			my $alt_length = length ($vari_alt{$j});
			if ($ref_length < $alt_length){
				$var_type = "RNA_Ins";
			} elsif ($ref_length == $alt_length){
				$var_type = "RNA_Mut";
			} else {
				$var_type = "RNA_Del";
			}

			$vari_gene_info{"$i\t$j"} = "$j\t$i\tRNA\t$var_type\t$j\t$j";
			#print CDS_ALL "$j\t$i\tUTR\t$var_type\t$j\t$j\n";
			#print RNA "$j\t$i\t$var_type\n";				
		}
	}
}



my %gene_mult_aa;
my %gene_mult_codon;
my %gene;
foreach my $i (sort keys %vari_gene){
	my @line = split (/\|/, $i);
	#print "$line[1]\n";
	$gene{$line[1]} = "";
}
my @gene = sort keys %gene;

my @RNA_all = &uniq (sort keys %RNA_info);
@gene = &uniq(@gene, @RNA_all);
#print "@gene\n";

my %gene_mult_codon_count;
my %gene_mult_aa_count;
my %gene_mult_RNA_count;
my %gene_mult_codon_ID;
my %gene_mult_aa_ID;
my %gene_mult_RNA_ID;

open ALL_AAINFO, ">./$output_folder.all_info_ID.aa.sum.txt" or die "Cannot write in $output_folder.all_info_ID.sum.txt: $!\n";
open ALL_CODINFO, ">./$output_folder.all_info_ID.Codon.sum.txt" or die "Cannot write in $output_folder.all_info_ID.sum.txt: $!\n";
if (length ($no_change) != 0){
	print ALL_AAINFO "$no_change\n";
	print ALL_CODINFO "$no_change\n";
}

if (length($no_change_after_screen) != 0){
	print ALL_AAINFO "$no_change_after_screen\n";
print ALL_CODINFO "$no_change_after_screen\n";
}



my %count_var_aa;
my %count_var_codon;
my %count_var_RNA;
my %count_all;

my %type_var_aa;
my %type_var_codon;
my %type_var_RNA;

#print "@gene\n";

foreach my $i (sort keys %all_vari_pattern){
	my @all_mult = &uniq(split (/\|/, $i));
	my @mul_info = split (/\t/, $all_vari_pattern{$i});
	#print "$i\n";
	my %gene_mult_codon;
	my %gene_mult_aa;
	my %gene_mult_RNA;

	my $all_vari_change_aaRNA = "";
	my $all_vari_change_aaCodon = "";

	my $count = 0;
	foreach my $j (@all_mult){
		$count ++;
		foreach my $t (@gene){
			my $mul_info = "$t\t$j";
			if (exists $vari_gene_info{$mul_info}){
				#print "$vari_gene_info{$mul_info}\n";
				my @codon_protein_info = split (/\t/, $vari_gene_info{$mul_info});

				my $genome_loc;
				if ($codon_protein_info[0] =~ /^\D+(\d+)\D+$/){
					$genome_loc = $1;
				}
				
				if (exists $count_all{$mul_info}){
					$count_all{$mul_info} += $mul_info[1];
					#print "$mul_info, $i, find, $count_all{$mul_info}\n";
				} else {
					$count_all{$mul_info} = $mul_info[1];
					#print "$mul_info, $i, find, $count_all{$mul_info}\n";
				}


				if ($codon_protein_info[2] eq "RNA"){
					my $loci_info = "$codon_protein_info[1]\t$codon_protein_info[0]";
					if (exists $count_var_RNA{$loci_info}){
						$count_var_RNA{$loci_info} += $mul_info[1];
					} else {
						$count_var_RNA{$loci_info} = $mul_info[1];
						$type_var_RNA{$loci_info} = $codon_protein_info[3]."\t$genome_loc";
					}
				} else{
					my $loci_info0 = "$codon_protein_info[1]\t$codon_protein_info[5]";
					if (exists $count_var_aa{$loci_info0}){
						$count_var_aa{$loci_info0} += $mul_info[1];
					} else {
						$count_var_aa{$loci_info0} = $mul_info[1];
						$type_var_aa{$loci_info0} = $codon_protein_info[3]."\t$genome_loc";
					}

					my $loci_info1 = "$codon_protein_info[1]\t$codon_protein_info[4]";
					if (exists $count_var_codon{$loci_info1}){
						$count_var_codon{$loci_info1} += $mul_info[1];
					} else {
						$count_var_codon{$loci_info1} = $mul_info[1];
						$type_var_codon{$loci_info1} = "$codon_protein_info[3]\t$codon_protein_info[5]\t$genome_loc";
					}
				}

				if (exists $vari_gene{"$j|$t"}){
					#print "Find! $j|$t\n";
					if (($codon_protein_info[2] ne "RNA")&($codon_protein_info[3] ne "Syn")){
						#print "$j: $t#$codon_protein_info[5]\n";
						if (length ($all_vari_change_aaRNA) == 0){
						$all_vari_change_aaRNA = "$t#$codon_protein_info[5]";
						} elsif ($count > 1) {
						$all_vari_change_aaRNA .= "|$t#$codon_protein_info[5]"
						}
					}

					if (length ($all_vari_change_aaCodon) == 0){
						$all_vari_change_aaCodon = "$t#$codon_protein_info[4]";
						} elsif ($count > 1) {
						$all_vari_change_aaCodon .= "|$t#$codon_protein_info[4]"
						}
					}
				#print "find, $vari_gene_info{$mul_info}\n";

				if ($codon_protein_info[2] eq "RNA"){
					if (exists $gene_mult_RNA{$t}){
						#print "$t, $gene_mult_RNA{$t}\n";
						$gene_mult_RNA{$t} .= "|$codon_protein_info[0]";
						}  else {
							$gene_mult_RNA{$t} = "$codon_protein_info[0]";
						}
					} else {
						if (exists $gene_mult_codon{$t}){
						#print "$t\n";
							$gene_mult_codon{$t} .= "|$codon_protein_info[4]";
						}  else {
							$gene_mult_codon{$t} = "$codon_protein_info[4]";
						}
						if (($codon_protein_info[3] ne "Syn")){
							#print "$codon_protein_info[3]\n";
							if ((exists $gene_mult_aa{$t})){
								$gene_mult_aa{$t} .= "|$codon_protein_info[5]";
							}  else {
								$gene_mult_aa{$t} = "$codon_protein_info[5]";
							}
						}
				}
			}
		}
	}

	foreach my $j (sort keys %gene_mult_codon){
		#print "$j, $gene_mult_codon{$j}\n";
		if (exists $gene_mult_codon_count{"$j\t$gene_mult_codon{$j}"}){
			$gene_mult_codon_count{"$j\t$gene_mult_codon{$j}"} += $mul_info[1];
			$gene_mult_codon_ID{"$j\t$gene_mult_codon{$j}"} .= "|$mul_info[2]";
		} else {
			$gene_mult_codon_count{"$j\t$gene_mult_codon{$j}"} = $mul_info[1];
			$gene_mult_codon_ID{"$j\t$gene_mult_codon{$j}"} = "$mul_info[2]";
		}
	}

	foreach my $j (sort keys %gene_mult_aa){
		if (exists $gene_mult_aa_count{"$j\t$gene_mult_aa{$j}"}){
			$gene_mult_aa_count{"$j\t$gene_mult_aa{$j}"} += $mul_info[1];
			$gene_mult_aa_ID{"$j\t$gene_mult_aa{$j}"} .= "|$mul_info[2]";
		} else {
			$gene_mult_aa_count{"$j\t$gene_mult_aa{$j}"} = $mul_info[1];
			$gene_mult_aa_ID{"$j\t$gene_mult_aa{$j}"} = "$mul_info[2]";
		}
	}

	foreach my $j (sort keys %gene_mult_RNA){
		#print "$j\n";
		if (exists $gene_mult_RNA_count{"$j\t$gene_mult_RNA{$j}"}){
			$gene_mult_RNA_count{"$j\t$gene_mult_RNA{$j}"} += $mul_info[1];
			$gene_mult_RNA_ID{"$j\t$gene_mult_RNA{$j}"} .= "|$mul_info[2]";
		} else {
			$gene_mult_RNA_count{"$j\t$gene_mult_RNA{$j}"} = $mul_info[1];
			$gene_mult_RNA_ID{"$j\t$gene_mult_RNA{$j}"} = "$mul_info[2]";
		}
	}
	if ((length ($all_vari_change_aaRNA)) != 0){
		#print "$all_vari_change_aaRNA\n";
		print ALL_AAINFO "$all_vari_change_aaRNA\t$mul_info[1]\t$mul_info[2]\n";
		} else {
			#print "$all_vari_pattern{$i}\n";
		}

	if ((length ($all_vari_change_aaCodon)) != 0){
		print ALL_CODINFO "$all_vari_change_aaCodon\t$mul_info[1]\t$mul_info[2]\n";
		} else {
			#print "$all_vari_pattern{$i}\n";
	}
}

open CDS_ALL, ">$output_folder.variations.info.sum.txt" or die "Cannot write in $output_folder.cds_aa_change.all.txt:$!\n";
#T16683C	6	CDS	nsp13	16683	T	C	Syn	TAT149TAC	TAT	149	TAC	Y149Y	Y	149	Y
print CDS_ALL "snp\tcount\ttype\tanno\tsnp_loc\tsnp_ref\tsnp_alt\tcodon_type\tcodon_change\tcodon_loc\tcodon_ref\tcodon_alt\taa_change\taa_location\taa_ref\taa_alt\n";

foreach my $i (sort keys %vari_gene_info){
	my @line = split (/\t/, $vari_gene_info{$i});
	#"$j\t$line[0]\tCDS\t$var_type\t$codon_info\t$aa_info"
	my $codon_loc;
	my $codon_ref;
	my $codon_alt;

	if ($line[4] =~ /^(\D+)(\d+)(\D+)$/){
		$codon_loc = $2;
		$codon_ref = $1;
		$codon_alt = $3;
	}

	my $aa_loc;
	my $aa_ref;
	my $aa_alt;

	if ($line[5] =~ /^(\D+)(\d+)(\D+)$/){
		$aa_loc = $2;
		$aa_ref = $1;
		$aa_alt = $3;
	}
	#print CDS_ALL "vari_gene_info: $vari_gene_info{$i}\n";
	#print CDS_ALL "Old_output: $line[0]\t$vari_locations{$line[0]}\t$line[1]\t$line[3]\t$line[2]\t$line[4]\t$line[5]\t$count_all{$i}\n";
	print CDS_ALL "$line[0]\t$count_all{$i}\t$line[2]\t$line[1]\t$vari_locations{$line[0]}\t$vari_ref{$line[0]}\t$vari_alt{$line[0]}\t$line[3]\t$line[4]\t$codon_loc\t$codon_ref\t$codon_alt\t$line[5]\t$aa_loc\t$aa_ref\t$aa_alt\n";
	#print CDS_ALL "$line[0]\t$vari_locations{$line[0]}\t$line[1]\t$line[3]\t$line[2]\t$line[4]\t$line[5]\t$count_all{$i}\n";

}
close CDS_ALL;

open AACOUNT, ">$output_folder.count_aa.txt" or die "Cannot write in $output_folder.aa_count.txt: $!\n";
print AACOUNT "#Var\tAnno\tType\tCount\n";
foreach my $i (sort keys %count_var_aa){
	my @line = split (/\t/, $i);
	my $ref;
	my $alt;
	if ($line[1] =~ /^(\D+)\d+(\D+)$/){
		$ref = $1;
		$alt = $2;
	}
	if ($ref ne $alt){
		print AACOUNT "$line[1]\t$line[0]\t$type_var_aa{$i}\t$count_var_aa{$i}\t\n";
	}
}
close AACOUNT;

open CODCOUNT, ">$output_folder.count_codon.txt" or die "Cannot write in $output_folder.codon_count.txt: $!\n";
print CODCOUNT "#Var\tAnno\tType\tAA\tCount\n";
foreach my $i (sort keys %count_var_codon){
	my @line = split (/\t/, $i);
	print CODCOUNT "$line[1]\t$line[0]\t$type_var_codon{$i}\t$count_var_codon{$i}\n";
}
close CODCOUNT;

open RNACOUNT, ">./$output_folder.count_RNA.txt" or die "Cannot create $output_folder.RNA_change.txt: $!\n";
print RNACOUNT "#Var\tAnno\tType\tCount\n";
foreach my $i (sort keys %count_var_RNA){
	my @line = split (/\t/, $i);
	print RNACOUNT "$line[1]\t$line[0]\t$type_var_RNA{$i}\t$count_var_RNA{$i}\n";
}
close RNACOUNT;


foreach my $i (sort keys %gene_mult_codon_count){
	my @info = split (/\t/, $i);
	open COD, ">>./${output_folder}_codon/$info[0].txt";
	print COD "$info[1]\t$gene_mult_codon_count{$i}\t$gene_mult_codon_ID{$i}\n";
}
close COD;

foreach my $i (sort keys %gene_mult_aa_count){
	my @info = split (/\t/, $i);
	open AA, ">>./${output_folder}_aa/$info[0].txt";
	print AA "$info[1]\t$gene_mult_aa_count{$i}\t$gene_mult_aa_ID{$i}\n";
}
close AA;

foreach my $i (sort keys %gene_mult_RNA_count){
	my @info = split (/\t/, $i);
	open RNA0, ">>./${output_folder}_rna/$info[0].txt";
	print RNA0 "$info[1]\t$gene_mult_RNA_count{$i}\t$gene_mult_RNA_ID{$i}\n";
}
close RNA0;





sub read_fasta{
	open READ_SEQ, "@_" or die "Can not read Sequence file: $!\n";
	my %sequences;
	my $id;
	my $count = 0;
	my $seq_length;
	while (<READ_SEQ>){
	chomp;
	s/\r//;
	if ($_ =~ /^>(?<seq_name>.*$)/){
		$id  = $+{seq_name};
		$count += 1;
	}else{
		$sequences{$id} .= $_;
		$seq_length = length ($sequences{$id});
		}
	}
	#print "Successfuly read @_, in total $count sequences with $seq_length bp.\n";
	#print "\n";
	%sequences;
}

sub translate{
	my $cds = $_[0];
	#print "cds is $cds\n";
	if ((length ($cds))%3 == 0){
		my @aa = ( $cds =~ m/.../g );
		my $aa = "";
		foreach my $i (@aa){
			if (exists $table{$i}){
				$aa .= $table{$i};
				} else {
					$aa .= "X";
				}
			}
			$aa;
		} elsif ((length ($cds)) < 3){
				my $aa = "Z"; ##
				#print "$cds is not multiple of 3\n";
				$aa;
			} else {
				#print "$cds is not multiple of 3\n";
				my $shift_size = (length ($cds)) % 3;
				my $cut_length = (int ((length ($cds))/3)) * 3;
				my $sub_str = substr ($cds, 0, $cut_length);
				my @aa = ( $cds =~ m/.../g );
				my $aa = "";
				foreach my $i (@aa){
					if (exists $table{$i}){
					$aa .= $table{$i};
					} else {
						#print "Error, codon $i could not find\n";
						$aa .= "-";
					}
				}
				$aa."Z";
			}
		
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}
