#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('i:j:s:o:', \%opts);
my $input_fasta_gz = $opts{'i'} or die "use: $0 -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta\n";
my $input_name2ID = $opts{'j'} or die "use: $0 -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta\n";
my $selected_id = $opts{'s'} or die "use: $0 -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta\n";
my $output_fasta = $opts{'o'} or die "use: $0 -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta\n";

my $options;
$options = "perl pickup_gene_from_name2ID_list.pl -i $input_name2ID -j $selected_id -o $output_fasta.selected_name2id";
print "$options\n";
system "$options";

$options = "perl pickup_genes_from_GISAID_sequence.pl -i $input_fasta_gz -j $output_fasta.selected_name2id -o $output_fasta";
print "$options\n";
system "$options";

$options = "mafft $output_fasta.fas > $output_fasta.align.fas";
print "$options\n";
system "$options";
