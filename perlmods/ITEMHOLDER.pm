package ITEMHOLDER;

use strict;


=head ITEMHOLDER.pm

An object that contains InterMine items and
ensures data constistancy within a source

written by Andrew Vallejos

=cut

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}


sub store
{
	my ($self, $name, $item) = @_;
	if ($name eq '' or $item eq '')
	{	return undef;	}
	$self->{$name} = $item;
}

sub get
{
	my ($self, $name) = @_;
	return $self->{$name};
}

sub holds
{
	my ($self, $name) = @_;
	
	if($name eq '')
	{ 	
		return 0;
	}
	elsif($self->{$name})
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub size
{
	my $self = shift;
	
	my $count = keys %$self;
	return $count;
	
}

1;