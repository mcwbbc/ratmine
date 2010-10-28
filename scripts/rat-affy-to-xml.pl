#!/usr/bin/perl
# rat-affy-to-xml.pl
# purpose: to create a target items xml file for intermine from Affy Metrix Tab files
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

use lib '../perlmods';
use RCM;

my ($model_file, $help, $input_dir, $genes_dir, $output_file);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_dir,
			'genes=s' => \$genes_dir,
			'output=s' => \$output_file,
			'help' => \$help);
			
if($help or !$model_file or !$input_dir)
{
	printHelp();
	exit(0);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc= new InterMine::Item::Document(model => $model, output => $output_file, auto_write => 1);

my $org_item = $item_doc->add_item('Organism', taxonId => '10116');

print "Reading $input_dir...\n";
my @files = <$input_dir/*.*>;
print "Found " . @files . " files...\n";

my %gene_items;

foreach my $input_file (@files)
{	
	my $name = $1 if $input_file =~ /[\\\/]([^\\\/]+?)\./;
	
	my $array_item = $item_doc->add_item('Array', primaryIdentifier => $name,
											vendor => 'AffyMetrix',
											organism => $org_item);
	
	my ($affyMap, $ensemblMap) = &buildGeneMaps($name, $genes_dir);
	
	#process Header
	open(my $IN, '<', $input_file) or die "cannot open $input_file\n";

	my @probe_items;
	print "Processing Data...$input_file\n";
	my %probes;
	
	my $index;
	while(<$IN>)
	{
		chomp;
		if(/^Probe Set Name/)
		{
			$index = &RCM::parseHeader($_);
			next;
		}
		
		my @fields = split(/\t/);
	   	my %affy_info = zip(@$index, @fields);
	
		my %affy_attr;
		my $id = $affy_info{Probe_Set_Name};
		my @genes;
		unless($probes{$id})
		{
			%affy_attr = (primaryIdentifier => $id,
							organism => $org_item,
							arrays => [$array_item]);
			
			if($$affyMap{$id})
			{
				unless($gene_items{$$affyMap{$id}})
				{
					my $gene_item = $item_doc->add_item('Gene', 
													primaryIdentifier =>$$affyMap{$id},
													organism => $org_item);
					$gene_items{$$affyMap{$id}} = $gene_item;
				}

				push(@genes, $gene_items{$$affyMap{$id}});
			}
			
			if($$ensemblMap{$id})
			{
				unless($gene_items{$$ensemblMap{$id}})
				{
					my $gene_item = $item_doc->add_item('Gene', 
													primaryIdentifier =>$$ensemblMap{$id},
													organism => $org_item);
					$gene_items{$$ensemblMap{$id}} = $gene_item;
				}

				push(@genes, $gene_items{$$ensemblMap{$id}});
			}
			$affy_attr{genes} = \@genes;
		}
		
		my $probe_item = $item_doc->add_item(Probe => %affy_attr);
		$item_doc->add_item('Sequence', residues => $affy_info{Probe_Sequence},
											probe => $probe_item);
		
	}#end while
	
	close $IN;
}
$item_doc->close();

### Subroutines ###


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

sub printHelp
{
	print <<HELP
perl rat-affy-to-xml.pl

Arguments
model	Path to model XML
input	Path to input dir
genes	Path to gene mapping dir
output	Path to output XML file
help	Print this message
HELP
}