#!/usr/bin/perl
###################
# eqtls-to-xml.pl
#
# written by Andrew Vallejos
#
###################

use warnings;
use strict;
use lib '../perlmods';
use RCM;
use ITEMHOLDER;

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
	
if($help or !$model_file)
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
$project_item->set('namePI', 'Timothy');
$project_item->set('surnamePI', 'Aitman');


my $sub_item = $item_factory->make_item('Submission');
$sub_item->set('title', 'eQTL Data');
$sub_item->set('experimentDate', '20100301');

my $pub_item = $item_factory->make_item('Publication');
$pub_item->set('pubMedId', '15711544');
$pub_item->as_xml($writer);

$sub_item->set('publication', $pub_item);
$project_item->set('submissions', [$sub_item]);
$project_item->as_xml($writer);

my @files = <${eqtls_dir}*.txt>;

my @qtls;
my $sslp_items = ITEMHOLDER->new;
my $probe_items = ITEMHOLDER->new;
foreach my $eqtls_file (@files)
{
	open(IN, $eqtls_file) or die "cannot open $eqtls_file";

	my $count = 0;
	my %index;
	while(<IN>)
	{
		chomp;
		$count++;
		if($count == 1)
		{
			%index = &RCM::parseHeader($_);
			next
		}
		
		my $qtl_item = &processLine($item_factory, $_, \%index, $writer);
		$qtl_item = &addStandardStuff($qtl_item, [$org_item, $sub_item]);
		$qtl_item->as_xml($writer);
		push(@qtls, $qtl_item);
	}
	close IN;

}

&writeAll($writer, $sslp_items);
&writeAll($writer, $probe_items);


$sub_item->set('dataPoints', \@qtls);
$sub_item->as_xml($writer);
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
	my ($item_factory, $line, $index, $writer) = @_;
		
	my $qtl_item = $item_factory->make_item('eQTL');
	my $sslp_item = $item_factory->make_item('SSLP');
	my $probe_item = $item_factory->make_item('ProbeSet');
	
	my @data = split(/\t/, $line);
	
#	print "$line\n";

#	print $data[$$index{Chomosome_Position_of_peak_marker}] . ':' .
#		$data[$$index{Chromosome_position_of_probeset}] . "\n";

		
	my $reaper_pval = $data[$$index{eQTL_Reaper_p_value}];
	my $fat_change = $data[$$index{Fold_change_Fatc}];
	my $fat_pval = $data[$$index{'t-test_p-value_in_Fat'}];
	my $kidney_change = $data[$$index{Fold_change_Kidneyc}];
	my $kidney_pval = $data[$$index{'t-test_p-value_in_Kidney'}];

	unless($sslp_items->holds($data[$$index{peak_marker}]))
	{
		my $item = &makeSSLP($sslp_item, \@data, $index, $item_factory, $writer);
		$sslp_items->store($data[$$index{peak_marker}], $item);
	}
	$sslp_item = $sslp_items->get($data[$$index{peak_marker}]);

	$qtl_item->set('sslp', $sslp_item);
	my $eqtls = $sslp_item->get('eqtls');
	push(@$eqtls, $qtl_item);
	$sslp_item->set('eqtls', $eqtls);
	$sslp_items->store($data[$$index{peak_marker}], $sslp_item);
	
	unless($probe_items->holds($data[$$index{probeset}]))
	{
		my $item = &makeProbe($probe_item, \@data, $index, $item_factory, $writer);
		$probe_items->store($data[$$index{probeset}], $item);
	}
	$probe_item = $probe_items->get($data[$$index{probeset}]);
	
	$qtl_item->set('probeSet', $probe_item);
	$eqtls = $sslp_item->get('eqtls');
	push(@$eqtls, $qtl_item);
	$probe_item->set('eqtls', $eqtls);
	$probe_items->store($data[$$index{probeset}], $probe_item);

	
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
		
	return $qtl_item;
}#processLine

sub makeSSLP
{
	my($item, $data, $index, $item_factory, $writer) = @_;
	
	#print $data . "\n" . $$data[$$index{peak_marker}] . "\n";
	$item->set('symbol', $$data[$$index{peak_marker}]);
	
	return $item;
}#makeSSLP

sub makeProbe
{

	my($item, $data, $index, $item_factory, $writer) = @_;
	
	$item->set('primaryIdentifier', $$data[$$index{probeset}]);
	
	return $item;
}
sub addStandardStuff
{
	my ($qtl_item, $stuff) = @_;
	foreach my $item (@$stuff)
	{
#		print "$item\n";
		my $class = lc $item->{':implements'}; #determine item's model
#		print "$class\n";
#		print "$qtl_item\n";
		$qtl_item->set("$class", $item);
	}
	return $qtl_item;
}

sub writeAll
{
	my ($writer, $items) = @_;
	foreach my $k ($items->contents)
	{
		$items->get($k)->as_xml($writer);
	}
}