#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
#version 21_5_10, sequences with no variation sites before and after screening is added
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;

my %opts;
getopts('i:o:', \%opts);
my $input_variants_file = $opts{'i'} or die "use: $0 -i input_variants_file -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_variants_file -o output_file\n";

my %vari_sum_all;
my %vari_screen;
my %vari_with_N;
my %vari_insertion;
my %ins_count;
my %ins_loc;
my %ins_length;
my %ins_sequences;
my %del_start;
my %del_end;
my %del_count;
my %del_sequences;
my %vari_snp;
my %var_count;

open IN, "./$input_variants_file" or die "Cannot read $input_variants_file\n";
my $ref_length = 29903; #reference sequence is NC_045512.fas

my @sequences;
my $count = 0;
while (<IN>){
	chomp;
	$count ++;
	my @line = split (/\t/, $_);
	if (($count % 10000) == 0){
		print "Handling ${count}th sequence, $line[0]\n";
	}
	$vari_sum_all{$line[0]} = $line[1];
	push @sequences, $line[0];
	my @var = split (/\|/,$line[1]);
	foreach my $i (0..$#var){
		if (exists $var_count{$var[$i]}){
			$var_count{$var[$i]} ++;
		} else{
			$var_count{$var[$i]} = 1;
		}

		my $ref;
		my $loc;
		my $alt;
		if ($var[$i] =~ /([A-Z-]+)(\d+)([A-Z-]+)/){
			$ref = $1;
			$loc = $2;
			$alt = $3;
			my $last_var_length = length($ref);
			if (($i == $#var)&(($last_var_length + $loc - 1) == $ref_length)){
				#print "Last var $var[$i]\n";
			} elsif (($i == 0)&($loc == 1)){
				#print "First $var[$i]\n";
			} elsif ($var[$i] =~ /N+/){
				#print "Vari with N $var[$i]\n";
				if (exists $vari_with_N{$line[0]}){
					$vari_with_N{$line[0]} .= "|$var[$i]";
				} else{
					$vari_with_N{$line[0]} .= $var[$i];
				}
			} elsif ($loc == 0){
				#print "$line[0], strange start $var[$i]\n";
			} elsif ($alt =~ /-+/){
				#print "$line[0], deletion $var[$i]\n";

				my $deletion_length = length ($ref);
				if (exists $del_count{$var[$i]}){
					$del_count{$var[$i]} ++;
					$del_sequences{$var[$i]} .= "|$line[0]";
				} else {
					$del_count{$var[$i]} = 1;
					$del_sequences{$var[$i]} = $line[0];
				}

				$del_start{$var[$i]} = $loc;
				$del_end{$var[$i]} = $loc + $deletion_length - 1;


				if (exists $vari_screen{$line[0]}){
					$vari_screen{$line[0]} .= "|$var[$i]";
				} else {
					$vari_screen{$line[0]} = $var[$i];
				}
			} elsif ((length($ref)) < (length($alt))){
				#print "$line[0], Insertion $var[$i]\n";
				if (exists $ins_count{$var[$i]}){
					$ins_count{$var[$i]} ++;
					$ins_sequences{$var[$i]} .= "|$line[0]";
				} else{
					$ins_count{$var[$i]} = 1;
					$ins_sequences{$var[$i]} = $line[0];
				}

				$ins_length{$var[$i]} = (length ($alt)) -(length ($ref));

				$ins_loc{$var[$i]} = $loc;

				if (exists $vari_screen{$line[0]}){
					$vari_screen{$line[0]} .= "|$var[$i]";
				} else {
					$vari_screen{$line[0]} .= $var[$i];
				}
			} elsif (!($alt =~ /[ATCG-]+/)){
				if (exists $vari_with_N{$line[0]}){
					$vari_with_N{$line[0]} .= "|$var[$i]";
				} else{
					$vari_with_N{$line[0]} .= $var[$i];
				}
				#print "$line[0], ambiguous sites $var[$i]\n";
			} else {
				#print "$line[0], SNP $var[$i]\n";
				if (exists $vari_snp{$line[0]}){
					$vari_snp{$line[0]} .= "|$var[$i]";
				} else{
					$vari_snp{$line[0]} = $var[$i]
				}
				if (exists $vari_screen{$line[0]}){
					$vari_screen{$line[0]} .= "|$var[$i]";
				} else {
					$vari_screen{$line[0]} = $var[$i];
				}
			}
		}
	}
}
close IN;

open SCREEN, ">./$output_file.screen.snp.txt" or die "Cannot write in $output_file.screen.snp.txt\n";
my %vari_screen_count;
my %vari_screen_sum;
foreach my $i (@sequences){
	if (exists $vari_screen{$i}){
		print SCREEN "$i\t$vari_screen{$i}\n";
		if (exists $vari_screen_sum{$vari_screen{$i}}){
			$vari_screen_count{$vari_screen{$i}} ++;
			$vari_screen_sum{$vari_screen{$i}} .= "|$i";
		} else{
			$vari_screen_count{$vari_screen{$i}} = 1;
			$vari_screen_sum{$vari_screen{$i}} = $i;
		}
	} else {
		if ($vari_sum_all{$i} eq "0change"){
			print SCREEN "$i\t0change\n";
			if (exists $vari_screen_sum{"0change"}){
			$vari_screen_count{"0change"} ++;
			$vari_screen_sum{"0change"} .= "|$i";
			} else{
				$vari_screen_count{"0change"} = 1;
				$vari_screen_sum{"0change"} = $i;
			}
		} else {
			print SCREEN "$i\t0change_after_screen\n";
			if (exists $vari_screen_sum{"0change_after_screen"}){
			$vari_screen_count{"0change_after_screen"} ++;
			$vari_screen_sum{"0change_after_screen"} .= "|$i";
			} else{
				$vari_screen_count{"0change_after_screen"} = 1;
				$vari_screen_sum{"0change_after_screen"} = $i;
			}
		}
	}
}

open SCREEN_COUNT, ">./$output_file.screen.ID.sum.txt" or die "Cannot write in $output_file.screen.ID.sum.txt\n";
foreach my $i (sort keys %vari_screen_count){
	print SCREEN_COUNT "$i\t$vari_screen_count{$i}\t$vari_screen_sum{$i}\n";
}

open DEL, ">./$output_file.deletion.txt" or die "Cannot write in $output_file.deletion.txt\n";
print DEL "var\tlength\tloc\tstart_end\tcount\tseq\n";

foreach my $i (sort keys %del_count){
	my $del_length = $del_end{$i} - $del_start{$i} + 1;
	print DEL "$i\t$del_length\t$del_start{$i}\t$del_start{$i}..$del_end{$i}\t$del_count{$i}\t$del_sequences{$i}\n";
}
close DEL;

open INS, ">./$output_file.insertion.txt" or die "Cannot write in $output_file.insertion.txt\n";
print INS "var\tlength\tloc\tcount\tseq\n";

foreach my $i (sort keys %ins_count){
	print INS "$i\t$ins_length{$i}\t$ins_loc{$i}\t$ins_count{$i}\t$ins_sequences{$i}\n";
}
close INS;

#open N_SUM, ">./$output_file.N_sum.txt" or die "Cannot write in $output_file.N_sum.txt\n";



