use strict;
use warnings;

package Moose::Micro;

use Moose ();
use Moose::Exporter;

my ($import, $unimport);
BEGIN {
  ($import, $unimport) = Moose::Exporter->build_import_methods(
    also => 'Moose',
  );
}

sub import {
  my $class = shift;
  my $attributes = shift;

  my $caller = caller;

  my $meta = Moose::Meta::Class->initialize($caller);
  $meta->add_attribute(@$_) for $class->attribute_list($attributes);

  unshift @_, $class;
  goto &$import;
}

sub unimport { goto &$unimport }

sub attribute_list {
  my ($self, $attributes) = @_;
  my $required = 1;

  my @attributes;

  for my $attr (split /\s+/, $attributes) {
    my ($name, %args) = $self->attribute_args($attr);
    $args{required} = $required;
    $required = 0 if $name =~ s/;$//;
    push @attributes, [ $name, %args ];
  }

  return @attributes;
}

sub attribute_args {
  my ($self, $attribute) = @_;

  my %args = (
    is => 'rw',
  );

  if ($attribute =~ s/^([\$\@\%])//) {
    my $type = $1;
    %args = (%args, $self->type_constraint_for($type));
  }

  if ($attribute =~ s/^\!//) {
    %args = (%args, accessor => "_$attribute");
  }

  # TODO: check for _build_$attribute and assume lazy_build

  return ($attribute => %args);
}

my %TC = (
  '$' => 'Value|ScalarRef|CodeRef|RegexpRef|GlobRef|Object',
  '@' => 'ArrayRef',
  '%' => 'HashRef',
);

sub type_constraint_for {
  my ($self, $sigil) = @_;

  return (isa => $TC{$sigil});
}

1;
