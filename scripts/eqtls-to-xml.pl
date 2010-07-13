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

my ($model_file, $eqtls_file, $eqtl_xml, $help) = (undef, undef, undef, undef, undef);

GetOptions(
	'model=s' => \$model_file,
	'qtl_input=s' => \$eqtls_file,
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

my $lab_item = $item_factory->make_item('Lab');
$lab_item->set('surname', 'Aitman');

open(IN, $eqtls_file) or die "cannot open $eqtls_file";

my $line = <IN>;
my %index = &RCM::parseHeader($line);

$writer->endTag("items");
### Subroutines ###

sub printHelp
{
	print <<HELP;
	help message
HELP
}