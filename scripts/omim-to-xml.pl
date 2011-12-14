#!/usr/bin/perl
###################
# omim-to-xml.pl
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
use List::MoreUtils qw/zip/;


my ($model_file, $omim_text, $output_xml, $help);

GetOptions(
	'model=s' => \$model_file,
	'omim_text=s' => \$omim_text,
	'omim_xml=s' => \$output_xml,
	'help' => \$help);
	
if($help or !$model_file)
{
	printHelp();
	exit(0);
}

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_xml, auto_write => 1);
my %methods;
my %disorder_items;

open(my $IN, '<', $omim_text);

my $text;
while(<$IN>)
{
	if(/\*RECORD\*/)
	{
		my %omim_attr;
		if($text =~ /\*FIELD\* NO\s(\d{6})/)
		{
			$omim_attr{primaryIdentifier} = $1;
			$text =~ /\*FIELD\* TI\s[\d\D]?\d{6} ([\d\D]+?)\s[\*;]/;
			$omim_attr{title} = $1;
			$omim_attr{title} =~ s/[\n\r]/ /;

			$item_doc->add_item(OMIM => %omim_attr);
		}
		$text = '';
	}
	$text .= $_;
} #end while
close $IN;

$item_doc->close;

### subroutines ###

sub printHelp
{
	
}