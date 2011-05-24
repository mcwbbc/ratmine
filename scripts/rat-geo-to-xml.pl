#!/usr/bin/perl
# rat-geo-to-xml.pl
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
use XML::XPath;
use LWP::UserAgent;


#arguments
my ($model_file, $input_directory, $output);
#flags
my ($help, $vf);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'help' => \$help,
			'verbose' => \$vf);


#URL for initial UIDs
my $dataseturl = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=rattus[organism]&retmax=4';

my $geoXML = downloadData($dataseturl, $vf);

my $geoIds = parseIds($geoXML);
print "@$geoIds";

###subroutintes

sub downloadData
{
	my ($remoteFile, $verbose) = @_;

	my $ua = LWP::UserAgent->new;
	my $res = $ua->get($remoteFile);
	if($verbose)
	{	
		$res->is_success ?
			print "$remoteFile downloaded\n" :
			print $res->status_line . "\n";
	}
	return $res->content;
}

sub parseIds
{
	my $xml = shift;
	
	my $xp = XML::XPath->new(xml => $xml);
	my $nodeset = $xp->find('/eSearchResult/IdList/Id');
	
	my @ids;
	foreach my $node ($nodeset->get_nodelist)
	{
		push(@ids, $node->string_value)
	}
	return \@ids;
}

