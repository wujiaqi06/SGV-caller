# Manual for SGV-caller, SARS-CoV-2 genome variation caller
Jiaqi Wu and So Nakagawa

## 1. Overview
SGV-caller is software that can generate the local database on the genomic variations of SARS-CoV-2 genomes at amino acid, codon, and nucleotide levels. The SGV-caller was designed to handle SARS-CoV-2 genomes and metadata files in the [GISAID database](https://www.gisaid.org/). In particular, the update of the GISAID database can be easily tracked. The output files generated by the SGV-Caller are tab-delimited text formats that are easy to read, manage and use. A data quality check is performed on each genome and summary statistics are reported. The data will be stored in a variety of formats that can be easily accessed by R software, bash commands and other programming languages. Based on the outputs, it will be easy to manage the variant information of SARS-CoV-2 genomes and extract the data that meet the user's requirements.

## 2. Dependency
  The SGV-Caller software consists of scripts written in the Perl language. Please ensure that you have Perl installed on your computer. In addition, the software requires the multiple alignment software [MAFFT](https://mafft.cbrc.jp/) (1). It is recommended that you install the latest version of MAFFT.
  For Ubuntu users, the easiest way to install MAFFT is as follows:
```
sudo apt-get -y install mafft
```
If you use Mac, you can use [brew](https://brew.sh/) to install it as follows:
```
brew install mafft
```
If you want to install using the source code of the MAFFT suite, you can install it by following the guidance of [MAFFT](https://mafft.cbrc.jp/). If this is the case, please set the path to the binary file of MAFFT programs by:
```
export PATH=$PATH:/path/to/the/directory/where/MAFFT/installed
```

SGV-Caller also requires xz to be installed in the system. In Linux systems, xz is installed by default. If you are using Mac OS, please install it:
```
brew install xz
```
## 3. Instalment 
  Please download the SGV-caller from https://github.com/wujiaqi06/SGV-caller. You can also get it by running: 
```
git clone https://github.com/wujiaqi06/SGV-caller.git
```
  The SGV-caller is Perl software, which does not need compilation. First, you have to set the path to the directory of the SGV-caller as follows:
```
chmod 777 /path/to/the/directory/where/sgv-caller/installed/sgv-caller.pl
```
  To use the SGV-caller, you have to copy the SGV-caller’s configuration file “sgv-caller.conf” into the directory containing the data to be analyzed. Then, set the suitables variables in “sgv-caller.conf”.

## 4. What can it do
  The main purpose of SGV-caller is to generate the local database of genomic variations of SARS-CoV-2 using data downloaded from [GISAID database](https://www.gisaid.org/). Variations at the nucleotide, amino acid and codon level will be reported. It can be used to user-defined virus genome as well.

## 5. How to run it
  Firstly, please set path to the folder of SGV-caller and configure local environment by: 
```
export PATH=$PATH:/path/to/the/directory/where/sgv-caller/installed
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
```
  Then, copy configuration file “sgv-caller.conf” to the directory where you hope to generate the database, then modify the values of “sgv-caller.conf” file to control software which calculation you want to conduct and their input files, then run this in command line:
```
cd where/sgv-caller.conf/is/stored
sgv-caller.pl
```
  By default, SGV-caller will search for the configuration file “sgv-caller.conf” in the database directory. If your configuration file has a different name, please run this command instead, then you can use your own configuration file:
```
sgv-caller.pl -i your_own_configuration_file
```
## 6. Configuration file
  Every time when you run SGV-caller, software firstly reads the configuration file “sgv-caller.conf” for the necessary information it needs. calculation 1-8 in “sgv-caller.conf” corresponding to the pipelines 1-8, which have different functions as follows:
```
Pipeline 1. Making a SGV database start from FASTA sequence and metadata downloaded from GISAID. 
Pipeline 2. Updating existing database with newly downloaded data from GISAID. 
Pipeline 3. Making an SGV database with a given FASTA file, using sequence names as sequence ID.
Pipeline 4. Making an SGV database with the “raw_variants.for_each.all.txt” file.
Pipeline 5. Extracting a subset of the SGV database based on the selected ID.
Pipeline 6. Extracting a FASTA sequences based on a given a GISAID ID list file.
Pipeline 7. Extracting genes from a list of GISAID genomes based on a given GISAID ID list file.
Pipeline 8. Extracting the amino acid replacement information from protein sequences.
```
### 6.1 output_file_name
output_file_name is the run name, which is necessary for pipelines 1-8. It should be a string with only characters, numbers and underbar. Any types of space are not allowed.

### 6.2 reference genome related options
Pipelines 1-5 needs reference genome, as well as its annotation information to annotate the nucleotide variations to codon and amino acid level. By default, SGV-caller takes Wuhan-hu-1 (RefSeq: NC_045512.2) as reference genome. use_default_reference is asking whether you will use the default reference genome or not. It takes the value of “yes” or “no”. If use_default_reference = yes, the default reference genome Wuhan-hu-1 will be used. If use_default_reference = no, the following three files are necessary to run SGV-caller: 
```
custom_reference_genome
custom_codon_fasta_annotation_file
custom_rna_annotation
```
custom_reference_genome is the directory and file name of the custom reference genome file. This file should contain a single sequence, and its sequence name had better not overlap with the sequence name in the fasta data file.
custom_codon_fasta_annotation_file is the directory and file name of the custom codon annotation file. Its format is:
```
S	21563..25384
ORF3a	25393..26220
E	26245..26472
M	26523..27191
nsp10	13025..13441
nsp11	13442..13480
nsp12	13442..13468,13468..16236
…
```
	Comma can be used to separate different genetic regions.
custom_rna_annotation is the directory and file name of the custom RNA annotation file. Its format is:
```
5UTR	1..265
3UTR	29675..29903
Non_Coding_ORF1ab_S	21556..21562
Non_Coding_S_ORF3a	25385..25392
…
```
### 6.3 Specification of different pipelines
  The calculation value in the “sgv-caller.conf” takes values from 1 to 8, corresponding to different pipelines. In example folder, you can find examples and testing data of “sgv-caller.conf” for pipelines 1-8.

#### Pipeline 1. Making a SGV database start from FASTA sequence and metadata downloaded from GISAID. 
```
calculation = 1
input_GISAID_fasta_genome_file = input_fasta_data_file
input_GISAID_metadata_file = input_metadata_file
```
  Calculation 1 calculates the local database from the GISAID FASTA sequence data file and metadata file, which are specified by “input_GISAID_fasta_genome_file” and “input_GISAID_metadata_file”. Either data downloaded from “Genomic epidemiology" or "Download packages" can be used directly without unzipping. The GISAID ID, rather than sequence name will be used as sequence identifier in this calculation.

#### Pipeline 2. Updating existing database with newly downloaded data from GISAID.
```
calculation = 2
directory_of_previous_database = directory_of_existing_SGV_database
output_file_name_of_previous_database = output_file_name_of_previous_run
input_new_GISAID_fasta_genome =	input_fasta_data_file
input_new_GISAID_metadata = input_metadata_file
```
  Calculation 2 is used to update an already existing database. It takes 4 input values, as shown above.  It needs the directory_of_existing_SGV_database and its output_file_name. The GISAID ID, rather than sequence name will be used as sequence identifier in this calculation.

#### Pipeline 3. Making an SGV database with a given FASTA file, using sequence names as sequence ID.
```
calculation = 3
input_fasta_file = multiple_fasta_file
```
  Calculation 3 is NOT for data downloaded from GISAID database, but for the case for general FASTA-format sequence data, such as the data downloaded from other databases such as GenBank. The sequence names in multiple_fasta_file will be directly used as sequence identifiers. The sequence name should be a string with only number, character and underbar. Space in sequence names is not allowed.

#### Pipeline 4. Making an SGV database with the “raw_variants.for_each.all.txt” file.
```
calculation = 4
input_raw_variation_file = input.raw_variants.for_each.all.txt
```
  Calculation 4 calculates SGV database from “input.raw_variants.for_each.all.txt” file, that is obtained by other runs.

#### Pipeline 5. Extracting a subset of the SGV database based on the selected ID.
```
calculation = 5
GISAID_ID_list_file = gisaid_id_list_file
input_GISAID_fasta_genome_file2 = input_fasta_data_file
input_GISAID_metadata_file2 = input_metadata_file
```
  Calculation 5 reads a “gisaid_id_list_file”, and generates a database of the GISAID IDs that is included in the “gisaid_id_list_file” only. It also needs “input_GISAID_fasta_genome_file2” and “input_GISAID_metadata_file2”. 

#### Pipeline 6. Extracting a FASTA sequences based on a given a GISAID ID list file.
```
calculation = 6
GISAID_ID_list_file = gisaid_id_list_file
input_GISAID_fasta_genome_file2 = input_fasta_data_file
input_GISAID_metadata_file2 = input_metadata_file
```
  Calculation 6 extract sequences listed in gisaid_id_list_file, and it will NOT generate the SGV database. 

#### Pipeline 7. Extracting genes from a list of GISAID genomes based on a given GISAID ID list file.
```
calculation = 7
GISAID_ID_list_file = gisaid_id_list_file
input_GISAID_fasta_genome_file2 =  input_fasta_data_file
input_GISAID_metadata_file2 = input_metadata_file
gene_annotation = default
#default or the custom gene annotation file name
```
  Calculation 7 reads a sequence list file gisaid_id_list_file and a gene annotation file gene_annotation. If you give “default” to gene_annotation, the gene annotation file in the reference folder (“NC_045512.anno.txt”) in the software will be used. If you hope to extract the genetic regions that are defined by yourself, please give the directory and file name to gene_annotation_file.

#### Pipeline 8. Extracting the amino acid replacement information from protein sequences.
```
calculation = 8
protein_sequence_file = S.pep.fas.gz
protein_reference_sequence_file = NC_045512.2.S.fas	
```
  Calculation = 8 reads a protein sequence file as input file (e.g. S.pep.fas.gz), a protein reference sequence file (e.g. NC_045512.2.S.fas), and extracts the amino acid replacement information directly. 

## 7.1 Output files
  Output_file_name.raw_variants.for_each.all.txt: the raw variations at nucleotide level for each genome.
  Output_file_name.variations.info.sum.txt: the information for each variation, including snp locations, reference snps, alternative snps, reference codons, alternative codons, reference amino acids, alternative amino acids, etc. 	
  Output_file_name.raw_variants.static.txt: quality of each genome, including number of differences to the reference genome, number of undetermined nucleotides of the whole genome and number of undetermined nucleotides of Spike protein, respectively.
  Output_file_name.s.static.txt: quality of Spike protein region only.
  Output_file_name.deletion.txt and Output_file_name.insertion.txt: the information of deletions and insertions of the genomes analysed.
  Output_file_name.count_aa.txt, Output_file_name.count_codon.txt, Output_file_name.count_snp.txt: the counting of each variations at amino acid, codon and nucleotide level.
  Output_file_name.options.txt: the command options that are actually run during the calculation.

## 7.2 Output folders
Main output folders:
```
  Output_file_name_genomic_variation
  Output_file_name_genomic_variation_ID_unique
  Output_file_name_genomic_variation_long_table
  Output_file_name_genomic_variation_var_for_each_ID
``` 
  All of these folders Contains 3 files, aa.txt, codon.txt, snp.txt. They are the summarized genetic variations at amino acid, codon and nucleotide level, with slightly different data format. 
##### “Output_file_name_genomic_variation” 
summarized genetic variations by haplotypes. aa.txt in Output_file_name_genomic_variation folder:
```
nsp2#I120F|nsp12#P323L|S#S477N|S#D614G|N#RG203KR|ORF9c#GE50NE	1	MW155300.1
nsp2#I120F|nsp12#P323L|nsp12#K718N|S#S477N|S#D614G|N#RG203KR|ORF9c#GE50NE	1	MW154115.1
nsp2#I120F|nsp12#P323L|S#S477N|S#D614G|ORF3c#K17R|N#RG203KR|ORF9c#GE50NE	1	MT972245.1
```
##### “Output_file_name_genomic_variation_ID_unique” 
summarizes genetic variations by variations. aa.txt in Output_file_name_genomic_variation_ID_unique folder:
```
M#L102LZ	1	OU811303.1
N#A211V	1	OD900734.1
N#A220V	7	OU794820.1|OB997169.1|OD944225.1|OD952064.1|OB987694.1|OU030367.1|OU800131.1
N#D288N	1	ON577819.1
N#D343G	1	OW518434.1
```
##### “Output_file_name_genomic_variation_long_table” 
contains only two columns, which are the variations and genomic IDs pairs. This format is suitable for analyzing by R software or bash commands.
Example: aa.txt in Output_file_name_genomic_variation_long_table folder:
```
E#T9I	OW513133.1
E#T9I	ON556126.1
E#T9I	OW464169.1
E#T9I	OW506517.1
E#V5F	MT994988.1
```
##### “Output_file_name_genomic_variation_var_for_each_ID” 
is the genomic variations for each genome. Example: aa.txt in Output_file_name_genomic_variation_var_for_each_ID folder folder:
```
FR998558.1	nsp12#P323L|S#D614G|S#Q677H|N#RG203KR|ORF9c#GE50NE
MT451742.1	nsp4#F308Y|ORF3a#G196V|ORF8#L84S|N#P13L|ORF9b#P10S|N#S197L|ORF9c#Q44*
MT810919.1	nsp12#P323L|S#D614G|S#T678I
MT972245.1	nsp2#I120F|nsp12#P323L|S#S477N|S#D614G|ORF3c#K17R|N#RG203KR|ORF9c#GE50NE
```
  Besides these four folders, SGV-caller also generates three folders, which summarise the genomic variations for each annotated gene or RNA regions, which are summarised in Output_file_name_aa, Output_file_name_codon and Output_file_name_rna folder.

## Examples
Example data for each pipeline are prepared in "examples" folder. A example "sgv-caller.conf" is prepared as well, which the input data are already set for each pipelines.
If you hope to try pipeline1, please copy "sgv-caller.conf" into "pipeline1" folder, then change:
```
output_file_name = your_output_run_name
calculation = 1
```
Then you can run pipeline1 by the method described above.

If you hope to run pipeline2, please firstly run example in pipeline1. Then modify
```
directory_of_previous_database = ../pipeline1
output_file_name_of_previous_database =	your_output_run_name_for_pipeline1
```
Then you can run pipeline2 by the method described above.

For other pipelies, only changing
```
output_file_name = your_output_run_name
calculation = number_1_to_8
```
You can run it normally.

Any lines in "sgv-caller.conf" start with "#" will be regarded as annotation lines, and will be ignored by software.
