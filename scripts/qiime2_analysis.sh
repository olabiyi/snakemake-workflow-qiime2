bash
# Install qiime2 - https://docs.qiime2.org/2020.6/install/native/#install-qiime-2-within-a-conda-environment
wget https://data.qiime2.org/distro/core/qiime2-2020.6-py36-linux-conda.yml
conda env create -n qiime2-2020.6 --file qiime2-2020.6-py36-linux-conda.yml
# CLEANUP
rm qiime2-2020.6-py36-linux-conda.yml

# install picrust2 plug-in
conda install -c bioconda -c conda-forge picrust2 
https://github.com/gavinmdouglas/q2-picrust2/archive/2019.10_0.tar.gz
tar -xvzf 2019.10_0.tar.gz
cd q2-picrust2-2019.10_0/
pip install -e .


# get SILVA database for QIMME
cd /gpfs0/bioinfo/users/obayomi/databases/q2_database
# Get the pre-trained full-length SILVA 99% classifier
wget  https://data.qiime2.org/2020.6/common/silva-138-99-nb-classifier.qza
# Get the raw preformatted sequences
wget https://data.qiime2.org/2020.6/common/silva-138-99-seqs.qza
# Get the preformatted taxonomy
wget https://data.qiime2.org/2020.6/common/silva-138-99-tax.qza


# Get Unite database for QIIME
wget https://files.plutof.ut.ee/public/orig/98/AE/98AE96C6593FC9C52D1C46B96C2D9064291F4DBA625EF189FEC1CCAFCF4A1691.gz
tar -xvzf 98AE96C6593FC9C52D1C46B96C2D9064291F4DBA625EF189FEC1CCAFCF4A1691.gz
rm -rf 98AE96C6593FC9C52D1C46B96C2D9064291F4DBA625EF189FEC1CCAFCF4A1691.gz
# Setting up the already trimmed database
# Import sequences
qiime tools import \
	--type 'FeatureData[Sequence]' \
	--input-path sh_qiime_release_04.02.2020/sh_refs_qiime_ver8_dynamic_04.02.2020.fasta \
	--output-path unite-trimmed.qza
# Import Taxonomy	
qiime tools import \
	--type 'FeatureData[Taxonomy]'  \
	--input-format HeaderlessTSVTaxonomyFormat \
	--input-path sh_qiime_release_04.02.2020/sh_taxonomy_qiime_ver8_dynamic_04.02.2020.txt \
	--output-path unite-trimmed-taxonomy.qza
# Train the classifier
qiime feature-classifier fit-classifier-naive-bayes \
	--i-reference-reads unite-trimmed.qza \
	--i-reference-taxonomy unite-trimmed-taxonomy.qza \
	--o-classifier unite-trimed-classifier.qza

# Extract reference reads¶
qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer GTGCCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACHVGGGTWTCTAAT \
  --p-trunc-len 585 \
  --p-min-length 100 \
  --p-max-length 800 \
  --o-reads ref-seqs-341-926.qza

#   Train the classifier
# We can now train a Naive Bayes classifier as follows, using the reference reads and taxonomy that we just created
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs-341-926.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier silva-138-99-nb-341-926-classifier.qza
  
  
# Preprocessing for ITS reads 
# by trimming ITS samples with Q2-ITSxpress plugin for Dada2
# Installing the plug-in
source activate qiime2-2020.6
conda install -c bioconda itsxpress
pip install q2-itsxpress
qiime dev refresh-cache

# Trimming the ITS region - trimming has been shown to improve taxnomy classification
qiime itsxpress trim-pair-output-unmerged \
	--i-per-sample-sequences sequences.qza \
	--p-region ITS1 \
	--p-taxa F \
	--o-trimmed trimmed.qza
# The trimmed.qza can then be passed to the dada2 workflow




cd /gpfs0/bioinfo/users/obayomi/hinuman_analysis
mkdir 16S_illumina/
cd 16S_illumina/
cp  -r ../../qiime2_tutorial/scripts/ .

mkdir 00.mapping
mkdir 01.import
mkdir 02.Join/
mkdir 02.QC
mkdir 03.dada_denoise
mkdir 04.assign_taxonomy
mkdir 05.filter_table
mkdir 06.make_tree
mkdir 07.make_taxa_plots
mkdir 08.core_diversity
mkdir 09.differential_abundance
mkdir 10.exports/
mkdir sequence_data/
mkdir stitched_reads/
mkdir 04.assign_taxonomy/dada2 04.assign_taxonomy/deblur
mkdir 05.filter_table/dada2 05.filter_table/deblur
mkdir 06.make_tree/dada2 06.make_tree/deblur
mkdir 07.make_taxa_plots/dada2 07.make_taxa_plots/deblur
mkdir 08.core_diversity/dada2 08.core_diversity/deblur
mkdir 09.differential_abundance/dada2 09.differential_abundance/deblur
mkdir 10.exports/dada2 10.exports/deblur
mkdir 05.filter_table/dada2/outdoors/
mkdir 05.filter_table/deblur/outdoors/
mkdir 07.make_taxa_plots/dada2/outdoors/
mkdir 07.make_taxa_plots/deblur/outdoors/
mkdir 08.core_diversity/dada2/outdoors/
mkdir 08.core_diversity/deblur/outdoors/
mkdir 09.differential_abundance/dada2/outdoors/
mkdir 09.differential_abundance/deblur/outdoors/
mkdir 10.exports/dada2/outdoors/
mkdir 10.exports/deblur/outdoors/

source activate qiime2-2020.6

cd sequence_data/
# Download the sequence files from drop box like so
wget https://www.dropbox.com/s/68d0a4ry0m651d0/Osnat001-1-A_S1_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/4sbhklmvtxzf560/Osnat001-1-A_S1_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/bzthw0fh7rr4i4n/Osnat002-2-A_S2_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/7jxp1f4ystdy6kc/Osnat002-2-A_S2_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6tj3rdayt2kpab1/Osnat003-3-A_S3_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6xv8c3uk06bhae5/Osnat003-3-A_S3_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ojb9fyfwevvfodl/Osnat004-4-A_S4_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/c1bidebrw0ig4jl/Osnat004-4-A_S4_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/qs9vogr5j9m2b2z/Osnat005-5-A_S5_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/l839dsbn6dltuvk/Osnat005-5-A_S5_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/k1fupnlbyt6kzil/Osnat006-6-A_S6_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/wgq23tvjxjm5uky/Osnat006-6-A_S6_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/steb0iayoo8hr1z/Osnat007-7-A_S7_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ndsr3zuez5lvsc6/Osnat007-7-A_S7_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/3ywb80wktsz0k1p/Osnat008-8-A_S8_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/e8t09rl0yk6e6a3/Osnat008-8-A_S8_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/tdyyrhjrjz5xxtg/Osnat009-9-A_S9_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2gytm0ht5ovtrvq/Osnat009-9-A_S9_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/e5xs4eutu0hkws2/Osnat010-10-A_S10_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/kkeoa1l23sx8yig/Osnat010-10-A_S10_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/r5qcywegao76t5i/Osnat011-11-A_S11_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8g1m46l5dqbuelm/Osnat011-11-A_S11_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1hyfpoid46x8x3j/Osnat012-12-A_S12_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6lf75eplr530374/Osnat012-12-A_S12_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/b0j09t9jwj5uy2k/Osnat013-13-A_S13_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/mhh9rr73328udjy/Osnat013-13-A_S13_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ny72llkls4mxryp/Osnat014-14-A_S14_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2enbvyr716sv57a/Osnat014-14-A_S14_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/i984ynbr56xg303/Osnat015-15-A_S15_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/9j8pvph85fjx8ow/Osnat015-15-A_S15_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1bitqv49c96gnyn/Osnat016-16-A_S16_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/9i16v17t6qsciyy/Osnat016-16-A_S16_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/pnchzlbn6v8b1eg/Osnat017-17-A_S17_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/i729g9h4130pqqr/Osnat017-17-A_S17_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/7uz7ntn86aoqmni/Osnat018-18-A_S18_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/iq4c3evf1yqhv5l/Osnat018-18-A_S18_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/9unx8jom7h56dis/Osnat019-19-A_S19_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/qj1owkuyzbwh22z/Osnat019-19-A_S19_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8k2uu5tdfk7msc2/Osnat020-20-A_S20_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/vgescoer3edlx3w/Osnat020-20-A_S20_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/kxvuwawxl58zl5n/Osnat021-22-A_S21_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ge9r91qlnad38y7/Osnat021-22-A_S21_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/titbabp9v8f77pe/Osnat022-23-A_S22_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/b87xwhelfr4wc6p/Osnat022-23-A_S22_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/42l6mzmf1wfvj2u/Osnat023-24-A_S23_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/q4bwu79yjau1xpm/Osnat023-24-A_S23_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/plvj3m27nu5ajtr/Osnat024-25-A_S24_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/fo9b9jc0ot9v5dt/Osnat024-25-A_S24_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6xhbg5f7az89eqf/Osnat025-26-A_S25_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/slqht181w8pz8fg/Osnat025-26-A_S25_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/w1ltoxx6dspn31k/Osnat026-27-A_S26_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1b99drybs4azlhg/Osnat026-27-A_S26_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1di7ete7m1jzsvx/Osnat027-28-A_S27_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/kgixbuo3032gjvc/Osnat027-28-A_S27_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/fb2w1ybelsoyiyr/Osnat028-29-A_S28_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/cx7yi34o6w2y4yy/Osnat028-29-A_S28_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/c2e7efeju4odm6s/Osnat029-30-A_S29_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/m3orvdlzwdg10q6/Osnat029-30-A_S29_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/be871zufmtg4y4n/Osnat030-31-A_S30_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/x0du1qipti2oere/Osnat030-31-A_S30_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/mtluft7agwapcj9/Osnat031-32-A_S31_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/qf1n6mor5kiuojb/Osnat031-32-A_S31_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/zilima9cbiu0gkt/Osnat032-33-A_S32_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ej5fc1hmoxvku0r/Osnat032-33-A_S32_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ad005y0zxq6hz80/Osnat033-34-A_S33_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/4mihqhxjutcnyf6/Osnat033-34-A_S33_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/cr9ivwjg3zcxq8b/Osnat034-35-A_S34_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/xb474gdaryw6asx/Osnat034-35-A_S34_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6vs6219ny730cn6/Osnat035-36-A_S35_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/n3v9jdxtwa594j5/Osnat035-36-A_S35_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/xqnpzbdcs5b8yq4/Osnat036-37-A_S36_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/11930f2nke92thx/Osnat036-37-A_S36_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/zcezamfz3dhw1ry/Osnat037-38-A_S37_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/a9yuzar1wp8b5h2/Osnat037-38-A_S37_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/zeg5jr9y7dszgu6/Osnat038-39-A_S38_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/e1ts8kz4pg2nsc6/Osnat038-39-A_S38_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/cmsg8ns177dxscq/Osnat039-40-A_S39_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/alu3xylnxptm8ud/Osnat039-40-A_S39_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/x1i4psyuqz09v4b/Osnat040-41-A_S40_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/jw0fjjdifp9g8wk/Osnat040-41-A_S40_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/qvw7yonnigutk8t/Osnat041-42-A_S41_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/lgxxnjfokcu5now/Osnat041-42-A_S41_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/mmqnifwuj016fi7/Osnat042-43-A_S42_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1etglv4bxxscj19/Osnat042-43-A_S42_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/q8m7qppr3p68zjs/Osnat043-44-A_S43_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/gtkvj0yphalblum/Osnat043-44-A_S43_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/jcgctlnh57gv30a/Osnat044-45-A_S44_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/3h1l81u5l7j2its/Osnat044-45-A_S44_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ehbvetzlho8rcaa/Osnat045-46-A_S45_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/hchc7d7sabjaemi/Osnat045-46-A_S45_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/5e9kux3mdcww3nw/Osnat046-47-A_S46_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/f7pps3oty3eddh8/Osnat046-47-A_S46_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/x0qwg0omtktiuaa/Osnat047-48-A_S47_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/w8g7cixxmds8azp/Osnat047-48-A_S47_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/njd357ag0ceimrc/Osnat048-49-A_S48_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/l8f15v6umuu4arx/Osnat048-49-A_S48_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/flh6oe366xij2mp/Osnat049-50-A_S49_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/z8yt7oevx3nvcsy/Osnat049-50-A_S49_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/196w6uuozbsy5d0/Osnat050-51-A_S50_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/no33crz83ejg08x/Osnat050-51-A_S50_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/r18bh3pwjrpl5ev/Osnat051-52-A_S51_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ncenrw7vioiqwxa/Osnat051-52-A_S51_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/rzzgn4y8igtpwm1/Osnat052-53-A_S52_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/209fhqwfesy863b/Osnat052-53-A_S52_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/wzicz2x7q0qecxp/Osnat053-54-A_S53_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/a00igp5cud8oo1s/Osnat053-54-A_S53_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/r9z7l1mvc3ca3gp/Osnat054-9-A-2_S54_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/0c6nqafb5vxya56/Osnat054-9-A-2_S54_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2534tfaz9u0ha9x/Osnat055-10-A-2_S55_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/lj4efp7p6scxx4k/Osnat055-10-A-2_S55_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/h4rouc2lw5gojkj/Osnat056-11-A-2_S56_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/28t095grzg3q1on/Osnat056-11-A-2_S56_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/t97phz1diq7xubv/Osnat057-12-A-2_S57_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/rfbt0ddfmq56ts2/Osnat057-12-A-2_S57_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/pc8gjz9slzp7llu/Osnat058-13-A-2_S58_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/fcnw4s1zr8o50cb/Osnat058-13-A-2_S58_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/41l9qh8savzcuva/Osnat059-14-A-2_S59_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/z222qvnz8s1zbs4/Osnat059-14-A-2_S59_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/asnsuyj8h4wprbp/Osnat060-15-A-2_S60_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/nvkur3onzz57v7p/Osnat060-15-A-2_S60_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/82hjkv64o0qsmax/Osnat061-16-A-2_S61_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/hqw71i13dxnxwbu/Osnat061-16-A-2_S61_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6sl08ypt99qfadn/Osnat062-17-A-2_S62_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/i139j08lz0rchkb/Osnat062-17-A-2_S62_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/bj3p593110xftqr/Osnat063-18-A-2_S63_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/0dguwbg50unrzer/Osnat063-18-A-2_S63_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/tufojp7filxnhzi/Osnat064-19-A-2_S64_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/02cbhbu0pfcgoyc/Osnat064-19-A-2_S64_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/urii3v9yon8wiy3/Osnat065-20-A-2_S65_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/xupli8xsrcdfhyj/Osnat065-20-A-2_S65_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/utgclre4tvtzsn5/Osnat066-21-A-2_S66_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/43qhiri7i114o65/Osnat066-21-A-2_S66_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/zroy3fl0q4ohgbh/Osnat067-22-A-2_S67_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8r2l069gv28khw6/Osnat067-22-A-2_S67_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2423y2z4zib5oxr/Osnat068-23-A-2_S68_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/edctcpkpmh9s2e4/Osnat068-23-A-2_S68_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/lzd1zbs1qfc64cc/Osnat069-25-A-2_S69_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8cbt7j9m2llzuae/Osnat069-25-A-2_S69_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8cbt7j9m2llzuae/Osnat069-25-A-2_S69_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/jb4v8oz5uru7suy/Osnat070-26-A-2_S70_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6o8wyb2jxotlate/Osnat070-26-A-2_S70_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/q06chf0o2omvg8x/Osnat071-27-A-2_S71_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/jbkgq9j0jfwp0jc/Osnat071-27-A-2_S71_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2i8nuhsh1m5xjuk/Osnat072-28-A-2_S72_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/3m5qf4inzpmij84/Osnat072-28-A-2_S72_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/14reexsbfc681k9/Osnat073-29-A-2_S73_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/m2pts95tv2id1oo/Osnat073-29-A-2_S73_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/weror0upmkl1uze/Osnat074-30-A-2_S74_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/g66raoltj8bkpjw/Osnat074-30-A-2_S74_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/k0ykozl40jo0xfz/Osnat075-31-A-2_S75_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/l3lc2vsuvlfg068/Osnat075-31-A-2_S75_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/wnqr5bcungxarog/Osnat076-32-A-2_S76_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/y6mfp385ockr1mf/Osnat076-32-A-2_S76_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/1406w0y0piuxm6u/Osnat077-33-A-2_S77_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/hjv88e0g1tpowp8/Osnat077-33-A-2_S77_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2gjef219yxu39aq/Osnat078-34-A-2_S78_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/5jjok5xen91h11o/Osnat078-34-A-2_S78_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/zqyut5akqeppzb5/Osnat079-35-A-2_S79_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ualy9cbel6lbosv/Osnat079-35-A-2_S79_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/cjzwpvaquakc5gi/Osnat080-36-A-2_S80_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/hep8m1qzxpiixwy/Osnat080-36-A-2_S80_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/56vz5208mdnljyk/Osnat081-37-A-2_S81_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/m5h02k10108d5zo/Osnat081-37-A-2_S81_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/7ll3yjzqv1qsod1/Osnat082-38-A-2_S82_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/vhnr8oudb6w47vk/Osnat082-38-A-2_S82_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/o835fbwta94uafb/Osnat083-39-A-2_S83_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2ouwu7ec4zery39/Osnat083-39-A-2_S83_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/2j5u0p9bashchs5/Osnat084-40-A-2_S84_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/bmobmsk89vz6j9w/Osnat084-40-A-2_S84_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/ip8s5m8js51hjyb/Osnat085-41-A-2_S85_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/kkv310qb5bj1tio/Osnat085-41-A-2_S85_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/b57418xt65gy7ew/Osnat086-42-A-2_S86_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/7pq446fgmq3qi3y/Osnat086-42-A-2_S86_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/mrg337rq0y3wfe0/Osnat087-43-A-2_S87_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/8qcs22tqy013enq/Osnat087-43-A-2_S87_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/r1p3ni9w29oo7mi/Osnat088-44-A-2_S88_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/7qi55je786w0nr4/Osnat088-44-A-2_S88_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/gs978yaobm242hj/Osnat157-M-1_S157_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/fd3oqnu184r044m/Osnat157-M-1_S157_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/huwuosxhx4g3kw2/Osnat158-M-2_S158_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/r4zbjlxaxyxq6gh/Osnat158-M-2_S158_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/xue7t6fut1n5tbz/Osnat159-M-3_S159_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/6ettroevj86oqdb/Osnat159-M-3_S159_L001_R2_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/eul7alxaztts66q/Osnat160-M-_S160_L001_R1_001.fastq.gz?dl=0
wget https://www.dropbox.com/s/cr4l9bspsj25xqz/Osnat160-M-_S160_L001_R2_001.fastq.gz?dl=0

# Rename the files
rename '?dl=0' '' Osnat*

# Rename file names based on regular expression 
# here - delete the prefix Osnat followed by one 
# or more digits and a literal "-"
find "." -type f | perl -pe 'print $_; s/Osnat\d+\-//' | xargs -n2 mv

# Check fastq encoding
head -n 40 file.fastq | \
awk '{if(NR%4==0) printf("%s",$0);}' | \
od -A n -t u1 | \
 awk 'BEGIN{min=100;max=0;}{for(i=1;i<=NF;i++) {if($i>max) max=$i; if($i<min) min=$i;}}END{if(max<=74 && min<59) print "Phred+33"; else if(max>73 && min>=64) print "Phred+64"; else if(min>=59 && min<64 && max>73) print "Solexa+64"; else print "Unknown score encoding\!";}'


# Add this line to everdy script to avoid device out of space error
export TEMPDIR='/gpfs0/bioinfo/users/obayomi/hinuman_analysis/18S_illumina/tmp/' TMPDIR='/gpfs0/bioinfo/users/obayomi/hinuman_analysis/18S_illumina/tmp/'

 Stitch the fowards and reverse reads together using pear
bash scripts/join_reads.sh &



#subset MANIFEST file to contain only forward reads
grep -E "sample|forward" sequence_data/MANIFEST > sequence_data/temp && \
cat  sequence_data/temp >  sequence_data/MANIFEST  && rm -rf  sequence_data/temp
mv sequence_data/MANIFEST  sequence_data/se-MANIFEST

grep -E "sample|forward" sequence_data/pe-MANIFEST > sequence_data/se-MANIFEST
sed -i -E 's/filename/absolute-filepath/g' sequence_data/se-MANIFEST
sed -i -E 's/Osnat/$PWD\/sequence_data\/Osnat/g' sequence_data/se-MANIFEST


# Create MANIFEST file from se-MANIFEST
cp sequence_data/se-MANIFEST  stitched_reads/
mv stitched_reads/se-MANIFEST stitched_reads/joined-MANIFEST
sed -i -E 's/sequence_data/stitched_reads/g' stitched_reads/joined-MANIFEST
sed -i -E 's/_R1_001/.assembled/g' stitched_reads/joined-MANIFEST

# import pe-sequnces to qiime
qiime tools import \
	--type 'SampleData[PairedEndSequencesWithQuality]' \
	--input-path sequence_data/ \
	--output-path 01.import/reads.qza
	
# import se-sequnces to qiime
qiime tools import \
	--type 'SampleData[SequencesWithQuality]' \
	--input-path sequence_data/se-MANIFEST \
	--output-path 01.import/se-reads.qza \
	--input-format SingleEndFastqManifestPhred33

# import the pear joined reads
qiime tools import \
	--type 'SampleData[SequencesWithQuality]' \
	--input-path stitched_reads/joined-MANIFEST \
	--output-path 01.import/pear-joined-reads.qza \
	--input-format SingleEndFastqManifestPhred33


# Demultiplex and View reads quality
# Analyze quality scores of 10000 random samples
# paired end
qiime demux summarize \
	--p-n 10000 \
	--i-data 01.import/reads.qza \
	--o-visualization 02.QC/qual_viz.qzv
# Single-end	
qiime demux summarize \
	--p-n 10000 \
	--i-data 01.import/se-reads.qza \
	--o-visualization 02.QC/se-qual_viz.qzv

# Joined-reads using pear
qiime demux summarize \
	--p-n 10000 \
	--i-data 01.import/pear-joined-reads.qza \
	--o-visualization 02.QC/pear-joined-reads_viz.qzv

# make substitution in the file to make them general
# %s/\/se\-/\/${PREFIX}-/g
# %s/\/pe\-/\/${PREFIX}-/g
# this didn't produce a desired output
qsub scripts/vsearch-join-pairs.sh

# Qaulity filter, denoise and generate feature table uising dada2 and deblur
qsub scripts/dada2_denoize.sh	
qsub scripts/deblur_denoize.sh
qsub scripts/classify_ASVs.sh
qsub scripts/phylogeny_tree.sh
# Remove singletons and non-target sequences e.g chloroplast, mitochondria, archaea and eukaryota
# for protists - Bacteria,Fungi,Chytridiomycota,Basidiomycota,Metazoa,Rotifera,Gastrotricha,
# Nematozoa,Euglenozoa,Embryophyta,Spermatophyta,Asterales,Brassicales,Caryophyllales,Cupressales,
# Fabales,Malpighiales,Pinales,Rosales,Solanales,Arecales,Asparagales,Poales,Capsicum,Jatropha,
# Bryophyta,Tracheophyta
# for all the samples combined
qsub scripts/filter_feature_table.sh # REMOVE_RARE="false" - remove non-target ASVs
# For indoors, outdors and mock
qsub scripts/filter_samples.sh # subset the filtered ASV tables
# for all the samples combined
qsub scripts/filter_feature_table.sh # REMOVE_RARE="true" - remove rare ASVs for combine
# For indoors, outdors and mock
qsub scripts/filter_feature_table.sh # REMOVE_RARE="true" # remove rare OTUs for indoors, outdoors and mock

# Create combinedtreatment mapping file from original mapping file
>( echo -n "sample-id\ttreatment\n" ; awk 'BEGIN{OFS="\t"} NR > 1 {print $4,$5}' 00.mapping/combined.tsv | uniq ) \
> 00.mapping/combined-treatment.tsv
grep -E "^sample|^MO" 00.mapping/combined-treatment.tsv > 00.mapping/mock-treatment.tsv
grep -E "^sample|^Med|^out" 00.mapping/combined-treatment.tsv > 00.mapping/outdoors-treatment.tsv
grep -E "^sample|^cont|^in" 00.mapping/combined-treatment.tsv > 00.mapping/indoors-treatment.tsv
grep -v "control" 00.mapping/combined-treatment.tsv > 00.mapping/outdoors-treatment.tsv



cd hinuman_analysis/18S_illumina/
mv pear* stitched_reads/
seqkit stats stitched_reads/*.fastq.gz > stitched_reads/reads_stats.tsv

# Get length of every sequence in fastq file
bioawk -c fastx 'BEGIN{OFS="\t"} {print $name,length($seq)}' stitched_reads/AV-8_S188_L001.assembled.fastq.gz

grep -v "control" 00.mapping/metadata.tsv > 00.mapping/minus-control-metadata.tsv

sed -i -E 's/,AV/,$PWD\/sequence_data\/AV/g' sequence_data/pe-MANIFEST

# generate samples and treatment bar plots
qsub scripts/taxa-plots.sh

# Alpha and Beta diversity
qsub scripts/corediversity_analysis.sh

# Differential abundance testing using ANCOM
qsub  scripts/ancom_differential_abundance.sh

qsub scripts/find-probes.sh
# get samples were probe was found
sort -V find-probe/ACTCCTACGGGAGGCAGC.txt | \
 cut -d"-" -f2-4 | \
 cut -d"_" -f1 | \
 less -S

# Function annotation analysis using PICRUST2
