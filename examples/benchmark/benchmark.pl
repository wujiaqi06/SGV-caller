#!/usr/bin/env perl
#
# Benchmark script for the SVG-caller pipeline
# Version 1.0.0
# by Kirill Kryukov
# in public domain under the CC0 license.
#

use strict;
use File::Path qw(make_path);

# Options.
my $clean_up = 0;
my $patch_sgv_caller = 1;
my $result_table_file = "benchmark-result-table.tsv";



# Checking disk space.
my $df = `df -B 1 . | tail -n 1 | awk '{print \$4}'`;
if ($df !~ /^(\d+)/) { die "Can't get free disk space\n"; }
my $dfgb = $1 / 1000000000;
my $dfgb_needed = 10;
if ($dfgb < $dfgb_needed) { die sprintf("Too little free disk space: found %.1f GB, need %.1f GB\n", $dfgb, $dfgb_needed); }
printf("Found %.1f GB of free disk space\n", $dfgb);



# Checking mafft.
my $mafftver = `mafft --version 2>&1`;
if ($mafftver !~ /v(\d+\.\d+\S*)/) { die "Can't find mafft\n"; }
$mafftver = $1;
print "Found mafft $mafftver\n";



# Cleaning up.
if ($clean_up)
{
    system("rm -rf SGV-caller test-data test-data.zip benchmark $result_table_file");
}



# Downloading SGV-caller from GitHub and patching it.
if (!-e 'SGV-caller')
{
    system('git clone https://github.com/wujiaqi06/SGV-caller');
    system('chmod a+x SGV-caller/sgv-caller.pl');

    if ($patch_sgv_caller)
    {
        foreach my $s ( 'alignment2variants_no_screen_linux.pl',
                        'name2ID.pl',
                        'name2ID_for_fasta.pl',
                        'pickup_genes_from_GISAID_sequence.pl' )
        {
            rename("SGV-caller/scripts/$s", "SGV-caller/scripts/$s.0");
            system("wget -O SGV-caller/scripts/$s https://biokirr.com/tools/patches/sgv-caller/$s");
        }
    }
}



# Downloading test data.
if (!-e 'test-data')
{
    system('wget https://biokirr.com/Supporting-Data/SGV-Caller-Test-Data/test-data.zip');
    system('unzip test-data.zip');
}



# Creating benchmark scripts.
foreach my $p (3 .. 8)
{
    foreach my $s (1000, 10000, 100000)
    {
        my $dir = "benchmark/p$p-$s";
        make_path($dir);

        open(my $S, '>', "$dir/sgv-caller.sh") or die;
        binmode $S;
        print $S "#!/usr/bin/env bash\n";
        print $S 'cd "$(dirname "$0")"', "\n";
        print $S "../../SGV-caller/sgv-caller.pl -i ../../test-data/p$p-$s.conf >sgv-caller-log.txt 2>sgv-caller-err.txt\n";
        close $S;
        system("chmod a+x $dir/sgv-caller.sh");

        open(my $T, '>', "$dir/benchmark.sh") or die;
        binmode $T;
        print $T "#!/usr/bin/env bash\n";
        print $T 'cd "$(dirname "$0")"', "\n";
        print $T '/usr/bin/time -v ./sgv-caller.sh >time-output.txt 2>&1', "\n";
        close $T;
        system("chmod a+x $dir/benchmark.sh");
    }
}



# Generating metadata.
foreach my $s (1000, 10000, 100000)
{
    my $out = "test-data/NCBI_SARS_CoV_2.s$s.metadata.tsv.gz";
    if (-e $out) { next; }
    system( "xz -dc test-data/NCBI_SARS_CoV_2.s$s.fas.xz"
            . " | grep '>'"
            . " | sed 's/^.//'"
            . " | perl -pe 's/^(.*)\$/\$1\\tncov\\t\$1/'"
            . " | gzip -c9"
            . " >$out" );
}



# Making id lists for pipelines 5 and 6, to extract 10% of entire datasets.
foreach my $p (5 .. 6)
{
    foreach my $s (1000, 10000, 100000)
    {
        if (-e "benchmark/p$p-$s/time-output.txt") { next; }
        my $n = $s / 10;
        system( "xz -dc test-data/NCBI_SARS_CoV_2.s$s.fas.xz"
                . " | grep '>'"
                . " | sed 's/^.//'"
                . " | shuf -n $n"
                . " >benchmark/p$p-$s/id-list.txt" );
    }
}



# Making id lists for pipeline 7.
foreach my $s (1000, 10000, 100000)
{
    if (-e "benchmark/p7-$s/time-output.txt") { next; }
    system( "xz -dc test-data/NCBI_SARS_CoV_2.s$s.fas.xz"
            . " | grep '>'"
            . " | sed 's/^.//'"
            . " >benchmark/p7-$s/id-list.txt" );
}



# Running the benchmark.
foreach my $p (3 .. 8)
{
    foreach my $s (1000, 10000, 100000)
    {
        my $out = "benchmark/p$p-$s/time-output.txt";
        if (-e $out) { next; }
        print "p$p-$s\n";
        system("benchmark/p$p-$s/benchmark.sh");
    }
}



# Summarizing the results.
open(my $OUT, '>', $result_table_file) or die "Can't create \"$result_table_file\"\n";
binmode $OUT;
print $OUT "Pipeline\t1,000\t10,000\t100,000\n";
foreach my $p (3 .. 8)
{
    print $OUT $p;
    foreach my $s (1000, 10000, 100000)
    {
        my ($time, $mem) = ('?', '?');
        my $t = "benchmark/p$p-$s/time-output.txt";
        if (-e $t and -s $t)
        {
            open(my $T, '<', $t) or die "Can't open \"$t\"\n";
            binmode $T;
            while (<$T>)
            {
                chomp;
                if (/^\s*Elapsed \(wall clock\) time \(h:mm:ss or m:ss\): (\S+)$/)
                { 
                    my $timestr = $1;
                    my ($h, $m, $s) = (0, 0, 0);
                    if ($timestr =~ /^(\d+):(\d+):(\d+(\.\d+|))/) { ($h, $m, $s) = ($1, $2, $3); }
                    elsif ($timestr =~ /^(\d+):(\d+(\.\d+|))/) { ($m, $s) = ($1, $2); }
                    else { die "Can't parse time: \"$timestr\"\n"; }
                    $time = sprintf("$h:%02d:%02d", $m, $s);
                }
                if (/^\s*Maximum resident set size \(kbytes\): (\d+)$/) { $mem = sprintf('%.1f', $1 / 1000); }
            }
            close $T;
        }
        print $OUT "\t$time ($mem)";
    }
    print $OUT "\n";
}
close $OUT;
