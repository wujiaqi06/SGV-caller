#!/usr/bin/perl -w
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

##looking for configure file svg-caller.conf
my %opts;
getopts('i:', \%opts);
my $input_configure_file = "sgv-caller.conf";
if (exists $opts{'i'}) { $input_configure_file = $opts{'i'}; }
if (!-e $input_configure_file) { 
	die "Can't find configuration file: $input_configure_file\n"; 
}	else {
	open OPT, $input_configure_file or die $!;
}

my %options;
while (<OPT>){
	chomp;
	s/^\s+//g;
	s/\s+$//;
	#print "$_\n";
	if ((!/^#/)&(/^(\w+)\s*=\s*(.*)$/)){
		my @line = split (/\s*=\s*/, $_);
		$line[1] =~ s/^~//;
		$line[1] =~ s/\s*#.*//;
		$options{$line[0]} = $line[1];
		#print "$line[0]\t$line[1]\n";
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
##Each pipeline runs a different set of Perl scripts, so the contents of the checks are different.
if ($options{"calculation"} =~ /[12345]/){
	#software check
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/alignment2variants_no_screen_linux.pl")){
		print "\nERROR: Could not find sgv-caller software alignment2variants_no_screen_linux.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/screen_summarize_data_del_int.pl")){
		print "\nERROR: can not find sgv-caller software screen_summarize_data_del_int.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl")){
		print "\nERROR: can not find sgv-caller software MapProtein_SARS2_aa_RNA_nsp_indel.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/variation_unique_ID_sum.pl")){
		print "\nERROR: can not find sgv-caller software variation_unique_ID_sum.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/raw_data_statistics.pl")){
		print "\nERROR: can not find sgv-caller software raw_data_statistics.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
	#annotation file check
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} =~ /[123]/){
	#software check
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/variation_log.pl")){
		print "\nERROR: can not find sgv-caller software variation_log.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

#Reference file check
##Software check to see if the required reference files can be found in the reference folder or not.
##if not, exit.
if ($options{"calculation"} =~ /[12345]/){
	if ($options{"use_default_reference"} eq "yes"){
		my $reference_loc = $script_dir."/reference";
		$reference_loc =~ s/^~//;
		$reference_loc =~ s/#.*$//;
		$reference_loc =~ s/\s;$//;
		if (!(-e "$reference_loc/NC_045512.fas")){
		print "\nERROR: can not find sgv-caller default reference genome NC_045512.fas, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
		}

		if (!(-e "$reference_loc/NC_045512.cds.anno.txt")){
		print "\nERROR: can not find sgv-caller default reference CDS annotation file NC_045512.cds.anno.txt, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
		}

		if (!(-e "$reference_loc/NC_045512.RNA.anno.txt")){
		print "\nERROR: can not find sgv-caller default reference RNA reference file NC_045512.RNA.anno.txt, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
		}
	} elsif ($options{"use_default_reference"} =~ /no/){
		print "Using custom reference genome, reading custom genome information\n";
		if (!(-e $options{"custom_reference_genome"})){
			print "\nERROR: can not find custom reference genome, please check custom_reference_genome is correct or not in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

	} else {
		print "ERROR: Wrong answer for use_default_reference!\n";
		print "WARNING: use_default_reference only take \"yes\" or \"no\" value in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} == 1){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/name2ID.pl")){
		print "\nERROR: can not find sgv-caller software name2ID.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} == 2){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/name2ID.pl")){
		print "\nERROR: can not find sgv-caller software name2ID.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/newly_added_name2ID.pl")){
		print "\nERROR: can not find sgv-caller software newly_added_name2ID.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} == 3){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/name2ID_for_fasta.pl")){
		print "\nERROR: can not find sgv-caller software name2ID_for_fasta.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} =~ /[56]/){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/name2ID_for_selected_ID_list.pl")){
		print "\nERROR: can not find sgv-caller software name2ID_for_selected_ID_list.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} == 6){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/pickup_genes_from_GISAID_sequence.pl")){
		print "\nERROR: can not find sgv-caller software pickup_gene_from_name2ID_list.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e "$software_loc/pickup_genes_from_GISAID_sequence.pl")){
		print "\nERROR: can not find sgv-caller software pickup_gene_from_name2ID_list.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

##Software check to see if the required Perl scripts can be found in the scripts folder or not.
##if not, exit.
if ($options{"calculation"} == 7){
	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	if (!(-e "$software_loc/alignment2variants_extract_genes.pl")){
		print "\nERROR: can not find sgv-caller software alignment2variants_extract_genes.pl, please check the path to sgv-caller software is correct or not!\n";
		print "WARNING: Please give absolute directory to sgv_caller_directory in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}
}

#pipeline 1
if ($options{"calculation"} == 1){
	print "\nCalculation 1, Calculating database from GSIAID fasta genome and GISAID database\n\n";
	#print "WARNING! input GISAID fasta genome and GISAID database should be gzip format!\n\n";
	print "WARNING! Either data from \"Genomic epidemiology\" or \"Download packages\" can be used directly, please do not unzip data!\n\n";
	my $input_fasta_sequence = $options{"input_GISAID_fasta_genome_file"};
	my $input_metadata = $options{"input_GISAID_metadata_file"};

	print "Input GISAID fasta genome file is $input_fasta_sequence\n";
	print "Input GISAID metadata file is $input_metadata\n";

	#Software check to see if the input sequence file could be found or not.
	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	#Software check to see if the input metadata file could be found or not.
	if (!(-e $input_metadata)){
		print "ERROR: can not find input_GISAID_metadata_file, please check options in svg-caller.conf!";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_metadata =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_metadata =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Metadata OK!\n\n";
			}
		}
	}

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";
	$reference_loc =~ s/^~//;
	$reference_loc =~ s/#.*$//;
	$reference_loc =~ s/\s;$//;

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_cds_file = $reference_loc."/NC_045512.cds.anno.txt";
	my $input_RNA_info_file = $reference_loc."/NC_045512.RNA.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};
		$input_cds_file = $options{"custom_codon_fasta_annotation_file"};
		$input_RNA_info_file = $options{"custom_rna_annotation"};

		if (!-e $input_reference_genome){
			print "ERROR! Cannot find custom reference genome $input_reference_genome!\n";
			print "WARNING: Please give correct file directory to custom_reference_genome in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_cds_file){
			print "ERROR! Cannot find custom reference cds annotation file $input_cds_file!\n";
			print "WARNING: Please give correct file directory to custom_codon_fasta_annotation_file in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_RNA_info_file){
			print "ERROR! Cannot find custom reference rna annotation file $input_RNA_info_file!\n";
			print "WARNING: Please give correct file directory to custom_rna_annotation in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">./$output_file_name.options.txt" or die $!;
	print "Step1, make name2ID file\n";
	$options = "perl $software_loc/name2ID.pl -i $input_metadata -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract raw variations from fasta sequence file\n";
	$options = "perl $software_loc/alignment2variants_no_screen_linux.pl -i $input_fasta_sequence -j $output_file_name.name2ID.txt -r $input_reference_genome -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, Compare differences between name2ID and raw_variant file\n";
	$options = "perl $software_loc/variation_log.pl -i $output_file_name.raw_variants.for_each.all.txt -j $output_file_name.name2ID.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	
	print "Step4, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	
	print "Step5, map snps to cds\n";
	$options = "perl $software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -j $input_reference_genome -c $input_cds_file -r $input_RNA_info_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step6, move genome-wide snps, codons and amino acid variations into genomic_variation folder\n";
	my $genomic_variation_folder = $output_file_name."_genomic_variation";
	if (!(-e $genomic_variation_folder)){
		mkdir "$genomic_variation_folder";
	} else {
		system "rm ./$genomic_variation_folder/*.txt";
	}
	move("$output_file_name.screen.ID.sum.txt","./$genomic_variation_folder/snp.txt");
	move("$output_file_name.all_info_ID.aa.sum.txt","./$genomic_variation_folder/aa.txt");
	move("$output_file_name.all_info_ID.Codon.sum.txt","./$genomic_variation_folder/codon.txt");

	print "step7, generate long tables for genomic variations";
	$options = "perl $software_loc/variation_unique_ID_sum.pl -i $genomic_variation_folder";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "step8, calculate quality statistics of each sequence";
	$options = "perl $software_loc/raw_data_statistics.pl -i $output_file_name.raw_variants.for_each.all.txt";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	close OPTS;
}

if ($options{"calculation"} == 2){
	print "\nCalculation 2, updating existing database by adding the differences between new GISAID data and exisiting GISAID database\n\n";
	#print "WARNING! input GISAID fasta genome and GISAID database should be gzip format!\n\n";
	print "WARNING! Either data from \"Genomic epidemiology\" or \"Download packages\" can be used directly, please do not unzip data!\n\n";
	
	my $old_database_directory = $options{"directory_of_previous_database"};
	my $old_output_name = $options{"output_file_name_of_previous_database"};
	
	my $input_existing_IDs = $old_database_directory."/".$old_output_name.".raw_variants.for_each.all.txt";
	my $input_old_raw_variants = $old_database_directory."/".$old_output_name.".raw_variants.for_each.all.txt";
	my $input_fasta_sequence = $options{"input_new_GISAID_fasta_genome"};
	my $input_metadata = $options{"input_new_GISAID_metadata"};

	my $existing_database = $options{"directory_of_previous_database"};

	if (!(-e ($input_existing_IDs))){
		print "ERROR: Cannot find $old_output_name.raw_variants.for_each.all.txt file in existing database: $old_database_directory!\n";
		print "EXIT...\n";
		exit;
	}

	if (!(-e ($input_old_raw_variants))){
		print "ERROR: Cannot find raw variation file in existing database: $old_database_directory!\n";
		print "EXIT...\n";
		exit;
	}
	print "The already existing database is $existing_database\n\n";
	print "Input GISAID fasta genome file is $input_fasta_sequence\n";
	print "Input GISAID metadata file is $input_metadata\n";
	print "###\n";
	
	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	if (!(-e $input_metadata)){
		print "ERROR: can not find input_GISAID_metadata_file, please check options in svg-caller.conf!";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_metadata =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_metadata =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Metadata OK!\n\n";
			}
		}
	}

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";
	$reference_loc =~ s/^~//;
	$reference_loc =~ s/#.*$//;
	$reference_loc =~ s/\s;$//;

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_cds_file = $reference_loc."/NC_045512.cds.anno.txt";
	my $input_RNA_info_file = $reference_loc."/NC_045512.RNA.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};
		$input_cds_file = $options{"custom_codon_fasta_annotation_file"};
		$input_RNA_info_file = $options{"custom_rna_annotation"};

		if (!-e $input_reference_genome){
			print "ERROR! Cannot find custom reference genome $input_reference_genome!\n";
			print "WARNING: Please give correct file directory to custom_reference_genome in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_cds_file){
			print "ERROR! Cannot find custom reference cds annotation file $input_cds_file!\n";
			print "WARNING: Please give correct file directory to custom_codon_fasta_annotation_file in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_RNA_info_file){
			print "ERROR! Cannot find custom reference rna annotation file $input_RNA_info_file!\n";
			print "WARNING: Please give correct file directory to custom_rna_annotation in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, make name2ID file\n";
	$options = "perl $software_loc/name2ID.pl -i $input_metadata -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, get newly added name2ID file\n";
	$options = "perl $software_loc/newly_added_name2ID.pl -i $input_existing_IDs -j $output_file_name.name2ID.txt -o $output_file_name.NewlyAdded.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, extract raw variations from fasta sequence file\n";
	$options = "perl $software_loc/alignment2variants_no_screen_linux.pl -i $input_fasta_sequence -j $output_file_name.NewlyAdded.name2ID.txt -r $input_reference_genome -o $output_file_name.newly_added";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step4, get merged raw variations for both new and old raw_variants file\n";
	$options = "cat $output_file_name.newly_added.raw_variants.for_each.all.txt $input_old_raw_variants > $output_file_name.raw_variants.for_each.all.txt";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step5, Compare differences between name2ID and raw_variant file\n";
	$options = "perl $software_loc/variation_log.pl -i $output_file_name.raw_variants.for_each.all.txt -j $output_file_name.name2ID.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step6, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step7, map snps to cds\n";
	$options = "perl $software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -j $input_reference_genome -c $input_cds_file -r $input_RNA_info_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step8, move genome-wide snps, codons and amino acid variations into genomic_variation folder\n";
	my $genomic_variation_folder = $output_file_name."_genomic_variation";
	if (!(-e $genomic_variation_folder)){
		mkdir "$genomic_variation_folder";
	} else {
		system "rm ./$genomic_variation_folder/*.txt";
	}
	move("$output_file_name.screen.ID.sum.txt","./$genomic_variation_folder/snp.txt");
	move("$output_file_name.all_info_ID.aa.sum.txt","./$genomic_variation_folder/aa.txt");
	move("$output_file_name.all_info_ID.Codon.sum.txt","./$genomic_variation_folder/codon.txt");

	print "step9, generate long tables for genomic variations";
	$options = "perl $software_loc/variation_unique_ID_sum.pl -i $genomic_variation_folder";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "step10, calculate quality statistics of each sequence";
	$options = "perl $software_loc/raw_data_statistics.pl -i $output_file_name.raw_variants.for_each.all.txt";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	close OPTS;
}

if ($options{"calculation"} == 3){
	print "\nCalculation 3, Calculating database directly from fasta formated sequence file, \n\n";
	print "WARNING! input fasta genome should be gzip format!\n\n";
	
	my $input_fasta_sequence = $options{"input_fasta_file"};

	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";
	$reference_loc =~ s/^~//;
	$reference_loc =~ s/#.*$//;
	$reference_loc =~ s/\s;$//;

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_cds_file = $reference_loc."/NC_045512.cds.anno.txt";
	my $input_RNA_info_file = $reference_loc."/NC_045512.RNA.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};
		$input_cds_file = $options{"custom_codon_fasta_annotation_file"};
		$input_RNA_info_file = $options{"custom_rna_annotation"};

		if (!-e $input_reference_genome){
			print "ERROR! Cannot find custom reference genome $input_reference_genome!\n";
			print "WARNING: Please give correct file directory to custom_reference_genome in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_cds_file){
			print "ERROR! Cannot find custom reference cds annotation file $input_cds_file!\n";
			print "WARNING: Please give correct file directory to custom_codon_fasta_annotation_file in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_RNA_info_file){
			print "ERROR! Cannot find custom reference rna annotation file $input_RNA_info_file!\n";
			print "WARNING: Please give correct file directory to custom_rna_annotation in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, make name2ID file\n";
	$options = "perl $software_loc/name2ID_for_fasta.pl -i $input_fasta_sequence -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract raw variations from fasta sequence file\n";
	$options = "perl $software_loc/alignment2variants_no_screen_linux.pl -i $input_fasta_sequence -j $output_file_name.name2ID.txt -r $input_reference_genome -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step4, map snps to cds\n";
	$options = "perl $software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -j $input_reference_genome -c $input_cds_file -r $input_RNA_info_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step5, move genome-wide snps, codons and amino acid variations into genomic_variation folder\n";
	my $genomic_variation_folder = $output_file_name."_genomic_variation";
	if (!(-e $genomic_variation_folder)){
		mkdir "$genomic_variation_folder";
	} else {
		system "rm ./$genomic_variation_folder/*.txt";
	}
	move("$output_file_name.screen.ID.sum.txt","./$genomic_variation_folder/snp.txt");
	move("$output_file_name.all_info_ID.aa.sum.txt","./$genomic_variation_folder/aa.txt");
	move("$output_file_name.all_info_ID.Codon.sum.txt","./$genomic_variation_folder/codon.txt");

	print "step6, generate long tables for genomic variations";
	$options = "perl $software_loc/variation_unique_ID_sum.pl -i $genomic_variation_folder";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "step7, calculate quality statistics of each sequence";
	$options = "perl $software_loc/raw_data_statistics.pl -i $output_file_name.raw_variants.for_each.all.txt";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	close OPTS;
}

if ($options{"calculation"} == 4){
	print "\nCalculation 4, making the database start from raw_variation file.\n\n";
	print "Input file is only raw_variants file\n\n";

	my $input_raw_variants_file = $options{"input_raw_variation_file"};

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";
	$reference_loc =~ s/^~//;
	$reference_loc =~ s/#.*$//;
	$reference_loc =~ s/\s;$//;

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_cds_file = $reference_loc."/NC_045512.cds.anno.txt";
	my $input_RNA_info_file = $reference_loc."/NC_045512.RNA.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};
		$input_cds_file = $options{"custom_codon_fasta_annotation_file"};
		$input_RNA_info_file = $options{"custom_rna_annotation"};

		if (!-e $input_reference_genome){
			print "ERROR! Cannot find custom reference genome $input_reference_genome!\n";
			print "WARNING: Please give correct file directory to custom_reference_genome in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_cds_file){
			print "ERROR! Cannot find custom reference cds annotation file $input_cds_file!\n";
			print "WARNING: Please give correct file directory to custom_codon_fasta_annotation_file in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_RNA_info_file){
			print "ERROR! Cannot find custom reference rna annotation file $input_RNA_info_file!\n";
			print "WARNING: Please give correct file directory to custom_rna_annotation in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int.pl -i $input_raw_variants_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, map snps to cds\n";
	$options = "perl $software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -j $input_reference_genome -c $input_cds_file -r $input_RNA_info_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, move genome-wide snps, codons and amino acid variations into genomic_variation folder\n";
	my $genomic_variation_folder = $output_file_name."_genomic_variation";
	if (!(-e $genomic_variation_folder)){
		mkdir "$genomic_variation_folder";
	} else {
		system "rm ./$genomic_variation_folder/*.txt";
	}
	move("$output_file_name.screen.ID.sum.txt","./$genomic_variation_folder/snp.txt");
	move("$output_file_name.all_info_ID.aa.sum.txt","./$genomic_variation_folder/aa.txt");
	move("$output_file_name.all_info_ID.Codon.sum.txt","./$genomic_variation_folder/codon.txt");

	print "step4, generate long tables for genomic variations";
	$options = "perl $software_loc/variation_unique_ID_sum.pl -i $genomic_variation_folder";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	close OPTS;
}

if ($options{"calculation"} == 5){
	print "\nCalculation 5, Calculating database of selected GISAID ID only\n\n";
	#print "WARNING! input GISAID fasta genome and GISAID database should be gzip format!\n\n";
	print "WARNING! Either data from \"Genomic epidemiology\" or \"Download packages\" can be used directly, please do not unzip data!\n\n";
	
	my $gisaid_id_list_file = $options{"GISAID_ID_list_file"};
	my $input_fasta_sequence = $options{"input_GISAID_fasta_genome_file2"};
	my $input_metadata = $options{"input_GISAID_metadata_file2"};
	print "The GSIAID id list file is $gisaid_id_list_file\n";

	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	if (!(-e $input_metadata)){
		print "ERROR: can not find input_GISAID_metadata_file, please check options in svg-caller.conf!";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_metadata =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_metadata =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Metadata OK!\n\n";
			}
		}
	}


	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";
	$reference_loc =~ s/^~//;
	$reference_loc =~ s/#.*$//;
	$reference_loc =~ s/\s;$//;

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_cds_file = $reference_loc."/NC_045512.cds.anno.txt";
	my $input_RNA_info_file = $reference_loc."/NC_045512.RNA.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};
		$input_cds_file = $options{"custom_codon_fasta_annotation_file"};
		$input_RNA_info_file = $options{"custom_rna_annotation"};

		if (!-e $input_reference_genome){
			print "ERROR! Cannot find custom reference genome $input_reference_genome!\n";
			print "WARNING: Please give correct file directory to custom_reference_genome in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_cds_file){
			print "ERROR! Cannot find custom reference cds annotation file $input_cds_file!\n";
			print "WARNING: Please give correct file directory to custom_codon_fasta_annotation_file in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}

		if (!-e $input_RNA_info_file){
			print "ERROR! Cannot find custom reference rna annotation file $input_RNA_info_file!\n";
			print "WARNING: Please give correct file directory to custom_rna_annotation in $input_configure_file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};


	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, extract name2ID from gene list file\n";
	$options = "perl $software_loc/name2ID_for_selected_ID_list.pl -i $input_metadata -j $gisaid_id_list_file -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract raw variations from fasta sequence file\n";
	$options = "perl $software_loc/alignment2variants_no_screen_linux.pl -i $input_fasta_sequence -j $output_file_name.name2ID.txt -r $input_reference_genome -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step4, map snps to cds\n";
	$options = "perl $software_loc/MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -j $input_reference_genome -c $input_cds_file -r $input_RNA_info_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step5, move genome-wide snps, codons and amino acid variations into genomic_variation folder\n";
	my $genomic_variation_folder = $output_file_name."_genomic_variation";
	if (!(-e $genomic_variation_folder)){
		mkdir "$genomic_variation_folder";
	} else {
		system "rm ./$genomic_variation_folder/*.txt";
	}
	move("$output_file_name.screen.ID.sum.txt","./$genomic_variation_folder/snp.txt");
	move("$output_file_name.all_info_ID.aa.sum.txt","./$genomic_variation_folder/aa.txt");
	move("$output_file_name.all_info_ID.Codon.sum.txt","./$genomic_variation_folder/codon.txt");

	print "step6, generate long tables for genomic variations";
	$options = "perl $software_loc/variation_unique_ID_sum.pl -i $genomic_variation_folder";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "step7, calculate quality statistics of each sequence";
	$options = "perl $software_loc/raw_data_statistics.pl -i $output_file_name.raw_variants.for_each.all.txt";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;
	close OPTS;
}

if ($options{"calculation"} == 6){
	print "\nCalculation 6, Extract sequences of selected GISAID IDs\n\n";
	#print "WARNING! input GISAID fasta genome and GISAID database should be gzip format!\n\n";
	print "WARNING! Either data from \"Genomic epidemiology\" or \"Download packages\" can be used directly, please do not unzip data!\n\n";

	my $gisaid_id_list_file = $options{"GISAID_ID_list_file"};
	my $input_fasta_sequence = $options{"input_GISAID_fasta_genome_file2"};
	my $input_metadata = $options{"input_GISAID_metadata_file2"};
	print "The GSIAID id list file is $gisaid_id_list_file\n";

	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	if (!(-e $input_metadata)){
		print "ERROR: can not find input_GISAID_metadata_file, please check options in svg-caller.conf!";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_metadata =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_metadata =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Metadata OK!\n\n";
			}
		}
	}

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, extract name2ID from gene list file\n";
	$options = "perl $software_loc/name2ID_for_selected_ID_list.pl -i $input_metadata -j $gisaid_id_list_file -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract sequences from gene list file\n";
	$options = "perl $software_loc/pickup_genes_from_GISAID_sequence.pl -i $input_fasta_sequence -j $output_file_name.name2ID.txt -o $output_file_name";
	print "$options\n";
	print OPTS "$options\n";
	system "$options";
	close OPTS;
}

if ($options{"calculation"} == 7){
	print "\nCalculation 7, Extract genetic regions of selected GISAID IDs\n\n";
	#print "WARNING! input GISAID fasta genome and GISAID database should be gzip format!\n\n";
	print "WARNING! Either data from \"Genomic epidemiology\" or \"Download packages\" can be used directly, please do not unzip data!\n\n";

	my $gisaid_id_list_file = $options{"GISAID_ID_list_file"};
	my $input_fasta_sequence = $options{"input_GISAID_fasta_genome_file2"};
	my $input_metadata = $options{"input_GISAID_metadata_file2"};
	print "The GSIAID id list file is $gisaid_id_list_file\n";

	if (!(-e $input_fasta_sequence)){
		print "ERROR: can not find input input_GISAID_fasta_genome_file $input_fasta_sequence\n";
		print "WARNING: Please give correct file directory to input_GISAID_fasta_genome_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_fasta_sequence =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_fasta_sequence =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_fasta_sequence 2>&1`;
			print "Sequence file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Sequence data OK!\n\n";
			}
		}
	}

	if (!(-e $input_metadata)){
		print "ERROR: can not find input_GISAID_metadata_file, please check options in svg-caller.conf!";
		print "EXIT...\n";
		exit;
	} else{
		if ($input_metadata =~ /\.gz$/){
			my $file_check = `gzip -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			}
		} elsif ($input_metadata =~ /\.tar.xz$/){
			my $file_check = `xz -t -v $input_metadata 2>&1`;
			print "Metadata file check: \n$file_check###\n";
			if ($file_check =~ /Unexpected/){
				print "ERROR! $input_metadata is incomplete!\nPlease check your file!\n";
				print "EXIT...\n";
				exit;
			} else{
				print "Metadata OK!\n\n";
			}
		}
	}

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;
	
	my $reference_loc = $script_dir."/reference";

	my $input_reference_genome = $reference_loc."/NC_045512.fas";
	my $input_gene_anno_file = $reference_loc."/NC_045512.anno.txt";

	if ($options{"use_default_reference"} =~ /no/){
		$input_reference_genome = $options{"custom_reference_genome"};

		if (!(-e $input_reference_genome)){
			print "ERROR: Cannot find custom reference genome: $input_reference_genome\n";
			print "Please check the following value in $input_configure_file:\nuse_default_reference\ncustom_reference_genome\n";
			print "EXIT...\n";
			exit;
		}
	}

	if ($options{"gene_annotation_file"} ne "default"){
		$input_gene_anno_file = $options{"gene_annotation_file"};
		if (!(-e $input_gene_anno_file)){
			print "ERROR: Cannot find custom reference genome: $input_gene_anno_file\n";
			print "Please check the following value in $input_configure_file:\ngene_annotation_file\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Step1, extract name2ID from gene list file\n";
	$options = "perl $software_loc/name2ID_for_selected_ID_list.pl -i $input_metadata -j $gisaid_id_list_file -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract sequences from gene list file\n";
	$options = "perl $software_loc/pickup_genes_from_GISAID_sequence.pl -i $input_fasta_sequence -j $output_file_name.name2ID.txt -o $output_file_name";
	print "$options\n";
	print OPTS "$options\n";
	system "$options";

	print "Step3, gizp output fasta file\n";
	$options = "gzip -f $output_file_name.fas";
	print "$options\n";
	print OPTS "$options\n";
	system $options;

	# alignment2variants_extract_genes.pl -i input_fasta -r reference -a gene_anno -o output_file
	print "Step3, extract sequences from gene list file\n";
	$options = "perl $software_loc/alignment2variants_extract_genes.pl -i $output_file_name.fas.gz -r $input_reference_genome -a $input_gene_anno_file -o ${output_file_name}_genes";
	print "$options\n";
	print OPTS "$options\n";
	system "$options";

	print "Finished! genetic regions of $gisaid_id_list_file is saved in ${output_file_name}_genes_gene folder!\n";
	close OPTS;
}

if ($options{"calculation"} == 8){
	print "\nCalculation 8, Extract amino acid variations directly from protein sequences\n\n";
	print "You should give a protein sequence file (gzip format) and a protein reference sequence.\n";

	my $software_loc = $script_dir."/scripts";
	$software_loc =~ s/^~//;
	$software_loc =~ s/#.*$//;
	$software_loc =~ s/\s;$//;

	my $protein_sequence_file = $options{"protein_sequence_file"};
	if (!(-e $protein_sequence_file)){
		print "ERROR: can not find protein_sequence_file: $protein_sequence_file, please check protein_sequence_file value in $input_configure_file.\n";
		print "EXIT...\n";
		exit;
	} else {
		my $file_check = `gzip -t -v $protein_sequence_file 2>&1`;
		print "Sequence file check: \n$file_check###\n";
		if (($file_check =~ /NOT\sOK/)|($file_check =~ /invalid/)|($file_check =~ /error/)){
			print "ERROR: $protein_sequence_file is incomplete!\nPlease check your file!\n";
			print "EXIT...\n";
			exit;
		}
	}

	my $protein_reference_file = $options{"protein_reference_sequence_file"};
	if (!(-e $protein_reference_file)){
		print "ERROR: can not fine protein_reference_sequence_file $protein_reference_file!\n";
		print "Please check value of protein_reference_sequence_file in $input_configure_file!\n";
		print "EXIT...\n";
		exit;
	}

	my $output_file_name = $options{"output_file_name"};

	my $options;
	open OPTS, ">$output_file_name.options.txt";
	print "Extracting amino acid variations directly from protein sequences\n";
	print "Reference sequence file is $protein_reference_file\n";
	
	print "Step1, make name2ID file\n";
	$options = "perl $software_loc/name2ID_for_fasta.pl -i $protein_sequence_file -o $output_file_name.name2ID";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step2, extract raw variations from fasta sequence file\n";
	$options = "perl $software_loc/alignment2variants_no_screen_linux.pl -i $protein_sequence_file -j $output_file_name.name2ID.txt -r $protein_reference_file -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Step3, screening raw variations\n";
	$options = "perl $software_loc/screen_summarize_data_del_int_aa.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
	print "$options\n\n";
	print OPTS "$options\n";
	system $options;

	print "Finished! amino acid variations are saved in $output_file_name.amino_acid.for_each.txt and $output_file_name.amino_acid.haplo.sum.txt files.\n";
	close OPTS;
}
