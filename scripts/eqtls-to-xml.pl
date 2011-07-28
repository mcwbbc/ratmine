#!/usr/bin/perl
###################
# eqtls-to-xml.pl
#
# written by Andrew Vallejos
#
###################

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


my ($model_file, $eqtls_dir, $eqtl_xml, $help);

GetOptions(
	'model=s' => \$model_file,
	'qtl_input=s' => \$eqtls_dir,
	'xml_output=s' => \$eqtl_xml,
	'help' => \$help);
	
if($help or !$model_file)
{
	printHelp();
	exit(0);
}

my $taxon_id = 10116;

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $eqtl_xml);

my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

my $pub_item = $item_doc->add_item('Publication', pubMedId => '15711544');

my $sub_item = $item_doc->add_item('Submission', title => 'eQTL Data',
												experimentDate => '20100301',
												publication => $pub_item);
												
my $project_item = $item_doc->add_item('Project', name =>'eQTL Data',
												namePI => 'Timothy',
												surnamePI => 'Aitman',
												submissions => [$sub_item]);

my @files = <${eqtls_dir}*.txt>;

my @qtls;
my %sslp_items;
my %probe_items;
foreach my $eqtls_file (@files)
{
	open(my $IN, '<', $eqtls_file) or die "cannot open $eqtls_file";

	my $hf = 0;
	my $index;
	while(<$IN>)
	{
		chomp;
		if($hf == 0)
		{
			$hf = 1;
			$index = &RCM::parseHeader($_);
			next
		}
		my @fields = split(/\t/);
	   	my %qtl_info = zip(@$index, @fields);
	
		my $qtl_attr = processLine(\%qtl_info);
		$qtl_attr = addStandardStuff($qtl_attr, [$org_item, $sub_item]);
		$item_doc->add_item(eQTL => %$qtl_attr);
	}
	close $IN;

}
$item_doc->close;

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
	my $data = shift;

	my $reaper_pval = $$data{eQTL_Reaper_p_value};
	my $fat_change = $$data{Fold_change_Fatc};
	my $fat_pval = $$data{'t-test_p-value_in_Fat'};
	my $kidney_change = $$data{Fold_change_Kidneyc};
	my $kidney_pval = $$data{'t-test_p-value_in_Kidney'};

	my %qtl_attr;
	unless($sslp_items{$$data{peak_marker}})
	{
		my $item = $item_doc->add_item('SimpleSequenceLengthVariation', symbol => $$data{peak_marker});
		$sslp_items{$$data{peak_marker}} = $item;
	}
	$qtl_attr{sslv} = $sslp_items{$$data{peak_marker}};
	
	unless($probe_items{$$data{probeset}})
	{
		my $item = $item_doc->add_item('ProbeSet', primaryIdentifier => $$data{probeset});
		$probe_items{$$data{probeset}} = $item;
	}	
	$qtl_attr{probeSet} = $probe_items{$$data{probeset}};

	$qtl_attr{reaperPValue} = $reaper_pval;
	
	my $expr_item_fat = $item_doc->add_item('Expression', tissue => 'fat',
														foldChange => $fat_change,
														pval => $fat_pval);
	
	my $expr_item_kidney = $item_doc->add_item('Expression', tissue => 'kidney',
														foldChange => $kidney_change,
														pval => $kidney_pval);
	
	$qtl_attr{tissueExpressions} = [$expr_item_fat, $expr_item_kidney];
		
	return \%qtl_attr;
}#processLine

sub addStandardStuff
{
	my ($qtl_attr, $stuff) = @_;
	foreach my $item (@$stuff)
	{
#		print "$item\n";
		my $class = lc $item->{':implements'}; #determine item's model
#		print "$class\n";
#		print "$qtl_item\n";
		$$qtl_attr{$class} = $item;
	}
	return $qtl_attr;
}
