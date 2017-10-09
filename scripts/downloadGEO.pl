#!/usr/bin/perl
# geo-platform-to-xml.pl
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki

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
use GEOSOFT;

#arguments
my ($input_directory, $output);
#flags
my ($help, $vf, $df);

GetOptions( 'input=s' => \$input_directory,
                        'download' => \$df,
                        'help' => \$help,
                        'verbose' => \$vf);

if( $help || !$df )
{
        printHelp();
	die;
}

if ($df) {
        downloadGEO($input_directory, $vf);
}



###subroutintes

sub printHelp
{
        print <<HELP;
downloadGEO.pl --input path_to_input_directory --download

Arguments:
input   input directory
download tag to download files. 

Flags:
series  use if processing GEO series records
help    prints this message

HELP
}


sub downloadGEO
{
        my ($targetDir, $verbose) = @_;
        print "getting count..\n" if $verbose;
	my $count = getCountFromGEO();

        print "getting uids..\n" if $verbose;
	$count ? my $uids = getUIDs($count) : die 'error getting count';
	
	print "getting GEOIds .. \n" if $verbose;
        $uids ? my $gpls = getGEOids($uids) : die 'error getting uids';
        
	print join("\n", @{$gpls}) if $verbose;

	print "downloading records..\n" if $verbose;
        downloadRecords($gpls, $targetDir);
}

sub getCountFromGEO
{
        my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GPL[ETYP]+AND+rattus+norvegicus[ORGN]&rettype=count';
        my $r = downloadData($q);
        my $c = $1 if $r =~ /<count>(\d+)</i;
        return $c;
}

sub getUIDs
{
        my $count = shift;
        my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GPL[ETYP]+AND+rattus+norvegicus[ORGN]&RetMax=' . $count;
        my $r = downloadData($q);
        my @uids;
        my $xp = XML::XPath->new(xml => $r);
        my $nodeset = $xp->find('//eSearchResult/IdList/Id');
        foreach my $node ($nodeset->get_nodelist) {
                push(@uids, $node->string_value);
        }
        return \@uids;
}

sub getGEOids
{
        my $uids = shift;
	print join(',',@$uids);
        my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gds&report=brief&id=' . join(',', @$uids);
        my $r = downloadData($q);
	print "before pattern match\n$r\n";
        my @GEOids;
        while ($r =~ /Accession\:\s(\w+)/g) {
		print "\n downloading text:\n$r\n";
		print "geoId:$1\n";
                push @GEOids, $1;
        }
        return \@GEOids;
}


sub downloadRecords
{
        my ($ids, $t_dir) = @_;
	print "target directory..$t_dir\n";
        foreach my $id (@$ids) {
		print "geoId to be downloaded:$id\n";
                my $file = $id . '.annot.gz';
                my $q = 'ftp://ftp.ncbi.nih.gov/pub/geo/DATA/annotation/platforms/' . $file;
                my $r = downloadData($q);
                if ($r) {
                        open(my $OUT, '>', "$t_dir/$file") or die "cannot open $t_dir/$file";
                        binmode $OUT;
                        print $OUT $r;
                        close $OUT;
                        `gzip -d "$t_dir/$file"`;
                }
        }
}

sub downloadData
{
        my ($remoteFile, $verbose) = @_;
	print "downloading data....$remoteFile\n" if $verbose;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get($remoteFile);
        if($verbose)
        {
                $res->is_success ?
                        print "$remoteFile downloaded\n" :
                        print $res->status_line . " something went wrong..\n";
        }
        $res->is_success ?
                return $res->content :
                return "count=0 something went wrong";
}


