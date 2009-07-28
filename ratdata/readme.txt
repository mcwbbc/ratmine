This directory holds external data files, which may not be the newest versions.

To get the newest versions, follow the instructions below:

genome/fasta/chr*.fasta
-------------------------
download from
http://hgdownload.cse.ucsc.edu/goldenPath/rn4/bigZips/chromFa.tar.gz
File is currently approximately 800 Mb
After uncompressing, you'll find directories for each chromosome, and 2 files in each folder.  The files to use are named chr*.fa, and you should copy them into the genome/fasta/ directory, and rename them to have a fasta extension

genome/gff/*.gff
--------------------------
these were obtained from RGD staff at MCW, so there is currently no standard download location.  You may just use the ones in the git repository

uniprot/uniprot-taxonomy-10116.xml (90mb)
-------------------------
download from
http://www.uniprot.org/uniprot/?query=taxonomy%3a10116&force=yes&format=xml
The file needs no modification and can be placed directly in the uniprot directory for the integrate

kegg/map_title.tab (11kb)
---------------------------------------
download from
ftp://ftp.genome.jp/pub/kegg/pathway/map_title.tab

kegg/rno_gene_map.tab (96kb)
----------------------------------
download from
ftp://ftp.genome.jp/pub/kegg/pathway/organisms/rno/rno_gene_map.tab
