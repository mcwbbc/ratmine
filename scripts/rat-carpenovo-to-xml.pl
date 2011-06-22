#!/usr/bin/perl
# rat-carpenovo-to-xml.pl
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


my ($model_file, $genes_file, $gene_xml, $help, $taxon_id);
GetOptions( 'model=s' => \$model_file,
			'input_file=s' => \$input_file,
			'output_file=s' => \$output_xml,
			'taxon_id=s' => \$taxon_id,
			'help' => \$help);

if($help or !($model_file and $genes_file))
{
	printHelp();
	exit(0);
}

my $data_source = 'Rat Genome Database';

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $gene_xml, auto_write => 1);

####
#User Additions
my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);
my $dataset_item = $item_doc->add_item('DataSet', name => $data_source);

#my $chrom_items;
#$chrom_items = RCM::addChromosomes($item_doc, $org_item);

# read the genes file
open(my $GENES, '<', $genes_file) or die ("cannot open $genes_file");
my $index;
my %pubs;
my %prots;
while(<$GENES>)