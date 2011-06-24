#!/usr/bin/perl
# rat-geo-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use Switch;
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
my ($model_file, $input_file, $output);
#flags
my ($help, $vf);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_file,
			'output=s' => \$output,
			'help' => \$help,
			'verbose' => \$vf);


my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output, auto_write => 1);

#global hashes to track unique
my %rs_items;
my %ma_items;
my %cl_items;

my %gds_items;
my %gsm_items;
my %gse_items;

open(my $IN, '<', $input_file);

while(<$IN>)
{
	chomp;
	my($gd_id, $id) = split("\t");
	
	$id =~ /\|(\w{2}):\d+/;
	my $ont = $1;
	$id = $&;
	$id =~ s/\|//;
	
	print "$ont | $id\n";
	
	my $geo_item = findGEOItem($gd_id);
		
	if($ont eq 'MA')
	{
		my $ont_item = getMAItem($id);
		$item_doc->add_item('MAAnnotation', subjectDataSet => $geo_item, ontologyTerm => $ont_item);
	}
	elsif($ont eq 'CL')
	{
		my $ont_item = getCLItem($id);
		$item_doc->add_item('CLAnnotation', subjectDataSet => $geo_item, ontologyTerm => $ont_item);
	}
	elsif($ont eq 'RS')
	{
		my $ont_item = getRSItem($id);
		$item_doc->add_item('RSAnnotation', subjectDataSet => $geo_item, ontologyTerm => $ont_item);
	}
	
} #while

$item_doc->close;
exit(0);

###subroutintes

sub findGEOItem
{
	my $id = shift;
	
	my $class = $& if $id =~ /^\w{3}/;
	
	my $item;
	
	if($class eq 'GDS')
	{
		$item = getItem(\%gds_items, 'GEODataSet', $id);
	}
	elsif($class eq 'GSE')
	{
		$item = getItem(\%gse_items, 'GEOSeries', $id);
	}
	elsif($class eq 'GSM')
	{
		$item = getItem(\%gsm_items, 'GEOSample', $id);
	}
	else
	{	die("Unknown class: $class\n");	}
} #end findGEOItem

sub getItem
{
	my($items_ref, $class, $id) = @_;
	
	unless($items_ref->{$id})
	{
		my $item = $item_doc->add_item($class, name => $id);
		$items_ref->{$id} = $item;
	}
	
	return $items_ref->{$id};
}

sub getMAItem
{
	my $id = shift;
	unless($ma_items{$id})
	{
		my $item = $item_doc->add_item('MATerm', identifier => $id);
		$ma_items{$id} = $item;
	}
	return $ma_items{$id};
}

sub getCLItem
{
	my $id = shift;
	unless($cl_items{$id})
	{
		my $item = $item_doc->add_item('CLTerm', identifier => $id);
		$cl_items{$id} = $item;
	}
	return $cl_items{$id};	
}

sub getRSItem
{
	my $id = shift;
	unless($rs_items{$id})
	{
		my $item = $item_doc->add_item('RSTerm', identifier => $id);
		$rs_items{$id} = $item;
	}
	return $rs_items{$id};	
}