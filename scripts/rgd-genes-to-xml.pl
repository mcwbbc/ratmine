#!/usr/bin/perl
# rgd-genes-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file

#use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../../intermine/perl/InterMine-Util/lib');
}

#use XML::Writer;
use InterMine::Item::Document;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use lib '../perlmods';
use RCM;
use List::MoreUtils qw/zip/;


my ($model_file, $genes_file, $gene_xml, $help);
GetOptions( 'model=s' => \$model_file,
			'rgd_genes=s' => \$genes_file,
			'output_file=s' => \$gene_xml,
			'help' => \$help);

if($help or !($model_file and $genes_file))
{
	&printHelp;
	exit(0);
}

my $data_source = 'Rat Genome Database';
my $taxon_id = 10116;

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $gene_xml, auto_write => 1);

####
#User Additions
my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);
my $dataset_item = $item_doc->add_item('DataSet', name => $data_source);

# read the genes file
open(my $GENES, '<', $genes_file) or die ("cannot open $genes_file");
my $index;
my %pubs;
while(<$GENES>)
{
	chomp;
	if(/^\D/) #parses header line
	{
		$index = RCM::parseHeader($_);
		next
	}
    #    print "\n   ------------ Line: ".$count."  --------------  \n";
	$_ =~ s/\026/ /g; #replaces 'Syncronous Idle' (Octal 026) character with space
	
	my @fields = split(/\t/);
   	my %gene_info = zip(@$index, @fields);
	
	my %gene_attr = ( organism => $org_item,
					dataSets => [$dataset_item],
					primaryIdentifier => $gene_info{GENE_RGD_ID},
					secondaryIdentifier => "RGD:$gene_info{GENE_RGD_ID}",
					symbol => $gene_info{SYMBOL});
	$gene_attr{name} = $gene_info{NAME} if $gene_info{NAME};
	$gene_attr{description} = $gene_info{GENE_DESC} if $gene_info{GENE_DESC};

	$gene_attr{ncbiGeneNumber} = $gene_info{ENTREZ_GENE} if ($gene_info{ENTREZ_GENE} and 
																$gene_info{GENE_TYPE} !~ /splice|allele/i);
	$gene_attr{geneType} = $gene_info{GENE_TYPE} if $gene_info{GENE_TYPE};
	$gene_attr{nomenclatureStatus} = $gene_info{NOMENCLATURE_STATUS} if $gene_info{NOMENCLATURE_STATUS};
	$gene_attr{fishBand} = $gene_info{FISH_BAND} if $gene_info{FISH_BAND};


	if (my $ids = $gene_info{CURATED_REF_PUBMED_ID}) 
	{
      	for my $id (split(/,/, $ids))
		{
			$pubs{$id} = $item_doc->add_item('Publication', pubMedId => $id) unless ($pubs{$id});
			push @{$gene_attr{publications}}, $pubs{$id};
		}
	}
	
	my $gene_item = $item_doc->add_item(Gene => %gene_attr);
	
	my %ensemblIds; #prevents duplicate ids for a single record
	if( my $ids = $gene_info{ENSEMBL_ID} )
	{
		foreach my $id (split(',', $ids))
		{
			next if (exists $ensemblIds{$id});
			my $syn_item = $item_doc->add_item('Synonym',
												value => '$id',
												subject => $gene_item);
			$ensemblIds{$id} = 1;
		}
	}
	
	unless ($gene_info{ENTREZ_GENE} eq '' or $gene_info{GENE_TYPE} =~ /splice|allele/i)
	{
		my $syn_item = $item_doc->add_item('Synonym',
												value => $gene_info{ENTREZ_GENE},
												subject => $gene_item);
	}
	

}#end while
close $GENES;
$item_doc->close();

###Subroutintes###

sub printHelp
{
	print <<HELP;

perl rgd-genes-to-xml.pl 

Purpose:
Convert the GENES_RAT file from RGD into InterMine XML

Arguments:
 --model		Mine model file
 --rgd_genes		GENES_RAT file from RGD FTP site
 --output_file		InterMine XML file 
 --help			Print this message
HELP
}