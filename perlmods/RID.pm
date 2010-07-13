package RID;

use strict;

#Ratmine ID Resolver
sub new
{
	my $class = shift;
	my $file = shift;
	my $self = {};

	if($file)
	{
		$self->{'_FILE'} = $file;
		open(IN, $file);
		while(<IN>)
		{
			next if $_ !~/^\d/; #ignore header line
			my $line = $_;
			chomp($line);
			my($rgd, $ens) = split("\t", $line);
			$self->{'_RGD'}->{$rgd}->$ens;
			$self->{'_ENSEMBL'}->{$ens}->$rgd;
		}#while
	}#if $file	

	bless $self, $class;
	return $self;
}#new

sub rgd2ensembl
{
	my ($self, $rgd) = @_;
	my $e = $self->resolveID('rgd', $rgd);
	return $e;
}

sub ensembl2rgd
{
	my ($self, $ens) = @_;
	my $r = $self->resolveID('ensembl', $ens);
	return $r;	
}

sub resolveID
{
	my ($self, $type, $id) = @_;
	
	my $k;
	if($type eq 'rgd')
	{	$k = '_RGD';	}
	elsif($type eq 'ensembl')
	{	$k = '_ENSEMBL';	}
	else
	{	return nil;	}
	
	return $self->{$k}->{$id};
}
1;
