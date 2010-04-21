#!/usr/bin/perl
# rgd-strains-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file

#use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../intermine/perl/lib');
}

use XML::Writer;
use InterMine::Item;
use InterMine::ItemFactory;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use Cwd;

my ($model_file, $strains_file, $strains_xml, $help);
GetOptions( 'model=s' => \$model_file,
			'rgd_strains=s' => \$strains_file,
			'output_file=s' => \$strains_xml,
			'help' => \$help);
			
if($help or !($model_file and $strains_file))
{
	&printHelp;
	exit(0);
}

my $data_source = 'Rat Genome Database';
my $taxon_id = 10116;
my $output = new IO::File(">$strains_xml");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);
$writer->startTag("items");

my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon_id);
$org_item->as_xml($writer);
my $dataset_item = $item_factory->make_item('DataSet');
$dataset_item->set('title', $data_source);
$dataset_item->as_xml($writer);

# read the genes file
open STRAINS, $strains_file;
my %index;
my %pubs;
while(<STRAINS>)
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
		s/\026/ /g; #replaces 'Syncronous Idle' (Octal 026) character with space
		s/\022/ /g; #replaces 'Device Control' (Octal 022) character with space
		my @strain_info = split("\t", $_);
		my $strain_item = $item_factory->make_item('Strain');
		$strain_item->set('organism', $org_item); 
		$strain_item->set('dataset', $dataset_item);
		
		$strain_item->set('primaryIdentifier', $strain_info[$index{'RGD_ID'}]);
		$strain_item->set('symbol', $strain_info[$index{'STRAIN_SYMBOL'}]) unless($strain_info[$index{'STRAIN_SYMBOL'}] eq '');
		$strain_item->set('name', $strain_info[$index{'FULL_NAME'}]) unless($strain_info[$index{'FULL_NAME'}] eq '');
		$strain_item->set('origin', $strain_info[$index{'ORIGIN'}]) unless($strain_info[$index{'ORIGIN'}] eq '');
		$strain_item->set('source', $strain_info[$index{'SOURCE'}]) unless($strain_info[$index{'SOURCE'}] eq '');
		$strain_item->set('type', $strain_info[$index{'STRAIN_TYPE'}]) unless($strain_info[$index{'STRAIN_TYPE'}] eq '');
		
		$strain_item->as_xml($writer);
	} #end if-else
	
}#end while
close STRAINS;
$writer->endTag("items");

###Subroutines###

sub printHelp
{
	print <<HELP;
#
# perl rgd-strains-to-xml.pl 
#
# Purpose:
#	Convert the STRAINS file from RGD into InterMine XML
#
#	Options:
#	--model=file\tMine model file
#	--rgd_strains\t\tSTRAINS file from RGD FTP site
#	--output_file\t\tInterMine XML file 
#	--help\t\tPrint this message
HELP
}