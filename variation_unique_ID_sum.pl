#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;
#Version 21.3.8.4
#long table only
#perl variation_unique_ID_sum.pl -i ../Variations_for_whole_genome
#version 7.14 open all outputs

my %opts;
getopts('i:', \%opts);
my $input_vari_info_folder = $opts{'i'} or die "use: $0 -i input_vari_info_folder\n";
my $output_folder = "${input_vari_info_folder}_ID_unique";
my $output_folder2 = "${input_vari_info_folder}_long_table";
my $output_folder3 = "${input_vari_info_folder}_var_for_each_ID";

chdir "./$input_vari_info_folder" or die "Cannot enter $input_vari_info_folder: $!\n";
my @vari_files = glob ("*.txt");
chdir "../";
if (!(-e $output_folder)){
	mkdir "./$output_folder" or die "Cannot make folder $output_folder: $!\n";
} else {
	system "rm ./$output_folder/*.txt";
}

if (!(-e $output_folder2)){
	mkdir "./$output_folder2" or die "Cannot make folder $output_folder2: $!\n";
} else {
	system "rm ./$output_folder2/*.txt";
}

if (!(-e $output_folder3)){
	mkdir "./$output_folder3" or die "Cannot make folder $output_folder3: $!\n";
} else {
	system "rm ./$output_folder3/*.txt";
}

foreach my $i (@vari_files){
	open IN, "$input_vari_info_folder/$i" or die "Cannot read ./$input_vari_info_folder/$i: $!\n";
	my %vari_ID;
	my %vari_number;
	my %each_id_vari;
	while (<IN>){
		chomp;
		my @line = split (/\t/, $_);
		my @vari = split (/\|/, $line[0]);
		foreach my $j (@vari){
			if (exists $vari_ID{$j}){
				$vari_ID{$j} .= "|$line[2]";
				$vari_number{$j} += $line[1];
			} else {
				$vari_ID{$j} .= $line[2];
				$vari_number{$j} = $line[1];
			}
		}
		my @id = split (/\|/, $line[2]);
		foreach my $t (@id){
			$each_id_vari{$t} = $line[0];
		}
	}
	close IN;
	open OUT, ">./$output_folder/$i";
	open OUT2, ">./$output_folder2/$i";
	foreach my $j (sort keys %vari_ID){
		my @id = split (/\|/, $vari_ID{$j});
		my @uniq_id = &uniq(@id);
		my $uniq_id = join ("|", @uniq_id);
		my $uniq_id_number = scalar (@uniq_id);
		print OUT "$j\t$uniq_id_number\t$uniq_id\n";

		foreach my $t (@uniq_id){
			print OUT2 "$j\t$t\n";
		}
	}
	close OUT;
	close OUT2;
	#system "gzip ./$output_folder/$i";
	#system "gzip ./$output_folder2/$i";

	open OUT3, ">./$output_folder3/$i";
	foreach my $j (sort keys %each_id_vari){
		print OUT3 "$j\t$each_id_vari{$j}\n";
	}
	close OUT3;
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

