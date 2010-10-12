#!/usr/bin/perl
# rgd-qtls-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

#use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../intermine/perl/lib');
}

#use XML::Writer;
use InterMine::Item::Document;
use InterMine::Model;
#use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use Cwd;
use lib '../perlmods';
use RCM;
use ITEMHOLDER;

my ($model_file, $qtls_file, $qtl_xml, $help) = (undef, undef, undef, undef);

GetOptions(
	'model=s' => \$model_file,
	'qtl_input=s' => \$qtls_file,
	'xml_output=s' => \$qtl_xml);

unless ($help eq '' and $model_file ne '' and -e $model_file)
{
	print "\nrgd-qtls-to-xml.pl\n";
	print "Convert the QTLS_RAT flat file from RGD into InterMine XML\n";
	print "rgd-qtls-to-xml.pl --model model.xml --qtl_input QTLS_RAT --xml_output qtls.xml \n";
	exit(0);
}

my $data_source = 'RGD';
my $taxon_id = 10116;
my $output = new IO::File(">$qtl_xml");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

my $pubs = ITEMHOLDER->new;
my $genes = ITEMHOLDER->new;
my $strains = ITEMHOLDER->new;
my @gff;



# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::Item::Document(model => $model);
$writer->startTag("items");

####
#User Additions
my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon_id);
$org_item->as_xml($writer);

my $chr_items = &RCM::makeChromosomeItems($item_factory, $writer);

# read the genes file
open QTLS, $qtls_file;
my %index;
my $count = 0;
while(<QTLS>)
{
	chomp;
	if( $_ !~ /^\d/) #parses header line
	{
		%index = &RCM::parseHeader($_);
	}
	else
	{
    	my @qtl_info = split(/\t/, $_);
		my $qtl_item = $item_factory->make_item('QTL');
		$qtl_item->set('organism', $org_item);
		$qtl_item->set('primaryIdentifier', $qtl_info[$index{QTL_RGD_ID}]);
		$qtl_item->set('symbol', $qtl_info[$index{QTL_SYMBOL}]);
		
		my $syn_item = $item_factory->make_item('Synonym');
		$syn_item->set('value', $qtl_info[$index{QTL_SYMBOL}]);
		#$syn_item->set('type', 'symbol');
		$syn_item->set('subject', $qtl_item);
		$syn_item->as_xml($writer);

		my $syn_item2 = $item_factory->make_item('Synonym');
		$syn_item2->set('value', $qtl_info[$index{QTL_NAME}]);
		#$syn_item2->set('type', 'name');
		$syn_item2->set('subject', $qtl_item);
		$syn_item2->as_xml($writer);
				
		$qtl_item->set('lod', $qtl_info[$index{LOD}]) unless $qtl_info[$index{LOD}] eq '';
		$qtl_item->set('pValue', $qtl_info[$index{P_VALUE}]) unless $qtl_info[$index{P_VALUE}] eq '';
		$qtl_item->set('trait', $qtl_info[$index{TRAIT_NAME}]);
		$qtl_item->set('name', $qtl_info[$index{QTL_NAME}]);
		#$qtl_item->set('synonyms', [$syn_item, $syn_item2]);
		
		my $chrom = $chr_items->get($qtl_info[$index{CHROMOSOME_FROM_REF}]);
		$qtl_item->set('chromosome', $chrom) unless $chrom;
		
		if($qtl_info[$index{'3_4_MAP_POS_START'}] =~ /\d/)
		{
			my $loc_item = &RCM::makeLocationItem($item_factory,
										$qtl_item,
										$writer,
										$chr_items->get($qtl_info[$index{CHROMOSOME_FROM_REF}]),
										$qtl_info[$index{'3_4_MAP_POS_START'}],
										$qtl_info[$index{'3_4_MAP_POS_STOP'}]);
			
			$qtl_item->set('locations', [$loc_item]);
		}
		
		
		#Add Publications
		if ($qtl_info[$index{CURATED_REF_PUBMED_ID}] ne '') {
	      	my @publication_info = split(/;/, $qtl_info[$index{CURATED_REF_PUBMED_ID}]);
	      	my @currentPubs = ();
	      	foreach my $p (@publication_info) {
	        	#reuse publication object if we already have it in the $pubs array
	        	unless($pubs->holds($p)) {
	          		my $pub1 = $item_factory->make_item("Publication");
	          		$pub1->set("pubMedId", $p);
	          		$pubs->store($p, $pub1);
	          		$pub1->as_xml($writer);
	        	}#end if-else
	      		push(@currentPubs, $pubs->get($p));
	      	}#end foreach
	      	$qtl_item->set("publications", \@currentPubs);
    	}#end if

		#Add Strains
		if($qtl_info[$index{STRAIN_RGD_IDS}] ne '')
		{
			my @strain_info = split(/;/, $qtl_info[$index{STRAIN_RGD_IDS}]);
			my @strainItems = ();
			foreach my $s (@strain_info)
			{
				my $strain_item;
				unless($strains->holds($s))
				{
					$strain_item = $item_factory->make_item("Strain");
					$strain_item->set("primaryIdentifier", $s);
					#$strain_item->set("qtls", [$qtl_item]);
					$strains->store($s, $strain_item);
				}
				$strain_item = $strains->get($s);
				my $qtls = $strain_item->get("qtls");
				push(@$qtls, $qtl_item);
				
				$strain_item->set('qtls', $qtls);
				#$strains->store($s, $strain_item);
	
				push(@strainItems, $strain_item);
			}#foreach
			$qtl_item->set('strains', \@strainItems);
		}#if


		#Add Candidate Genes
		if($qtl_info[$index{CANDIDATE_GENE_RGD_IDS}] ne '')
		{
			my @gene_info = split(/;/, $qtl_info[$index{CANDIDATE_GENE_RGD_IDS}]);
			my @geneItems = ();
			foreach my $g (@gene_info)
			{
				my $gene_item;
				unless($genes->holds($g))
				{
					$gene_item = $item_factory->make_item("Gene");
					$gene_item->set('primaryIdentifier', $g);
					$genes->store($g, $gene_item);
				}
				$gene_item = $genes->get($g);
				my $qtls = $gene_item->get('parentQTLs');
				push(@$qtls, $qtl_item);
				
				$gene_item->set('parentQTLs', $qtls);
				#$genes->store($g, $gene_item);
				
				push(@geneItems, $gene_item);
			}#end foreach
			$qtl_item->set('candidateGenes', \@geneItems);
		}#end if
      	$qtl_item->as_xml($writer);
	} #end if-else	

}#end while
close QTLS;

#print out Genes then Strains
$genes->as_xml($writer);

$strains->as_xml($writer);


$writer->endTag("items");