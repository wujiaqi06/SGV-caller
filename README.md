# SGV-caller
SGV-caller: SARS-CoV-2 genome variation caller

## 1. Dependency

Please install MAFFT (MAFFT: PMID: 12136088) beforehand. If your MAFFT software was not installed into system, please set path for it first by:
export PATH=$PATH:/path/to/the/folder/where/MAFFT/installed
The installation of the latest version of MAFFT is recommended. Please see more detail at: https://mafft.cbrc.jp/alignment/software/.
The softwares in this pipeline is using the Perl language. Please make sure you have Perl installed on your computer.
Installment
Please download the software from https://github.com/wujiaqi06/SGV-caller. 
You can also get it by running:
git clone https://github.com/wujiaqi06/SGV-caller.git

## 2. What can it do

The function of this pipeline is to extract the nucleotide, amino acid and codon level variations of SARS-CoV-2 genomes. It is easy to use and the data structure is also very simple, and anyone using this pipeline can have your own local database of SARS-CoV-2 genomes.

### 2.1 GISAID Genomic epidemiology Data

Please download genomic data and metadata from the GISAID database from "Genomic epidemiology". The downloaded file can be directly read by the software without unzipping them. The easiest way to run the software is to do:

perl pipeline_GISAID_from_fasta_metadata.pl -i input_fasta_sequence.gz -j input_metadata.gz -o output_file_name

input_fasta_sequence.gz: zipped input fasta sequence file, with gz extension. If your files are unzipped, please run:
gzip fasta_sequence

input_metadata.gz: zipped input metadata file, with gz extension. If your files are unzipped, please run:
gzip input_metadata

output_file_name: character, underbar or number without any space.

### 2.2 Custom data

You can also run the pipeline using custom data. It could be the data downloaded from NCBI, or obtained by your own experiments. In this case, you need two steps to run the pipeline. 
Step 1, obtain the name2ID file.
name2ID file is an index file, which has two columns separated by tab. The first line is sequence names; while the second line is the name you hope to change to. Example of name2ID file can be seen in the later section. In case of GISAID analysis, it is useful to change sequence names to GISAID ID numbers, thus the first column is GISAID sequence name, the second column is GISAID ID numbers. If you do not need to change the sequence name, just give both of the columns of the sequence name. In this case, you can run:
perl name2ID_for_fasta.pl  -i input_fasta_file_zipped -o output_file

You can also generate a name2ID file by yourself.

Step 2, run the pipeline
perl pipeline_GISAID_from_name2ID.pl -i input_fasta_sequence.gz -j input_name2id -o output_file_name

## 3. main outputs

The 3 major directories:
output_aa: variations at the amino acid level of each gene and genomes
output_codon: variations at the codon level of each gene and genomes
output_rna: variations in non-coding regions and genomes

Note that a "Z" letter in amino acid sequence comparison represents frame shifts.

Other 4 directories:
output_genomic_variation
output_genomic_variation_ID_unique
output_genomic_variation_long_table
output_genomic_variation_var_for_each_ID
For each directory, 3 files will be generated: aa.txt, snp.txt, codon.txt.
They summarized haplotypes of all sequences at the amino acid level (aa.txt), the nucleotide level (snp.txt) and the codon level (codon.txt), with different data formats. “0change” means the genome is identical to the reference genome; while “0change_after_screen” means after quality control, the genome is identical to the reference genome.

output_genomic_variation：variations are summarized by haplotypes (summarized variations). The second column is the number of sequences carrying the haplotypes. The third column is the lists of sequences, which are separated by "|".

output_genomic_variation_ID_unique has the same format with test_genomic_variation, however, removing the repeated ids, thus its statistics is more correct.
output_genomic_variation_long_table: pairwise of sequence id and variations. This is the format that is easy to read by R software. 
output_genomic_variation_var_for_each_ID: haplotypes for each sequence.

The other output files:
output.raw_variants.for_each.all.txt: the raw variations for each sequence. It is not screened. By the information saved in this file, you can extract pairwise alignment of gisaid sequences to reference the genome (usually Wuhan-hu-1).
output.screen.snp.txt is screened variations for each sequence.
output.raw_variants.for_each.all.txt is summarized information for each snp. The information includes snp location, annotation of gene location, amino acid/codon/nucleotide level reference/alternative mutations, etc. Is easy to be used to search the cross-information of each snps.
output.count_aa.txt is counting of number of each variation at amino acid level
output.count_codon.txt: is counting of number of each variation at codon level
output.count_RNA.txt is counting the number of each variation at non-coding regions.
output.deletion.txt is deletions in each genomes.
output.insertion.txt is insertions in each genome.

The supporting file:
output_name2ID.txt shows a pair of sequence names and GISAID ID for each sequence.

<Notice> another pipeline "pipeline_GISAID_Adding_new_data.pl", which adds the new sequences to an already existing database, needs output.raw_variants.for_each.all.txt and "output_name2ID.txt" file as input files. Please keep these two files carefully every time.
Details of each softwares in the pipeline

## 4. The function of each software
 
### 4.1 The function of each software in this pipeline are as follows:
#### Step 1. name2ID.pl

Function: 
generating a list of sequence names and GISAID ID from metadata.

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
 
The first line is sequence name, and the second line is GISAID ID, which are separated by tab.
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

#### Step 2. alignment2varients_no_screen_linux.pl

Function: 
Extracts all variations of each sequence based on the one-to-one pairwise alignment between target and reference sequences.

use:
perl alignment2varients_no_screen_linux.pl -i input_fasta -j name2id -r reference -o output_file

input_fasta: gzipped fasta file.
name2id: name2id file, as output in the Step1.
reference: reference genome, usually "NC_045512.2.fas"

The output file is saved in "output_file.variations.info.sum.txt".

#### Step 3. alignment2varients_extract_genes.pl
Function:
This perl software is similar to alignment2varients_no_screen_linux.pl, but it also reads gene annotation file (e.g. "gene_anno"), and extract genes of each sequences in input_fasta based on the genetic regions as mentioned in gene_anno file.
The output sequence files are in fasta format, and are saved in {output_file}_gene folder
use:
perl alignment2varients_extract_genes.pl -i input_fasta -r reference -a gene_anno -o output_file

The example of "gene_anno" file (wuhan-hu-1):
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

#### Step 4. screen_summzrize_data_del_int.pl

function:
Screens the raw variation file, and generates a summarized haplotype file, which can be used as an input file for MapProtein_SARS2_aa_RNA_nsp_indel.pl.

use: 
perl screen_summzrize_data_del_int.pl -i input_variants_file -o output_file
Filters output_file.variations.info.sum.txt file by removing ID without date information, and output screened variations in "output_file.screen.ID.sum.txt" file.

#### Step 5. MapProtein_SARS2_aa_RNA_nsp_indel.pl
use:
perl MapProtein_SARS2_aa_RNA_nsp_indel.pl -i input_vari_info_file -o output_folder

Note that the gene annotation and nucleotide sequences stored in the "NC_045512.cds.Exc1ab.overlapAdded.fas" file are used as the default. 
The format of this file is "gene|start_location..end_location", for example:

///NC_045512.cds.Exc1ab.overlapAdded.fas
>S|21563..25384
ATGTTTGTTTTTCTTG...
>ORF3a|25393..26220
ATGGATTTGTTTATGAGAATC...
///

The format of the input_vari_info_file for MapProtein_SARS2_aa_RNA_nsp_indel.pl should be:

haplotypes	number_of_sequence_carry_such_haplotypes	sequence_id1|sequence_id2|sequence_id3

You can change the content of "NC_045512.cds.Exc1ab.overlapAdded.fas" by adding or removing genes. Pay attention that the sequence location, and the sequence of genes should exactly march its annotation.

#### Step 6. variation_unique_ID_sum.pl
use: perl variation_unique_ID_sum.pl -i input_vari_info_folder

This perl software calculates variations stored in the input directory and generates 3 output files in “input_vari_info_folder”.

ID_unique shows that duplicated IDs are removed in the input folder.
var_for_each_ID summarizes haplotypes for each sequence.
long_table is very friendly to be used by R programming.

## 5. Other pipelines

#### Pipeline 1. pipeline_GISAID_from_name2ID.pl
use:
perl pipeline_GISAID_from_name2ID.pl -i input_fasta_sequence -j input_name2id -o output_file_name

This pipeline works when you have already prepared a name2ID file, and it starts from a name2ID file.
This pipeline would be useful if you want to handle your own sequence, or you want to analyze sequences from GenBank.

#### Pipeline 2. pipeline_GISAID_Adding_new_data.pl
use:
perl use: pipeline_GISAID_Adding_new_data.pl -i input_fasta_equence -j input_metadata -s input_old_name2ID -t input_old_raw_variants -o output_file_name

This pipeline analyzes the sequences that are newly added into the database using previously analyzed results as input files: raw variants file with "-t" and name2ID file with "-s". It also reads a new fasta file with "-i" and a new metadata file with "-j". 

This is recommended for updating the variations called from the GISAID database.

#### Pipeline 3. pipeline_sars2_variations_from_raw_variances.pl
use: 
perl pipeline_sars2_variations_from_raw_variances.pl -i input_raw_variants_file

This pipeline starts from the raw_variants file. 

#### Pipeline 4. pipeline_GISAID_from_Fasta.pl
use: 
perl pipeline_GISAID_from_Fasta.pl -i input_fasta_sequence -o output_file_name

This pipeline takes zipped fasta files as input files.
It is suitable in the case you do not hope to change the sequence names in fasta files. 

#### Pipeline 5. pipeline_select_sequence.pl
use: 
perl pipeline_select_sequence.pl -i input_fasta_gz -j input_name2ID -s selected_id -o output_fasta

This pipeline reads a list of gisaid_id (selected_id), as well as the whole fasta file and "input_name2ID" file of the GISAID database. 
It outputs the sequences that are listed in selected_id file. Alignment by MAFFT will be automatically conducted as well.

selected_id file only contains gisaid ids. It is not necessary, but it is better to be a subset of input_name2ID file. If it contains sequences that input_name2ID file does not have, the sequences cannot be extracted, and will be passed.

example of selected_id file, GISAID id only is enough
///
EPI_ISL_2626633
EPI_ISL_1610990
...
///
#### 6. Examples
1, run the pipeline from fasta file (zipped) and metadata file (zipped) using GISAID Genomic epidemiology Data.
perl pipeline_GISAID_from_fasta_metadata.pl -i gisaid_input_fasta.fas.gz -j gisaid_metadata.tsv.gz -o output

2, run the pipeline from raw variation file
perl pipeline_sars2_variations_from_raw_variances.pl -i input.raw_variants.for_each.all.txt

3, run the pipeline from fasta file and name2id file, which is suitable for handling NCBI data or your own data.
perl pipeline_GISAID_from_name2ID.pl -i example_input_fasta.fas.gz -j name2ID.txt -o output

4, extract genes that you are interested in, such as S proteins.
perl alignment2varients_extract_genes.pl -i example_input_fasta.fas.gz -r NC_045512.fas -a anno.txt -o output
//output is in output_gene folder

5, give a list of gisaid ids, and extract its sequences (in fasta format) and conducte alignment
perl pipeline_select_sequence.pl -i example_input_fasta.fas.gz -j name2ID.txt -s selected_id.txt -o selected
//output is selected.fas selected.align.fas
