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
	&printHelp;
	exit(0);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_file, auto_write => 1);

my $taxon_id = '10116';

my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

#process Header

my $chrom_items;
$chrom_items = RCM::addRatChromosomes($item_doc, $org_item);

my %pubs;
print "Processing Data...\n";
open(my $IN, '<', $input_file) or die "cannot open $input_file\n";

my $index;
while(<$IN>)
{
	next if /^#/; #ignore comment lines
	chomp;
	if(/^\D/) #parses header line
	{
		$index = RCM::parseHeader($_);
		next
	}
  
	my @fields = split(/\t/);
   	my %data = zip(@$index, @fields);

	my %sslp_attr = ('organism' => $org_item,
						'primaryIdentifier' => $data{SSLP_RGD_ID},
						'symbol' => $data{SSLP_SYMBOL});
						
	$sslp_attr{expectedSize} = $data{EXPECTED_SIZE} if $data{EXPECTED_SIZE};
	
	if (my $ids = $data{CURATED_REF_PUBMED_ID}) 
	{
      	for my $id (split(/,/, $ids))
		{
			$pubs{$id} = $item_doc->add_item('Publication', pubMedId => $id) unless ($pubs{$id});
			push @{$sslp_attr{publications}}, $pubs{$id};
		}
	}

#	my $chrom = $chrom_items->{$data{CHROMOSOME}};
#	$sslp_attr{chromosome} = $chrom if $chrom;
	

	my $sslp_item = $item_doc->add_item(SimpleSequenceLengthVariation => %sslp_attr);

=cut
	if($data{CHROMOSOME} and $data{START_POS_3_4})
	{
		#print "\n$data{START_POS_3_4}\n";
		my @starts = split(';', $data{START_POS_3_4});
		my @stops = split(';', $data{STOP_POS_3_4});
		my @chroms = split(';', $data{CHROMOSOME_3_4});

		foreach my $start (@starts) {
			my $end = shift @stops;
			my $c = shift @chroms;
			$item_doc->add_item( 'Location',
									locatedOn => $chrom_items->{$c},
									start => $start,
									end => $end,
									feature => $sslp_item
									);
		}

	}
	
=cut

}#end while(<IN>)
close $IN;
$item_doc->close();

exit(0);

### Subroutines ###

sub printHelp
{
print<<HELP;
perl rgd-sslp-to-xml.pl

arguments:
model	model file
input	RGD flat file
output	XML output file
help	prints this message
			
HELP
}
