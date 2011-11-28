#!/usr/bin/perl
# rgd-sslp-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

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

my ($model_file, $help, $input_file, $output_file);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_file,
			'output=s' => \$output_file,
			'help' => \$help);
			
if($help or !($model_file and $input_file))
{
	printHelp();
	exit(0);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_file, auto_write => 1);

my $rat_id = '10116';
my $mouse_id = '10090';
my $human_id = '9606';

my $rat_item = $item_doc->add_item('Organism', taxonId => $rat_id);
my $mouse_item = $item_doc->add_item('Organism', taxonId => $mouse_id);
my $human_item = $item_doc->add_item('Organism', taxonId => $human_id);

#process Header

print "Processing Data...\n";
open(my $IN, '<', $input_file) or die "cannot open $input_file\n";

my $index;
my %mouse_genes;
my %human_genes;
my $header_flag = 0;
while(<$IN>)
{
	next if /^#/; #ignore comment lines
	chomp;
	unless($header_flag) #parses header line
	{
		$index = RCM::parseHeader($_);
		$header_flag = 1;
		next
	}
  
	my @fields = split(/\t/);
   	my %data = zip(@$index, @fields);

	my $rat_gene = $item_doc->add_item('Gene', primaryIdentifier => $data{RAT_GENE_RGD_ID}, organism => $rat_item);

	my @mouse_ids = split(/\|/, $data{MOUSE_ORTHOLOG_RGD});
	my @mouse_types = split(/\|/, $data{MOUSE_ORTHOLOG_SOURCE});
	foreach my $mouse_id (@mouse_ids) {
		unless($mouse_genes{$mouse_id})
		{
			$mouse_genes{$mouse_id} = $item_doc->add_item('Gene', 
												primaryIdentifier => $mouse_id, 
												organism => $mouse_item);

		}
		my $type = shift(@mouse_types);
		$item_doc->add_item('Orthologue', gene => $rat_gene, 
										homologue => $mouse_genes{$mouse_id}, 
										type => $type);
		$item_doc->add_item('Orthologue', gene => $mouse_genes{$mouse_id}, 
										homologue => $rat_gene, 
										type => $type);
	} #end foreach $mouse_id

	my @human_ids = split(/\|/, $data{HUMAN_ORTHOLOG_RGD});
	my @human_types = split(/\|/, $data{HUMAN_ORTHOLOG_SOURCE});
	foreach my $human_id (@human_ids) {
		unless($human_genes{$human_id})
		{
			$human_genes{$human_id} = $item_doc->add_item('Gene', 
												primaryIdentifier => $human_id, 
												organism => $human_item);
		}
		my $type = shift(@human_types);
		$item_doc->add_item('Orthologue', gene => $rat_gene, 
										homologue => $human_genes{$human_id}, 
										type => $type);
		$item_doc->add_item('Orthologue', gene => $human_genes{$human_id}, 
										homologue => $rat_gene, 
										type => $type);
	} #end foreach $human_id


	

}#end while(<IN>)
close $IN;
$item_doc->close();

exit(0);

### Subroutines ###

sub printHelp
{
print<<HELP;
perl rgd-orthologs-to-xml.pl

arguments:
model	model file
input	RGD flat file
output	XML output file
help	prints this message
			
HELP
}