#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('i:', \%opts);
my $input_raw_variants_file = $opts{'i'} or die "use: $0 -i input_raw_variants_file\n";
my $output_file_name = $input_raw_variants_file;

$output_file_name =~ s/(\w+)\..*$/$1/;
print "$output_file_name\n";


my $input_reference_genome = "NC_045512.fas";
my $input_reference_cds = "NC_045512.cds.Exc1ab.overlapAdded.fas";


if (!(-e $input_raw_variants_file)){
	print "Could not find input_raw_variants_file: $input_raw_variants_file, please check...\nExit...\n";
	exit;
}

if (!(-e $input_reference_genome)){
	print "Could not find input_reference_genome: $input_reference_genome, please check...\nExit...\n";
	exit;
}

if (!(-e $input_reference_cds)){
	print "Could not find input_reference_cds: $input_reference_cds, please check...\nExit...\n";
	exit;
}

my $options;

print "Step1, screening raw variations\n";
$options = "perl screen_summzrize_data_del_int.pl -i $input_raw_variants_file -o $output_file_name";
print "$options\n\n";
system $options;

print "Step2, map snps to cds\n";
$options = "perl MapProtein_SARS2_aa_RNA_nsp_indel.pl -i $output_file_name.screen.ID.sum.txt -o $output_file_name";
print "$options\n\n";
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
$options = "perl variation_unique_ID_sum.pl -i $genomic_variation_folder";
print "$options\n\n";
system $options;



