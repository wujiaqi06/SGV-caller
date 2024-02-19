#!/usr/bin/env perl -w
# written by Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;
use File::Copy;
#version 2021.4.9

my %opts;
getopts('i:r:a:o:', \%opts);
my $input_fasta = $opts{'i'} or die "use: $0 -i input_fasta -r reference -a gene_anno -o output_file\n";
my $ref = $opts{'r'} or die "use: $0 -i input_fasta -r reference -a gene_anno -o output_file\n";
my $gene_anno = $opts{'a'} or die "use: $0 -i input_fasta -r reference -a gene_anno -o output_file\n";
my $output_file = $opts{'o'} or die "use: $0 -i input_fasta -r reference -a gene_anno -o output_file\n";
#read reference data
my %ref_seq = &read_fasta($ref);
my @ref_name = keys %ref_seq;
my @ref;
my $ref_length = length ($ref_seq{$ref_name[0]});

if (!(-e "./${output_file}_gene")){
	mkdir "./${output_file}_gene" or die "Cannot make folder ${output_file}_gene: $!\n";
} else {
	system "rm ./${output_file}_gene/*.fas";
}


open TEM, ">temp.txt";

open VARINDALL, ">./$output_file.Variants_info.ForEachSeq.all.txt" or die "Cannot read ForEachSeq.all.txt: $!\n";

if ((scalar @ref_name) != 1){
	print "There are more than 1 sequence in reference file!\n";
} else {
	@ref = split (//, $ref_seq{$ref_name[0]});
}

open ANNO, $gene_anno or die "Cannot read $gene_anno: $!\n";
my %gene_start;
my %gene_end;
while (<ANNO>){
	chomp;
	my @line = split (/\t/, $_);
	$gene_start{$line[0]} = $line[1];
	$gene_end{$line[0]} = $line[2];
}
close ANNO;


if ($input_fasta =~ /\.gz$/){
	open DATA_SEQ, "gzip -dc $input_fasta |" or die "Can not read Sequence file $input_fasta: $!\n";
	} elsif ($input_fasta =~ /\.tar\.xz$/){
	open DATA_SEQ, "tar -xOf $input_fasta sequences.fasta|" or die "Can not read Sequence file $input_fasta: $!\n";
	} else {
	open DATA_SEQ, $input_fasta or die "Can not read Sequence file $input_fasta: $!\n";
}

if (-e "$output_file.seq.align.fas"){
	system "rm $output_file.seq.align.fas";
}

if (-e "$output_file.seq.temp.fas"){
	system "rm $output_file.seq.temp.fas";
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
my $count_line = 0;
while (<DATA_SEQ>){
	chomp;
	$count_line ++;
	if (/^>(?<seq_name>.+$)/){
		$old_id = $id;
		$id = $+{seq_name};
		if ($old_id ne ""){	
			open OUT, ">./$output_file.seq.temp.fas" or die "Cannot write in $output_file.seq.temp.fas: $!\n";
			print OUT ">$ref_name[0]\n$ref_seq{$ref_name[0]}\n";
			print OUT ">$old_id\n$seq\n";
			#mafft --globalpair --maxiterate 1000 input [> output]
			system ("mafft $output_file.seq.temp.fas > $output_file.seq.align.fas");
			close OUT;
			$seq_name = $old_id;
			}
		$count ++;
		$seq = "";
	} else {
		$seq .= $_;
	}

	if (eof){
		open OUT, ">./$output_file.seq.temp.fas" or die "Cannot write in $output_file.seq.temp.fas: $!\n";
		print OUT ">$ref_name[0]\n$ref_seq{$ref_name[0]}\n";
		print OUT ">$id\n$seq\n";
		system ("mafft $output_file.seq.temp.fas > $output_file.seq.align.fas");
		$seq_name = $id;
		close OUT;
	}

	if (-e "$output_file.seq.align.fas"){
		my %align = &read_fasta("$output_file.seq.align.fas");
		my @align_seq = keys %align;
		print TEM "seq_aligned are @align_seq\n";
		my %var_ref;
		my %var_alt;
		##march reference location
		my @ref_align = split (//, $align{$ref_name[0]});
		delete $align{$ref_name[0]};
		my @obj_align = split (//,$align{$seq_name});
		print TEM "sequence is $seq_name\n";
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
		my $length0 = scalar(@obj_align);
		foreach my $gene (sort keys %gene_start){
			open GENE, ">>./${output_file}_gene/$gene.fas" or die "Cannot write in ${output_file}_gene/$gene.fas: $!\n"; 
			#open GENE_S, ">>./${output_file}_gene/$gene.shift.fas" or die "Cannot write in ${output_file}_gene/$gene.shift.fas: $!\n"; 
			my $start = $gene_start{$gene} - 1;
			my $end = $gene_end{$gene} - 1;
			my @gene_seq = @obj_align[$start..$end];
			my $gene_seq = join ("", @gene_seq);
			#$gene_seq =~ s/(---)+//g;
			print GENE ">$seq_name\n$gene_seq\n";
			#if ($gene_seq =~ /-/){
			#	print GENE_S ">$seq_name\n$gene_seq\n";
			#}
		}

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
			#print TEM "$seq_name, Find 0 location, $var_ref{0}0$var_alt{0}\n";
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

