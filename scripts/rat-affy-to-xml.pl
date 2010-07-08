#!/usr/bin/perl
# rat-affy-to-xml.pl
# purpose: to create a target items xml file for intermine from Affy Metrix Tab files
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

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
use XML::XPath;
use Getopt::Long;
use Cwd;
use warnings;

my ($model_file, $help, $input_dir, $genes_dir, $output_file);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_dir,
			'genes=s' => \$genes_dir,
			'output=s' => \$output_file,
			'help' => \$help);
			
if($help or !$model_file or !$input_dir)
{
	&printHelp;
}

my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);

my $output = new IO::File(">$output_file");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

$writer->startTag("items");

my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', '10116');
$org_item->as_xml($writer);

print "Reading $input_dir...\n";
my @files = <$input_dir/*.*>;
print "Found " . @files . " files...\n";
my %gene_items;

foreach my $input_file (@files)
{	
	my $array_item = $item_factory->make_item('Array');
	my $name = $1 if $input_file =~ /[\\\/]([^\\\/]+?)\./;
	$array_item->set('primaryIdentifier', $name);
	$array_item->set('vendor', 'AffyMetrix');
	$array_item->set('organism', $org_item);
	
	my ($affyMap, $ensemblMap) = &buildGeneMaps($name, $genes_dir);
	
	#process Header
	open(IN, $input_file) or die "cannot open $input_file\n";
	my $line = <IN>;
	my %index = &parseHeader($line);

	my @probe_items;
	print "Processing Data...$input_file\n";
	my %probes;
	
	while(<IN>)
	{
		chomp;
		my @data = split("\t", $_);
		
		unless($probes{$data[$index{'Probe_Set_Name'}]})
		{
			$probes{$data[$index{'Probe_Set_Name'}]} = &processProbe(\@data, \%index, $affyMap, $ensemblMap);
			$probes{$data[$index{'Probe_Set_Name'}]}->set('organism', $org_item);
			$probes{$data[$index{'Probe_Set_Name'}]}->set('arrays', [$array_item]);
			push(@probe_items, $probes{$data[$index{'Probe_Set_Name'}]})
		}
	
		my $seq_item = $item_factory->make_item('Sequence');
		$seq_item->set('residues', $data[$index{'Probe_Sequence'}]);
		$seq_item->as_xml($writer);
		
		my $sequences = $probes{$data[$index{'Probe_Set_Name'}]}->get('sequences');
		push(@$sequences, $seq_item);
		$probes{$data[$index{'Probe_Set_Name'}]}->set('sequences', $sequences);
		
	}#end while
	
	foreach my $item (values %probes)
	{
		$item->as_xml($writer);
	}
	$array_item->set('probeSets', \@probe_items);
	$array_item->as_xml($writer);

	close IN;
}
$writer->endTag("items");

### Subroutines ###
sub parseHeader #parses header line
{
	print "Processing Header...\n";
	my $h = shift;
	chomp $h;
	my %i;
	my @header = split(/\t/, $h);
	for(my $x = 0; $x < @header; $x++)
	{	
		$header[$x] =~ s/[\s\.]/_/g; #make things unix friendly
		print $header[$x] . "\n";
		$i{$header[$x]} = $x;	
	}
	return %i;
}

sub processProbe
{
	my ($arg1, $arg2, $affyMap, $ensemblMap) = @_;
	my @data = @$arg1;
	my %index = %$arg2;
	
	my $probe_item = $item_factory->make_item('ProbeSet');
	$probe_item->set('primaryIdentifier', $data[$index{'Probe_Set_Name'}]);
	$probe_item->set('organism', $org_item);
	
	
	my @genes;
	if($$affyMap{$data[$index{'Probe_Set_Name'}]})
	{
		unless($gene_items{$$affyMap{$data[$index{'Probe_Set_Name'}]}})
		{
			my $gene_item = $item_factory->make_item('Gene');
			$gene_item->set('primaryIdentifier', $$affyMap{$data[$index{'Probe_Set_Name'}]});
			$gene_item->set('organism', $org_item);
			$gene_item->as_xml($writer);
			$gene_items{$$affyMap{$data[$index{'Probe_Set_Name'}]}} = $gene_item;
		}
		
		push(@genes, $gene_items{$$affyMap{$data[$index{'Probe_Set_Name'}]}});
	}
	
	if($$ensemblMap{$data[$index{'Probe_Set_Name'}]})
	{
		unless($gene_items{$$ensemblMap{$data[$index{'Probe_Set_Name'}]}})
		{
			my $gene_item = $item_factory->make_item('Gene');
			$gene_item->set('primaryIdentifier', $$ensemblMap{$data[$index{'Probe_Set_Name'}]});
			$gene_item->set('organism', $org_item);
			$gene_item->as_xml($writer);
			$gene_items{$$ensemblMap{$data[$index{'Probe_Set_Name'}]}} = $gene_item;
		}
		
		push(@genes, $gene_items{$$ensemblMap{$data[$index{'Probe_Set_Name'}]}});
	}
	
	$probe_item->set('genes', \@genes);	
	return $probe_item;
}

sub buildGeneMaps
{
	my ($array, $gene_dir) = @_;
	my @gene_files = <$gene_dir/*$array*.txt>;
	print "Found " . @gene_files . " genes files...\n";
	
	my ($ensemblMap, $affyMap);
	foreach my $file (@gene_files)
	{
		if($file =~ /ensembl/i)
		{
			$ensemblMap = &processGeneFile($file);
		}
		else
		{
			$affyMap = &processGeneFile($file);
		}
		
	}
	
	return ($affyMap, $ensemblMap);
}

sub processGeneFile
{
	my ($file, $ref);
	$file = shift;
	
	open IN, $file;
	while(<IN>)
	{
		chomp;
		my $line = $_;
		next if $line =~ /^probe/i;
		my ($probe, $gene) = split(/\t/, $line);
		$$ref{$probe} = $gene;
	}
	close IN;
	return $ref;
}