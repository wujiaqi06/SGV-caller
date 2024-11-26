#!/usr/bin/env perl
#
# Benchmark script for the SGV-caller pipeline
# Version 1.0.2
# by Kirill Kryukov
# in public domain under the CC0 license.
#

use strict;
use Cwd;
use File::Path qw(make_path);

# Options.
my $clean_up = 0;
my $result_table_file = "benchmark-result-table.tsv";
my $use_sgv_caller_from_github = 1;
my $use_test_data_from_github = 1;

my @sizes = (1000, 10000, 100000);
#my @sizes = (1000);

my @pipelines = (3, 4, 5, 6, 7, 8);
#my @pipelines = (3);



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
    system("rm -rf SGV-caller test-data benchmark $result_table_file");
}



# Downloading SGV-caller pipeline.
if (!-e 'SGV-caller')
{
    if ($use_sgv_caller_from_github)
    {
        system('git clone https://github.com/wujiaqi06/SGV-caller');
        system('chmod a+x SGV-caller/sgv-caller.pl');
    }
    else
    {
        make_path('SGV-caller');
        my $dir = getcwd();
        chdir 'SGV-caller';
        system('wget https://biokirr.com/Supporting-Data/SGV-Caller-Test-Data/sgv-caller_v1.8.zip');
        system('unzip sgv-caller_v1.8.zip');
        system('chmod a+x sgv-caller_v1.8/sgv-caller.pl');
        chdir $dir;
    }
}

my $sgv_caller_script_path = $use_sgv_caller_from_github
                             ? '../../SGV-caller/sgv-caller.pl'
                             : '../../SGV-caller/sgv-caller_v1.8/sgv-caller.pl';



# Downloading test data.
if (!-e 'test-data')
{
    if ($use_test_data_from_github)
    {
        system('wget https://github.com/wujiaqi06/SGV-caller/raw/refs/heads/main/examples/benchmark/test-data.zip');
        system('unzip test-data.zip');
    }
    else
    {
        system('wget https://biokirr.com/Supporting-Data/SGV-Caller-Test-Data/test-data.zip');
        system('unzip test-data.zip');
    }
}



# Creating benchmark scripts.
foreach my $p (@pipelines)
{
    foreach my $s (@sizes)
    {
        my $dir = "benchmark/p$p-$s";
        make_path($dir);

        open(my $S, '>', "$dir/sgv-caller.sh") or die;
        binmode $S;
        print $S "#!/usr/bin/env bash\n";
        print $S 'cd "$(dirname "$0")"', "\n";
        print $S "$sgv_caller_script_path >sgv-caller-log.txt 2>sgv-caller-err.txt\n";
        # -i sgv-caller.conf
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



# Copying and patching configuration files.
foreach my $p (@pipelines)
{
    foreach my $s (@sizes)
    {
        #my $src = "SGV-caller/benchmark/testing_data/p$p-$s.conf";
        my $src = "test-data/p$p-$s.conf";
        my $dst = "benchmark/p$p-$s/sgv-caller.conf";
        open(my $SRC, '<', $src) or die "Can't open \"$src\"\n";
        open(my $DST, '>', $dst) or die "Can't create \"$dst\"\n";
        binmode $SRC;
        binmode $DST;
        while (<$SRC>)
        {
            #s/\.\.\/\.\.\/test-data\//..\/..\/SGV-caller\/benchmark\/testing_data\//;
            print $DST $_;
        }
        close $SRC;
        close $DST;
    }
}



# Generating metadata.
foreach my $s (@sizes)
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
foreach my $p (grep { $_ >= 5 and $_ <= 6 } @pipelines)
{
    foreach my $s (@sizes)
    {
        my $out = "benchmark/p$p-$s/id-list.txt";
        if (-e $out) { next; }
        my $n = $s / 10;
        system( "xz -dc test-data/NCBI_SARS_CoV_2.s$s.fas.xz"
                . " | grep '>'"
                . " | sed 's/^.//'"
                . " | shuf -n $n"
                . " >$out" );
    }
}



# Making id lists for pipeline 7.
foreach my $p (grep { $_ == 7 } @pipelines)
{
    foreach my $s (@sizes)
    {
        my $out = "benchmark/p$p-$s/id-list.txt";
        if (-e $out) { next; }
        system( "xz -dc test-data/NCBI_SARS_CoV_2.s$s.fas.xz"
                . " | grep '>'"
                . " | sed 's/^.//'"
                . " >$out" );
    }
}



# Running the benchmark.
foreach my $p (@pipelines)
{
    foreach my $s (@sizes)
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
print $OUT "Pipeline\t", join("\t", @sizes), "\n";
foreach my $p (@pipelines)
{
    print $OUT $p;
    foreach my $s (@sizes)
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
                    $s = sprintf('%.0f', $s);
                    $m = sprintf('%.0f', $m);
                    if ($s == 60) { $m++; $s = 0; }
                    if ($m == 60) { $h++; $m = 0; }
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
