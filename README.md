# SGV-caller
SGV-caller: SARS-CoV-2 genome variation caller

[Part 1: Introduction]
This is a package to extract the variations from SARS-CoV-2 genomes mainly from the GISAID database. 
You can also use it to extract variations from other databases, such like GenBank. Please notice that currently this pipeline is specifically for SARS-CoV-2, and using Wuhan-hu-1 (GenBank accession number NC_045512.2) as reference genome. If you hope to apply it to other organisms, please connect to the author (Jiaqi Wu in Tokai University School of Medicine, wujiaqi06@gmail.com)
It contains several pipelines for different input data. You can also run each software independently for different purposes.

[Part 2: Preparation]
Please install MAFFT beforehand. If your MAFFT software was not installed into system, please set path for it first by:
export PATH=$PATH:/path/to/the/folder/where/MAFFT/installed
#current linux server, please run:
export PATH=$PATH:/mnt/4sbay/bin/mafft/7.481/bin/
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
##

The installing of the latest version of MAFFT is recommended.
Please see more detail at: https://mafft.cbrc.jp/alignment/software/

[Part 3: An easy start with GISAID data with 2 steps]
Step 1, downloading data from GISAID database ("Genomic epidemiology" only):
FASTA and metadata.

<PAY ATTENTION 01>: Please download data from "Genomic epidemiology" in the GISAID database. Current "name2ID.pl" can handle the data format of "Genomic epidemiology".

<PAY ATTENTION 02>: You DO NOT need to unzip the downloaded file! Please use the sequences file and metadata file as you downloaded directly from the GISAID database.

Step 2, put FASTA and metadata into the same folder of this pipeline, and run:
perl pipeline_GISAID_from_fasta_metadata.pl -i input_fasta_sequence -j input_metadata -o output_file_name
input_fasta_sequence: zipped input fasta sequence file, with gz extension.
input_metadata: zipped input metadata file, with gz extension.
output_file_name: any string without space, recommended characters, number and underbar only.

example: 
perl pipeline_GISAID_from_fasta_metadata.pl -i example_input_fasta.fas.gz -j example_input_metadata.tsv.gz -o test

3 main output directories:
test_aa: variations at the amino acid level of each gene
test_codon: variations at the codon level of each gene
test_rna: variations in non-coding regions

Note that a "Z" letter in amino acid sequence comparison represents 

The other 4 directories:
test_genomic_variation
test_genomic_variation_ID_unique
test_genomic_variation_long_table
test_genomic_variation_var_for_each_ID
For each directory, 3 files will be generated: aa.txt, snp.txt, codon.txt.
They summarized haplotypes of all sequences at the amino acid level (aa.txt), the nucleotide level (snp.txt) and the codon level (codon.txt).

The information stored in the following 4 folders are the same, but their format differs among them:
test_genomic_variation：variations are summarized by haplotypes (summarized variations). the second colum is number of sequences carry the haplotypes. The third colum is the lists of sequences, which are separated by "|".
test_genomic_variation_ID_unique has the same format with test_genomic_variation, however, removed the repeated ids, thus its statistics is more correct.
test_genomic_variation_long_table: pairwise of sequence id and variations. This is the format that is easy to be read by R software. R package to summarize and visualize the variations are under developing.
test_genomic_variation_var_for_each_ID: haplotypes for each sequences.

The other output files:
test.raw_variants.for_each.all.txt is the raw variations for each sequences. It is not screened. By the informations saved in this file, you can extract pairwise alignment of gisaid sequences to reference genome (Wuhan-hu-1).
test.screen.snp.txt is screened variations for each sequences.
test.raw_variants.for_each.all.txt is summarized informations for each snp. The information includes snp location, annotation of gene location, amino acid/codon/nucleotide level reference/alternative mutations, etc. Is easy to be used to search the cross-information of each snps.
test.count_aa.txt is counting of number of each variation at amino acid level
test.count_codon.txt: is counting of number of each variation at codon level
test.count_RNA.txt is counting of number of each variation at non-conding regions.
test.deletion.txt is deletions in sequences.
test.insertion.txt is insertions in sequences.

The supporting file:
output_name2ID.txt shows a pair of sequence name and GISAID ID for each sequence.

<Notice> another pipeline "pipeline_GISAID_Adding_new_data.pl" needs output.raw_variants.for_each.all.txt and "output_name2ID.txt" file as input files. Please keep these two files carefully every time.

[Part 4: Detail explanations]:

The function of each software in this pipeline are as follows:
Step 1, name2ID.pl

Function: 
generating a list of sequence name and GISAID ID from metadata.

use:
perl name2ID.pl -i input_metadata_gzip -o output_file

This perl script extrat sequences names and GISAID ID information for each sequences from metadata obtained from the GISAID database.
The example output ("name2ID.txt" file in output folder) of it is:

///
Argentina/INEI096534/2020	EPI_ISL_2158693
Argentina/INEI100632/2021	EPI_ISL_2104813
Argentina/INEI102214/2021	EPI_ISL_2135148
Argentina/INEI102437/2021	EPI_ISL_2135258
Argentina/INEI102438/2021	EPI_ISL_2135260
...
///
 
The first line is sequence name, and the second line is GISAID ID, which are separate by tab.
You do not need to give ".txt" in the output file, it will be automatically added to the output file name.

If you want to use sequence data obtained GenBank or your own sequences, the following script is useful to obtaine a "name2ID.txt" file.

perl name2ID_for_fasta.pl -i input_fasta_gzip -o output_file

The output is as follows depending on the definition of sequences in the fasta file:
///
OU076650	OU076650
OU078219	OU078219
OU085641	OU085641
...
///

Step 2, alignment2varients_no_screen_linux.pl

Function: 
Extracts all variations of each sequence based on the one-to-one pairwise alignment between target and reference sequences.

use:
perl alignment2varients_no_screen_linux.pl -i input_fasta -j name2id -r reference -o output_file

input_fasta: gzipped fasta file.
name2id: name2id file, as output in the Step1.
reference: "NC_045512.2.fas"

The output file saved in "output_file.variations.info.sum.txt".

Step 3, alignment2varients_extract_genes.pl
Function:
This perl software is similar to alignment2varients_no_screen_linux.pl, but it also reads gene annotation file (e.g. "gene_anno"), and extract genes of each sequences in input_fasta based on the genetic regions as mentioned in gene_anno file.
The output sequence files are in fasta format, and are saved in {output_file}_gene folder
use:
perl alignment2varients_extract_genes.pl -i input_fasta -r reference -a gene_anno -o output_file

The "gene_anno" file:
///
ORF1ab_1	266	13468
ORF1ab_2	13468	21555
ORF1a	266	13483
S	21563	25384
ORF3a	25393	26220
E	26245	26472
M	26523	27191
ORF6	27202	27387
ORF7a	27394	27759
ORF7b	27756	27887
ORF8	27894	28259
N	28274	29533
ORF10	29558	29674
///

4, screen_summzrize_data_del_int.pl

function:
Screens the raw variation file, and generates a summarized haplotype file, which can be used as an input file for MapProtein_SARS2_aa_RNA_nsp_indel.pl.

use: 
perl screen_summzrize_data_del_int.pl -i input_variants_file -o output_file
Filters output_file.variations.info.sum.txt file by removing ID without date information, and output screened variations in "output_file.screen.ID.sum.txt" file.

Step 5, MapProtein_SARS2_aa_RNA_nsp_indel.pl
use:
perl MapProtein_SARS2_aa_RNA_nsp_indel.pl -i input_vari_info_file -o output_folder

Note that the gene annotation and nucleotide sequences stored in the "NC_045512.cds.Exc1ab.overlapAdded.fas" file used as the default. 
The format of this file is "gene|start_location..end_location", for example:

///NC_045512.cds.Exc1ab.overlapAdded.fas
>S|21563..25384
ATGTTTGTTTTTCTTG...
>ORF3a|25393..26220
ATGGATTTGTTTATGAGAATC...
///

<PAY ATTENTION 03> The format of the input file used for this perl script should be:

haplotypes	number_of_sequence_carry_such_haplotypes	sequence_id1|sequence_id2|sequence_id3

The input file is the output file of "screen_summzrize_data_del_int.pl" (e.g. "output_file.screen.snp.txt"), of which format is as follows:
///
nsp3#T428I|nsp3#P1469S|nsp3#F1569V|nsp4#L438P|nsp4#T492I|nsp6#L37F|nsp6#SGFK106K|nsp12#P323L|ORF2b#V15L|S#G75V|S#T76I|S#RSYLTPGD246N|S#L452Q|S#F490S|S#D614G|S#T859N|N#P13L|ORF9b#P10S|N#RG203KR|ORF9c#GE50NE|N#G214C|ORF9c#M60I|N#T366I	1	EPI_ISL_2543618
nsp3#T428I|nsp3#P1469S|nsp3#F1569V|nsp4#L438P|nsp4#T492I|nsp5#G15S|nsp6#SGFK106K|nsp12#P323L|ORF2b#V15L|S#G75V|S#T76I|S#RSYLTPGD246N|S#L452Q|S#F490S|S#D614G|S#T859N|N#P13L|ORF9b#P10S|N#RG203KR|ORF9c#GE50NE|N#G214C|ORF9c#M60I|ORF9c#T72I|N#T366I	EPI_ISL_2626633|EPI_ISL_2626634
nsp3#T428I|nsp3#P1469S|nsp3#F1569V|nsp4#L438P|nsp4#T492I|nsp5#G15S|nsp6#SGFK106K|nsp12#P323L|ORF2b#V15L|S#G75V|S#T76I|S#RSYLTPGD246N|S#L452Q|S#F490S|S#D614G|S#T859N|N#P13L|ORF9b#P10S|N#RG203KR|ORF9c#GE50NE|N#G214C|ORF9c#M60I|N#T366I	8	EPI_ISL_1610990|EPI_ISL_1807291|EPI_ISL_1807293|EPI_ISL_1856910|EPI_ISL_1856914|EPI_ISL_1969411|EPI_ISL_1969418|EPI_ISL_2018305
///

<PAY ATTENTION 04> You can change the content of "NC_045512.cds.Exc1ab.overlapAdded.fas" by adding or removing genes. BUT: The sequence location, and the sequence of gene should exactly march its annotation. It is highly recommend not to modify this file.

Step 6, variation_unique_ID_sum.pl
use: perl variation_unique_ID_sum.pl -i input_vari_info_folder

This perl software calculates variatons stored in the input directory and generates 3 output files in “input_vari_info_folder”.

ID_unique shows that duplicated IDs are removed in the input folder.
var_for_each_ID summarizes haplotypes for each sequence.
long_table is very friend to be used by R programming.

<PAY ATTENTION 05> files inside of “input_vari_info_folder”, should have exactly the same format with <PAY ATTENTION 03>, as input format.

[Part 6: different pipelines]:

1, pipeline_GISAID_from_name2ID.pl
use:
perl pipeline_GISAID_from_name2ID.pl -i input_fasta_sequence -j input_name2id -o output_file_name

This pipeline works when you already prepared name2ID file, and it starts from name2ID file.
This pipeline would be useful if you want to handle your own sequence, or you want to analysis sequences from GenBank.

2, pipeline_GISAID_Adding_new_data.pl
use:
perl use: pipeline_GISAID_Adding_new_data.pl -i input_fasta_equence -j input_metadata -s input_old_name2ID -t input_old_raw_variants -o output_file_name

This pipeline analyzed the sequences that is newly added into the database using previously analyzed results as input files: raw variants file with "-t" and name2ID file with "-s". It also reads new fasta file with "-i" and new metadata file with "-j". 

This is recommended for updating the variations called from GISAID database.

3, pipeline_sars2_variations_from_raw_variances.pl
use: 
perl pipeline_sars2_variations_from_raw_variances.pl -i input_raw_variants_file

This pipeline starts from raw_variants file. 

4, pipeline_GISAID_from_Fasta.pl
use: 
perl pipeline_GISAID_from_Fasta.pl -i input_fasta_sequence -o output_file_name

This pipeline takes zipped fasta file as input file.
It is suitable in the case you do not hope to change the sequence names in fasta files. 

5, pipeline_select_sequence.pl
use: 
perl pipeline_select_sequence.pl -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta

This pipeline reads a list of gisaid_id (selected_id), as well as the whole fasta file and "input_name2ID" file of GISAID database. 
It output the sequences that is listed in selected_id file. Alignment by MAFFT will be automatically conducted as well.

<PAY ATTENTION 06>　selected_id file only contain gisaid ids. It is not necessary, but had better to be a subset of input_name2ID file. 
If it contains sequences that input_name2ID file does not have, the sequences cannot be extracted, and will be passed.
Here, input_name2ID file should be name2ID file of whole database, thus is the one extracted from GISAID metadata.

example of selected_id file, GISAID id only is enough
///
EPI_ISL_2626633
EPI_ISL_1610990
...
///

[Part 7: examples]:
1, run the pipleline from fasta file (zipped) and metadata file (zipped)
perl pipeline_GISAID_from_fasta_metadata.pl -i example_input_fasta.fas.gz -j example_input_metadata.tsv.gz -o test

2, run the pipeline from raw variation file
perl pipeline_sars2_variations_from_raw_variances.pl -i test.raw_variants.for_each.all.txt

3, run the pipeline from fasta file and name2id file, which is suitable for handling NCBI data or your own data.
perl pipeline_GISAID_from_name2ID.pl -i example_input_fasta.fas.gz -j name2ID.txt -o test

4, extract genes that you are interested, such like S proteins.
perl alignment2varients_extract_genes.pl -i example_input_fasta.fas.gz -r NC_045512.fas -a anno.txt -o test
//output is in test_gene folder

5, give a list of gisaid ids, and extract its sequences (in fasta format) and conducte alignment
perl pipeline_select_sequence.pl -i example_input_fasta.fas.gz -j name2ID.txt -s selected_id.txt -o selected
//output is selected.fas selected.align.fas
