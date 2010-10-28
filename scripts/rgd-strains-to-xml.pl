#!/usr/bin/perl
# rgd-strains-to-xml.pl
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

my ($model_file, $strains_file, $strains_xml, $help, $strain_obo);
GetOptions( 'model=s' => \$model_file,
			'rgd_strains=s' => \$strains_file,
			'output_file=s' => \$strains_xml,
			'strain_obo=s' => \$strain_obo,
			'help' => \$help);
			
if($help or !($model_file and $strains_file))
{
	printHelp();
	exit(0);
}

my $data_source = 'Rat Genome Database';
my $taxon_id = 10116;

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $strains_xml, auto_write => 0);

my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

my $dataset_item = $item_doc->add_item('DataSet', name => $data_source);


# read the genes file
open(my $STRAINS, '<', $strains_file);
my %pubs;
my %rsIndex;

if ($strain_obo)
{
	print "Creating Obo Index...\n";
	%rsIndex = createOboMap($strain_obo);

}

print "Creating XML...\n";

my $index;
my $hf = 0;
while(<$STRAINS>)
{
	chomp;
	if(/^\D/ and $hf == 0) #parses header line
	{
		$index = RCM::parseHeader($_);
		$hf++;
		next;
	}
	elsif(/^\d/) #ignore multiline records
	{
		s/\026/ /g; #replaces 'Syncronous Idle' (Octal 026) character with space
		s/\022/ /g; #replaces 'Device Control' (Octal 022) character with space
		
		my @fields = split(/\t/);
	   	my %strain_info = zip(@$index, @fields);
		
		my %strain_attr = ( organism => $org_item,
							dataset => $dataset_item,
							primaryIdentifier => $strain_info{RGD_ID});
		$strain_attr{symbol} = $strain_info{STRAIN_SYMBOL} if $strain_info{STRAIN_SYMBOL};
		$strain_attr{name} = $strain_info{FULL_NAME} if $strain_info{FULL_NAME};
		$strain_attr{origin} = $strain_info{ORIGIN} if $strain_info{ORIGIN};
		$strain_attr{source} = $strain_info{SOURCE} if $strain_info{SOURCE};
		$strain_attr{type} = $strain_info{STRAIN_TYPE} if $strain_info{STRAIN_TYPE};
		
		my $strain_item = $item_doc->add_item(Strain => %strain_attr);
		
		if($rsIndex{$strain_info{RGD_ID}})
		{
			my $rs_item = $item_doc->add_item('RSTerm', identifier => $rsIndex{$strain_info{RGD_ID}},
											strain => $strain_item);
											
			$strain_item->set('rsTerm', $rs_item);
		}
	} #end if-else
	
}#end while
close $STRAINS;
$item_doc->write;
$item_doc->close;
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
#	--strain_obo\t\tStrain Ontology OBO file [optional]
#	--help\t\tPrint this message
HELP
}

sub createOboMap
{
	my $file = shift;
	my %map;
	
	my $entry = '';
	open IN, $file or die("cannot open $file");
	while(<IN>)
	{
		$entry .= $_;
		if($_ =~ /^\s+$/)
		{	
			if($entry =~ /id:\s+(RS:\s?\d+)[\d\D\s]+?RGD ID:\s+(\d+)/m)
			{	$map{$2} = $1;	}
			$entry = '';
		}
	}
	print "Found " . keys(%map) . " RSTerms\n";
	return %map;
}