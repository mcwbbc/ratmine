#!/usr/bin/perl
###################
# eqtls-to-xml.pl
#
###################

use warnings;
use strict;
use lib '../perlmods';
use RCM;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../../intermine/perl/lib');
}

use XML::Writer;
use InterMine::Item;
use InterMine::ItemFactory;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use Cwd;

my ($model_file, $eqtls_dir, $eqtl_xml, $help) = (undef, undef, undef, undef, undef);

GetOptions(
	'model=s' => \$model_file,
	'qtl_input=s' => \$eqtls_dir,
	'xml_output=s' => \$eqtl_xml,
	'help' => \$help);
	
if($help)
{
	&printHelp;
	exit(0);
}

my $taxon_id = 10116;
my $output = new IO::File(">$eqtl_xml");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);
$writer->startTag("items");

my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon_id);
$org_item->as_xml($writer);

my $project_item = $item_factory->make_item('Project');
$project_item->set('name', 'eQTL Data');

my $experiment_item = $item_factory->make_item('Experiment');
$experiment_item->set('name', 'eQTL Data');
$project_item->set('experiment', $experiment_item);
$project_item->as_xml($writer);

my @files = <${eqtls_dir}*.txt>;

my @qtls;
my $chr_items = &RCM::makeChromosomes($item_factory, $writer);

foreach my $eqtls_file (@files)
{
	open(IN, $eqtls_file) or die "cannot open $eqtls_file";

	my $line = <IN>;
	my %index = &RCM::parseHeader($line);
	while(<IN>)
	{
		chomp;
		my $qtl_item = &processLine($item_factory, $_, \%index, $chr_items, $writer);
		$qtl_item = &addStuff($qtl_item, [$org_item, $experiment_item]);
		push(@qtls, $qtl_item);
	}

}
$experiment_item->set('eqtls', \@qtls);
$experiment_item->as_xml($writer);
$writer->endTag("items");
### Subroutines ###

sub printHelp
{
	print <<HELP;
	perl eqtls-to-xml.pl 
	
	arguments
	--model \t model file
	--qtl_input \t directory to qtl txt files
	--xml_output \t intermine XML file
	--help \t prints this message
HELP
}

sub processLine
{
	my ($item_factory, $line, $index, $chr_items, $writer) = @_;
	
	my $qtl_item = $item_factory->make_item('eQTL');
	my $sslp_item = $item_factory->make_item('SSLP');
	my $probe_item = $item_factory->make_item('ProbeSet');
	
	my @data = split(/\t/, $line);
	my $reaper_pval = $data[$$index{eQTL_Reaper_p_value}];
	my $fat_change = $data[$$index{Fold_change_Fatc}];
	my $fat_pval = $data[$$index{'t-test_p-value_in_Fat'}];
	my $kidney_change = $data[$$index{Fold_change_Kidneyc}];
	my $kidney_pval = $data[$$index{'t-test_p-value_in_Kidney'}];
	
	$sslp_item->set('symbol', $data[$$index{peak_marker}]);
	$sslp_item->set('chromosome', $$chr_items{$data[$$index{Chomosome_Position_of_peak_marker}]});
	my $sslp_loc_item = &RCM::make_location($item_factory, 
								$$chr_items{$data[$$index{Chomosome_Position_of_peak_marker}]}, 
								$data[$$index{Physical_position_of_peak_marker}]);
	$sslp_item->set('location', $sslp_loc_item);
	
	
	
	$probe_item->set('primaryIdentifier', $data[$$index{probeset}]);
	$probe_item->set('chromosome', $$chr_items{$data[$$index{Chromosome_position_of_probeset}]});
	my $probe_loc_item = &RCM::make_location($item_factory, 
								$$chr_items{$data[$$index{Chomosome_Position_of_probeset}]}, 
								$data[$$index{Physical_position_of_probeset}]);
	$probe_item->set('location', $probe_loc_item);
	
	$qtl_item->set('reaperPValue', $reaper_pval);
	my $expr_item_fat = $item_factory->make_item('Expression');
	$expr_item_fat->set('tissue', 'fat');
	$expr_item_fat->set('foldChange', $fat_change);
	$expr_item_fat->set('pval', $fat_pval);
	$expr_item_fat->as_xml($writer);
	
	my $expr_item_kidney = $item_factory->make_item('Expression');
	$expr_item_kidney->set('tissue', 'kidney');
	$expr_item_kidney->set('foldChange', $kidney_change);
	$expr_item_kidney->set('pval', $kidney_pval);
	$expr_item_kidney->as_xml($writer);
	
	$qtl_item->set('tissueExpressions', [$expr_item_fat, $expr_item_kidney]);
	
	$qtl_item->as_xml($writer);
	
}

sub addStandardStuff
{
	my ($qtl_item, $stuff) = @_;
	foreach my $item (@$stuff)
	{
		my $model = $item->model; #determine item's model
		$qtl_item->set($model, $item);
	}
	return $qtl_item;
}