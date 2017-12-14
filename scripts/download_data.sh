#!/bin/bash

if ["$1" = ""]
then
echo "usage: download_data.sh [pipelineId | all]"
fi


set -e

TEMP_DIR="/home/intermine/git_ratmine/ratmine_src_data_mod/tmp";
DOWNL_DIR="/home/intermine/git_ratmine/ratmine_src_data_mod";
SCRIPTS_DIR="/home/intermine/git_ratmine/intermine/ratmine/scripts";

rm -rf $TEMP_DIR/*

#rat-gff3 =======================================================
if [ "$1" = "gff3" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
scp -r rgddata@kyle.rgd.mcw.edu:/home/rgddata/pipelines/RGDGff3Pipeline/dist/log/RGDGFF3/Output/Gene .
scp -r rgddata@kyle.rgd.mcw.edu:/home/rgddata/pipelines/RGDGff3Pipeline/dist/log/RGDGFF3/Output/Qtl .
scp -r rgddata@kyle.rgd.mcw.edu:/home/rgddata/pipelines/RGDGff3Pipeline/dist/log/RGDGFF3/Output/Sslp .
rm $DOWNL_DIR/genome/gff/rat/*.* 
rm $DOWNL_DIR/genome/gff/human/*.* 
rm $DOWNL_DIR/genome/gff/mouse/*.* 
gunzip $TEMP_DIR/Gene/Rat/rat60/*RATMINE*
gunzip $TEMP_DIR/Gene/Mouse/mouse38/*RATMINE*
gunzip $TEMP_DIR/Gene/Human/human37/*RATMINE*
cp $TEMP_DIR/Gene/Rat/rat60/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/rat/
cp $TEMP_DIR/Gene/Mouse/mouse38/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/mouse/
cp $TEMP_DIR/Gene/Human/human37/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/human/
gunzip $TEMP_DIR/Qtl/Rat/rat60/*RATMINE*
gunzip $TEMP_DIR/Qtl/Mouse/mouse38/*RATMINE*
gunzip $TEMP_DIR/Qtl/Human/human37/*RATMINE*
cp $TEMP_DIR/Qtl/Rat/rat60/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/rat/
cp $TEMP_DIR/Qtl/Mouse/mouse38/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/mouse/
cp $TEMP_DIR/Qtl/Human/human37/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/human/
gunzip $TEMP_DIR/Sslp/Rat/rat60/*RATMINE*
gunzip $TEMP_DIR/Sslp/Mouse/mouse38/*RATMINE*
gunzip $TEMP_DIR/Sslp/Human/human37/*RATMINE*
cp $TEMP_DIR/Sslp/Rat/rat60/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/rat/
cp $TEMP_DIR/Sslp/Mouse/mouse38/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/mouse/
cp $TEMP_DIR/Sslp/Human/human37/*RATMINE*.gff3 $DOWNL_DIR/genome/gff/human/

fi

#panther ====================================================
if [ "$1" = "panther" ] || [ "$1" = "all" ] 
   then

cd $TEMP_DIR
wget ftp://ftp.pantherdb.org/ortholog/11.1/RefGenomeOrthologs.tar.gz 
tar xvfz $TEMP_DIR/RefGenomeOrthologs.tar.gz
rm $TEMP_DIR/RefGenomeOrthologs.tar.gz
cp $TEMP_DIR/RefGenomeOrthologs $DOWNL_DIR/panther/

fi

#orthologs ====================================================
if [ "$1" = "orthologs" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/RGD_ORTHOLOGS_RATMINE.txt
cd $SCRIPTS_DIR
perl  rgd-orthologs-to-xml.pl --model /home/intermine/git_ratmine/intermine/ratmine/dbmodel/build/model/genomic_model.xml --input $TEMP_DIR/RGD_ORTHOLOGS_RATMINE.txt --output $TEMP_DIR/orthologs.xml
rm $DOWNL_DIR/homology/orthologs.xml
cp $TEMP_DIR/orthologs.xml $DOWNL_DIR/homology/

fi


#homologene =====================================================
if [ "$1" = "homologene" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.ncbi.nih.gov/pub/HomoloGene/current/homologene.data
rm $DOWNL_DIR/homologene/homologene.data
cp $TEMP_DIR/homologene.data $DOWNL_DIR/homologene/homologene.data

fi

# omim-text =========================================================

# omim-genes =======================================================

# rat-rs ============================================================
if [ "$1" = "rat-rs" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/ontology_obo_files/rat_strain/rat_strain.obo
rm $DOWNL_DIR/rs/rat_strain.obo
cp $TEMP_DIR/rat_strain.obo $DOWNL_DIR/rs/

fi

# uniprot-rat =======================================================
if [ "$1" = "uniprot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget -O 10116_uniprot_sprot.xml.gz "http://www.uniprot.org/uniprot/?format=xml&query=taxonomy:10116 AND reviewed%3Ayes&compress=yes"
wget -O 10116_uniprot_trembl.xml.gz "http://www.uniprot.org/uniprot/?format=xml&query=taxonomy:10116 AND reviewed%3Ano&compress=yes"
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/docs/keywlist.xml.gz
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot_varsplic.fasta.gz

gunzip $TEMP_DIR/10116_uniprot_sprot.xml.gz
gunzip $TEMP_DIR/10116_uniprot_trembl.xml.gz
gunzip $TEMP_DIR/keywlist.xml.gz
gunzip $TEMP_DIR/uniprot_sprot_varsplic.fasta.gz

rm -rf $DOWNL_DIR/uniprot/*.*
rm -rf $DOWNL_DIR/uniprot/docs

cp $TEMP_DIR/*uniprot* $DOWNL_DIR/uniprot
mkdir $DOWNL_DIR/uniprot/docs
cp $TEMP_DIR/keywlist.xml $DOWNL_DIR/uniprot/docs


fi

# experiment eqtl =======================================================

# rat-kegg-pathway =====================================================

# reactome ==============================================================
if [ "$1" = "reactome" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget http://www.reactome.org/download/current/UniProt2Reactome_All_Levels.txt
rm $DOWNL_DIR/reactome/*
cp UniProt2Reactome_All_Levels.txt $DOWNL_DIR/reactome/

fi

# rat-pharmgkb ===========================================================
# db-snp =================================================================
# go-annotation ===============not done==========================================
if [ "$1" = "go-annotation" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
#wget ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/HUMAN/gene_association.goa_human.gz
#wget http://geneontology.org/gene-associations/gene_association.goa_human.gz
#wget ftp://ftp.geneontology.org/pub/go/gene-associations/goa_human.gaf.gz
#wget ftp://ftp.geneontology.org/pub/go/gene-associations/gene_association.mgi.gz
#wget ftp://ftp.informatics.jax.org/pub/reports/gene_association.mgi
wget ftp://ftp.rgd.mcw.edu/pub/data_release/gene_association.rgd.gz 
rm $DOWNL_DIR/go-annotation/*
#gunzip gene_association.goa_human.gz
#gunzip goa_human.gaf.gz
#gunzip gene_association.mgi.gz
gunzip gene_association.rgd.gz

cp gene_association.rgd $DOWNL_DIR/go-annotation/
#cp gene_association.mgi $DOWNL_DIR/go-annotation/
#cp gene_association.goa_human $DOWNL_DIR/go-annotation/
#cp goa_human.gaf $DOWNL_DIR/go-annotation/

fi

# go =====================================================================
if [ "$1" = "go" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology.1_2.obo
rm $DOWNL_DIR/go/gene_ontology.1_2.obo
cp gene_ontology.1_2.obo $DOWNL_DIR/go

fi

# rat-mp =================================================================
if [ "$1" = "rat-mp" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget http://www.informatics.jax.org/downloads/reports/MPheno_OBO.ontology
rm $DOWNL_DIR/mp/MPheno_OBO.obo
cp MPheno_OBO.ontology $DOWNL_DIR/mp/MPheno_OBO.obo

fi

# rat-mp-annot =======================================================
if [ "$1" = "rat-mp-annot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_mp 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_mp 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_mp 
rm $DOWNL_DIR/mp-annotation/*
cp rattus_genes_mp $DOWNL_DIR/mp-annotation/
cp homo_genes_mp $DOWNL_DIR/mp-annotation/
cp mus_genes_mp $DOWNL_DIR/mp-annotation/

fi


# rat-qtl-mp-annot =======================================================
if [ "$1" = "rat-qtl-mp-annot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_qtls_mp 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_qtls_mp 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_qtls_mp 
rm $DOWNL_DIR/mp-annotation-qtl/*
cp rattus_qtls_mp $DOWNL_DIR/mp-annotation-qtl/
cp homo_qtls_mp $DOWNL_DIR/mp-annotation-qtl/
cp mus_qtls_mp $DOWNL_DIR/mp-annotation-qtl/

fi

# rat-pw =================================================================
if [ "$1" = "rat-pw" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/ontology_obo_files/pathway/pathway.obo
rm $DOWNL_DIR/pw/pathway.obo
cp pathway.obo $DOWNL_DIR/pw

fi

# rat-pw-annot ===========================================================
if [ "$1" = "rat-pw-annot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_pw 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_pw 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_pw 
rm $DOWNL_DIR/pw-annotation/*
cp rattus_genes_pw $DOWNL_DIR/pw-annotation/
cp homo_genes_pw $DOWNL_DIR/pw-annotation/
cp mus_genes_pw $DOWNL_DIR/pw-annotation/

fi

# rat-do =================================================================
if [ "$1" = "rat-do" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/ontology_obo_files/disease/RDO.obo
rm $DOWNL_DIR/do/RDO.obo
cp RDO.obo $DOWNL_DIR/do

fi

# rat-do-annot ==========================================================
if [ "$1" = "rat-do-annot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_rdo
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_rdo
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_rdo
rm $DOWNL_DIR/do-annotation/*
cp rattus_genes_rdo $DOWNL_DIR/do-annotation/
cp homo_genes_rdo $DOWNL_DIR/do-annotation/
cp mus_genes_rdo $DOWNL_DIR/do-annotation/

fi


# rat-qtl-do-annot =======================================================
if [ "$1" = "rat-qtl-do-annot" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_qtls_rdo 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_qtls_rdo 
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_qtls_rdo 
rm $DOWNL_DIR/do-annotation-qtl/*
cp rattus_qtls_rdo $DOWNL_DIR/do-annotation-qtl/
cp homo_qtls_rdo $DOWNL_DIR/do-annotation-qtl/
cp mus_qtls_rdo $DOWNL_DIR/do-annotation-qtl/

fi


# rat-nbo ================================================================
if [ "$1" = "rat-nbo" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget -O nbo.obo http://data.bioontology.org/ontologies/NBO/submissions/23/download?apikey=8b5b7825-538d-40e0-9e9e-5ab9274a9aeb
rm -f $DOWNL_DIR/nbo/*
cp nbo.obo $DOWNL_DIR/nbo/

fi

# uberon  ================================================================
# rat-biogrid ============================================================
if [ "$1" = "rat-biogrid" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR

wget http://thebiogrid.org/downloads/archives/Release%20Archive/BIOGRID-3.4.134/BIOGRID-ORGANISM-3.4.134.psi25.zip
unzip BIOGRID-ORGANISM-3.4.134.psi25.zip
rm $DOWNL_DIR/biogrid/*
cp BIOGRID-ORGANISM-Rattus* $DOWNL_DIR/biogrid

fi

# psi-mi-ontology ========================================================
if [ "$1" = "psi-mi-ontology" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget http://obo.cvs.sourceforge.net/viewvc/obo/obo/ontology/genomic-proteomic/protein/psi-mi.obo
rm $DOWNL_DIR/psi/*
cp psi-mi.obo $DOWNL_DIR/psi/

fi

# intact  ================================================================
if [ "$1" = "intact" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.ebi.ac.uk/pub/databases/IntAct/current/psi25/species/rat.zip
wget ftp://ftp.ebi.ac.uk/pub/databases/IntAct/current/psi25/species/mouse.zip
wget ftp://ftp.ebi.ac.uk/pub/databases/IntAct/current/psi25/species/human.zip
rm $DOWNL_DIR/intact/*
cp rat.zip $DOWNL_DIR/intact
cp human.zip $DOWNL_DIR/intact
cp mouse.zip $DOWNL_DIR/intact
cd $DOWNL_DIR/intact
unzip rat.zip
unzip human.zip
unzip mouse.zip
rm -f $DOWNL_DIR/intact/*.zip

fi

# pubmed-gene  ============================================================
if [ "$1" = "pubmed-gene" ]  || [ "$1" = "all" ]
   then

cd $TEMP_DIR
wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz
wget ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
gunzip gene2pubmed.gz
gunzip gene_info.gz
rm $DOWNL_DIR/pubmed/*
cp gene2pubmed $DOWNL_DIR/pubmed/
cp gene_info $DOWNL_DIR/pubmed/

fi

# update-publications =====================================================
# entrez-organism  ========================================================


exit

#gff3 files
cd $TEMP_DIR



wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_go -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_go -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_go -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/gene_association.rgd.gz -p $TEMP_DIR
gunzip -v $TEMP_DIR/gene_association.gz
VAR1 = "sort -k 2,2 "$TEMP_DIR"rattus_genes_go > "$DOWNL_DIR"go-annotation/rattus_genes_go";
`$VAR1`;
VARa = "sort -k 2,2 "$TEMP_DIR"gene_association.rgd > "$DOWNL_DIR"go-annotation/gene_association.rgd";
`$VARa`;
VAR2 = "sort -k 2,2 "$TEMP_DIR"homo_genes_go > "$DOWNL_DIR"go-annotation/homo_genes_go";
`$VAR2`;
VAR3 = "sort -k 2,2 "$TEMP_DIR"mus_genes_go > "$DOWNL_DIR"go-annotation/mus_genes_go";
`$VAR3`;




wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_mp -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_mp -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_mp -p $TEMP_DIR;
VAR1 = "sort -k 2,2 "$TEMP_DIR"rattus_genes_mp > "$DOWNL_DIR"mp-annotation/rattus_genes_mp";
`$VAR1`;
VAR2 = "sort -k 2,2 "$TEMP_DIR"homo_genes_mp > "$DOWNL_DIR"mp-annotation/homo_genes_mp";
`$VAR2`;
VAR3 = "sort -k 2,2 "$TEMP_DIR"mus_genes_mp > "$DOWNL_DIR"mp-annotation/mus_genes_mp";
`$VAR3`;



wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_nbo -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_nbo -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_nbo -p $TEMP_DIR;
VAR1 = "sort -k 2,2 "$TEMP_DIR"rattus_genes_nbo > "$DOWNL_DIR"nbo-annotation/rattus_genes_nbo";
`$VAR1`;
VAR2 = "sort -k 2,2 "$TEMP_DIR"homo_genes_nbo > "$DOWNL_DIR"nbo-annotation/homo_genes_nbo";
`$VAR2`;
VAR3 = "sort -k 2,2 "$TEMP_DIR"mus_genes_nbo > "$DOWNL_DIR"nbo-annotation/mus_genes_nbo";
`$VAR3`;

wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_pw -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_pw -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_pw -p $TEMP_DIR;
VAR1 = "sort -k 2,2 "$TEMP_DIR"rattus_genes_pw > "$DOWNL_DIR"pw-annotation/rattus_genes_pw";
`$VAR1`;
VAR2 = "sort -k 2,2 "$TEMP_DIR"homo_genes_pw > "$DOWNL_DIR"pw-annotation/homo_genes_pw";
`$VAR2`;
VAR3 = "sort -k 2,2 "$TEMP_DIR"mus_genes_pw > "$DOWNL_DIR"pw-annotation/mus_genes_pw";
`$VAR3`;

wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/rattus_genes_rdo -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/homo_genes_rdo -p $TEMP_DIR;
wget ftp://ftp.rgd.mcw.edu/pub/data_release/annotated_rgd_objects_by_ontology/mus_genes_rdo -p $TEMP_DIR;
VAR1 = "sort -k 2,2 "$TEMP_DIR"rattus_genes_rdo > "$DOWNL_DIR"rdo-annotation/rattus_genes_rdo";
`$VAR1`;
VAR2 = "sort -k 2,2 "$TEMP_DIR"homo_genes_rdo > "$DOWNL_DIR"rdo-annotation/homo_genes_rdo";
`$VAR2`;
VAR3 = "sort -k 2,2 "$TEMP_DIR"mus_genes_rdo > "$DOWNL_DIR"rdo-annotation/mus_genes_rdo";
`$VAR3`;


