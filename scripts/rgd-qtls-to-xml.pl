#!/usr/bin/perl
# rgd-qtls-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

#use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../../intermine/perl/InterMine-Util/lib');
}

use InterMine::Item::Document;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use lib '../perlmods';
use RCM;
use List::MoreUtils qw/zip/;

my ($model_file, $qtls_file, $qtl_xml, $help);

GetOptions(
	'model=s' => \$model_file,
	'qtl_input=s' => \$qtls_file,
	'xml_output=s' => \$qtl_xml,
	'help' => \$help);

if($help or !$model_file or !(-e $model_file))
{
	print "\nrgd-qtls-to-xml.pl\n";
	print "Convert the QTLS_RAT flat file from RGD into InterMine XML\n";
	print "rgd-qtls-to-xml.pl --model model.xml --qtl_input QTLS_RAT --xml_output qtls.xml \n";
	exit(0);
}

my $data_source = 'Rat Genome Database';
my $taxon_id = 10116;

my %pubs;
my %genes;
my %strains;

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $qtl_xml, auto_write => 1);

####
#User Additions
my $org_item = $item_doc->add_item('Organism', 'taxonId' => $taxon_id);

my $chrom_items;
$chrom_items = RCM::addChromosomes($item_doc);

# read the genes file
open(my $QTLS, '<', $qtls_file);
my $index;
my $count = 0;
while(<$QTLS>)
{
	chomp;
	if(/^\D/) #parses header line
	{
		$index = &RCM::parseHeader($_);
		next;
	}

	my @fields = split(/\t/);
   	my %qtl_info = zip(@$index, @fields);

	my %qtl_attr = ( organism => $org_item,
					primaryIdentifier => $qtl_info{QTL_RGD_ID},
					symbol => $qtl_info{QTL_SYMBOL},
					trait => $qtl_info{TRAIT_NAME},
					name => $qtl_info{QTL_NAME});
	
	$qtl_attr{lod} = $qtl_info{LOD} if $qtl_info{LOD};
	$qtl_attr{pValue} = $qtl_info{P_VALUE} if $qtl_info{P_VALUE};
			
	#$qtl_item->set('synonyms', [$syn_item, $syn_item2]);
	
	my $chrom = $chrom_items->{$qtl_info{CHROMOSOME_FROM_REF}};
	$qtl_attr{chromosome} = $chrom unless $chrom;
	
	if( $qtl_info{'3_4_MAP_POS_START'} )
	{
		my($start, $end) = @qtl_info{ '3_4_MAP_POS_START', '3_4_MAP_POS_STOP'};
		$qtl_attr{locations} = [ $item_doc->add_item( 'Location',
												locatedOn => $chrom,
												start => $start,
												end => $end
												)];
	}
	
	
	#Add Publications
	if (my $ids = $qtl_info{CURATED_REF_PUBMED_ID}) 
	{
      	for my $id (split(/;/, $ids))
		{
			$pubs{$id} = $item_doc->add_item('Publication', pubMedId => $id) unless ($pubs{$id});
			push @{$qtl_attr{publications}}, $pubs{$id};
		}
	}
	
	#Add Strains
	if (my $ids = $qtl_info{STRAIN_RGD_ID}) 
	{
      	for my $id (split(/;/, $ids))
		{
			$strains{$id} = $item_doc->add_item('Strain', primaryIdentifier => $id) unless ($strains{$id});
			push @{$qtl_attr{strains}}, $strains{$id};
		}
	}
	
	#Add Candidate Genes
	if (my $ids = $qtl_info{CANDIDATE_GENE_RGD_IDS}) 
	{
      	for my $id (split(/;/, $ids))
		{
			$pubs{$id} = $item_doc->add_item('Gene', primaryIdentifier => $id) unless ($genes{$id});
			push @{$qtl_attr{candidateGenes}}, $genes{$id};
		}
	}
	
	my $qtl_item = $item_doc->add_item( QTL => %qtl_attr);
	
	my $syn_item = $item_doc->add_item('Synonym', value => $qtl_info{QTL_SYMBOL},
											subject => $qtl_item);
										
	my $syn_item2 = $item_doc->add_item('Synonym', value => $qtl_info{QTL_NAME},
											subject => $qtl_item);	

}#end while
close $QTLS;
$item_doc->close();
