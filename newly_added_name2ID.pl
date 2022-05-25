#!/usr/bin/env perl -w
# (Copyright) Jiaqi Wu
use diagnostics;
use 5.010;
use strict;
use Cwd;
use Getopt::Std;

my %opts;
getopts('i:j:o:', \%opts);
my $old_id = $opts{'i'} or die "use: $0 -i old_name2id -j new_name2id -o newly_added_name2id\n";
my $new_id = $opts{'j'} or die "use: $0 -i old_name2id -j new_name2id -o newly_added_name2id\n";
my $newly_added = $opts{'o'} or die "use: $0 -i old_name2id -j new_name2id -o newly_added_name2id\n\n";

my %old_id;
open OLD, "./$old_id" or die "Cannot read $old_id: $!\n";
while (<OLD>){
	chomp;
	my @line = split (/\t/, $_);
	$old_id{"$line[1]"} = "";
}
close OLD;

open NEW, "./$new_id" or die "Cannot read $new_id: $!\n";
open OUT, ">./$newly_added.txt" or die "Cannot write in $newly_added.txt : $!\n";
while (<NEW>){
	chomp;
	my @line = split (/\t/, $_);
	if (!(exists $old_id{$line[1]})){
		print OUT "$_\n";
	}
}

close NEW;
close OUT;
