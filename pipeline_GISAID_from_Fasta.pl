#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('i:o:', \%opts);
my $input_fasta_sequence = $opts{'i'} or die "use: $0 -i input_fasta_sequence -o output_file_name\n";
my $output_file_name = $opts{'o'} or die "use: $0 -i input_fasta_sequence -o output_file_name\n";

my $input_reference_genome = "NC_045512.fas";
my $input_reference_cds = "NC_045512.cds.Exc1ab.overlapAdded.fas";

if (!(-e $input_fasta_sequence)){
	print "Error! Could not find input_fasta_sequence: $input_fasta_sequence, please check...\nExit...\n";
	exit();
} else {
	my $file_check = `gzip -t -v $input_fasta_sequence 2>&1`;
	print "Sequence file check: \n$file_check###\n";
	if ($file_check =~ /NOT\sOK/){
		print "ERROR! $input_fasta_sequence is incomplete!\nPlease check your file!\nExit...\n";
		exit();
	}
}

if (!(-e $input_reference_genome)){
	print "Error! Could not find input_reference_genome: $input_reference_genome, please check...\nexit()...\n";
	exit();
}

if (!(-e $input_reference_cds)){
	print "Error! Could not find input_reference_cds: $input_reference_cds, please check...\nexit()...\n";
	exit();
}

my $options;

print "Step1, make name2ID file\n";
$options = "perl name2ID_for_fasta.pl -i $input_fasta_sequence -o name2ID";
print "$options\n\n";
system $options;

print "Step2, extract raw variations from fasta sequence file\n";
$options = "perl alignment2varients_no_screen_linux.pl -i $input_fasta_sequence -j name2ID.txt -r $input_reference_genome -o $output_file_name";
print "$options\n\n";
system $options;

print "Step3, screening raw variations\n";
$options = "perl screen_summzrize_data_del_int.pl -i $output_file_name.raw_variants.for_each.all.txt -o $output_file_name";
print "$options\n\n";
system $options;

print "Step4, map snps to cds\n";
$options = "perl MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -o $output_file_name";
print "$options\n\n";
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
$options = "perl variation_unique_ID_sum.pl -i $genomic_variation_folder";
print "$options\n\n";
system $options;

print "step7, calculate quality statistics of each sequence";
$options = "perl raw_data_statistics.pl -i $output_file_name.raw_variants.for_each.all.txt";
print "$options\n\n";
system $options;

