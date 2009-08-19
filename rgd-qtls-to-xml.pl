#!/usr/bin/perl
# rgd-qtls-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../intermine/perl/lib');
}

use XML::Writer;
use InterMine::Item;
use InterMine::ItemFactory;
use InterMine::Model;

my ($model_file, $qtls_file, $gff_file) = @ARGV;

die "Must point to valid InterMine Model" unless (-e $model_file);
my $data_source = 'RGD';
my $taxon_id = 10116;


my @items = ();
my %pubs = ();
my @gff;



# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);

####
#User Additions
my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon_id);
push(@items, $org_item); #add organism to items list


# read the genes file
open QTLS, $qtls_file;
my %index;
my $count = 0;
while(<QTLS>)
{
	chomp;
	if( $_ !~ /^\d/) #parses header line
	{
		my @header = split(/\t/, $_);
		for(my $i = 0; $i < @header; $i++)
		{	$index{$header[$i]} = $i;	}
	
	}
	else
	{
    	my @qtl_info = split(/\t/, $_);
		my $qtl_item = $item_factory->make_item('Qtl');
		$qtl_item->set('organism', $org_item);
		$qtl_item->set('primaryIdentifier', $qtl_info[$index{QTL_RGD_ID}]);
		$qtl_item->set('symbol', $qtl_info[$index{QTL_SYMBOL}]);
		$qtl_item->set('lod', $qtl_info[$index{LOD}]) unless $qtl_info[$index{LOD}] eq '';
		$qtl_item->set('pValue', $qtl_info[$index{P_VALUE}]) unless $qtl_info[$index{P_VALUE}] eq '';
		$qtl_item->set('trait', $qtl_info[$index{TRAIT_NAME}]);
		$qtl_item->set('name', $qtl_info[$index{QTL_NAME}]);
		
		unless($qtl_info[$index{'3.4_MAP_POS_START'}] eq '')
		{
			my @gff_line; #Create a GFF3 compatable line for each record
			push(@gff_line, $qtl_info[$index{CHROMOSOME_FROM_REF}]); #chromsome location
			push(@gff_line, "RatGenomeDatabase"); #source
			push(@gff_line, "region"); #SOFA term
			push(@gff_line, $qtl_info[$index{'3.4_MAP_POS_START'}]); #start position
			push(@gff_line, $qtl_info[$index{'3.4_MAP_POS_STOP'}]); #stop position
			push(@gff_line, '.'); #score, left blank since QTLs have two different scores
			push(@gff_line, '.'); #strand, irrelevant
			push(@gff_line, '.'); #phase, irrelevant
			push(@gff_line, "ID=$qtl_info[$index{QTL_RGD_ID}]"); #attributes line
		
			push(@gff, join("\t", @gff_line)); #add line to gff list
		}
		push(@items, $qtl_item);
	} #end if-else	

}#end while
close QTLS;

# write everything out as xml:
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3);
$writer->startTag("items");
#write the organism and the genes
for my $item (@items) {
  $item->as_xml($writer);
}
#write the pubs
#for my $item (values(%pubs)) {
#  $item->as_xml($writer);
#}
$writer->endTag("items");

open(GFF, ">$gff_file");
foreach my $line (@gff) {	print GFF "$line\n";	}
close GFF;

