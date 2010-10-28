#!/usr/bin/perl
# rgd-to-pharmgkb.pl
# by Andrew Vallejos

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

my ($ortho_file, $pharm_file, $help, $out_file, $model_file);
my $t = 0;

GetOptions( 'model=s' => \$model_file,
			'orthologue_file=s' => \$ortho_file,
			'pharmGKB_file=s' => \$pharm_file,
			'output_file=s' => \$out_file,
			'help' => \$help);

if($help or !($ortho_file and $pharm_file))
{
	&printHelp;
	exit(0);
}

# Begin with setting up the environment
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $out_file, auto_write => 1);

my $taxon_id = '10116';
my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

#build rgd to human index
open(my $RGD, '<', $ortho_file) or die("cannot open $ortho_file\n");
my $index;
my %rgd_mapping;

#build RGD to Human Orthologue Index
print "Reading Orthologue File...\n";
while(<$RGD>)
{
	next if /^#/;
	chomp;
	if(/^RAT/)
	{
		$index = RCM::parseHeader($_);
		next;
	}
	my @fields = split(/\t/);
   	my %line = zip(@$index, @fields);

	my $rgd_id = $line{RAT_GENE_RGD_ID};
	my $gene_id = $line{HUMAN_ORTHOLOG_ENTREZ};
	my $symbol = $line{RAT_GENE_SYMBOL};
	foreach my $g (split(/\|/, $gene_id)) {
		$rgd_mapping{$g}{id} = $rgd_id;
		$rgd_mapping{$g}{symbol} = $symbol;
	}

}#end while <RGD>
close $RGD;

print "Closing Orthologue File...\nOpening Pharm File...\n";

open(my $PKB, '<', $pharm_file);
my %pharm_items;
my %rgd_flags;
while(<$PKB>)
{
	chomp;
	if(/^Pharm/)
	{
		$index = RCM::parseHeader($_);
		next;
	}

	my @fields = split(/\t/);
   	my %line = zip(@$index, @fields);

	my $pharm_id = $line{'PharmGKB Accession Id'};
	my $gene_id = $line{'Entrez Id'};
	unless (exists($rgd_flags{ $rgd_mapping{$gene_id}{id} }))
	{
		if($rgd_mapping{$gene_id}{id})
		{
			#push(@{$rgd_mapping{$gene_id}{pharmids}}, $pharm_id);
			my $gene_item = $item_doc->add_item('Gene', primaryIdentifier => $rgd_mapping{$gene_id}{id},
															pharmGKBidentifier => $pharm_id,
															organism => $org_item);
			$rgd_flags{ $rgd_mapping{$gene_id}{id} } = 'true';
			#print !exists($rgd_mapping{$gene_id}{flag}) ."\n"; exit(0);
		}
	}
	#print "$pharm_id\t$gene_id\t$rgd_mapping{$gene_id}{id}\t$rgd_mapping{$gene_id}{symbol}\n";

}#end while <PKB>

=cut

foreach my $gid (keys %rgd_mapping)
{
	if($rgd_mapping{$gid}{id})
	{
		#print "$pid\n";
		#$t++;
		my $gene_item = $item_factory->make_item('Gene');
		$gene_item->set('primaryIdentifier', $rgd_mapping{$gid}{id});
		my @pharm_items;
		foreach my $pid (@{$rgd_mapping{$gid}{pharmids}})
		{
			if($pid)
			{
				my $pharm_item = $item_factory->make_item('PharmGKB');
				$pharm_item->set('primaryIdentifier', $pid);
				$pharm_item->set('gene', $gene_item);
				$pharm_item->as_xml($writer);
				push(@pharm_items, $pharm_item);
			}#unless
		}
		$gene_item->set('pharmgkbs', \@pharm_items);
		$gene_item->as_xml($writer);
		$gene_item->destroy;
	}#unless
} #foreach my $pid

=cut

#my @test = keys(%pharm_items);
#print @test . "\n";
#print $test[1] . "\n";
#print "$t\n";
#print "@{$pharm_items{$test[1]}} \n";
close $PKB;
print "Closing PharmFile...\n";
exit(0);

#####Subroutines########

sub printHelp
{
	print "help\n";
}#end printHelp

sub buildHeaderIndex
{
	my %index;
	my $header = shift;
	my $count = 0;
	foreach my $h (@$header) {
		$index{$h} = $count;
		$count++;
	}
	return %index;
}