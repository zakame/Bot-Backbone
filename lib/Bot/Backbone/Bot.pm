package Bot::Backbone::Bot;
use v5.10;
use Moose;

has services => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        add_service   => 'push',
        list_services => 'elements',
    },
);

sub construct_services {
    my $self = shift;

    my $my_name = $self->meta->name;

    for my $name ($self->meta->list_services) {
        my $service_config = $self->meta->services->{$name};

        my $class_name = $service_config->{service};
        if ($class_name =~ s/^\.//) {
            $class_name = join '::', $my_name, 'Service', $class_name;
        }
        elsif ($class_name =~ s/^=//) {
            # do nothing, we now have the exact name
        }
        else {
            $class_name = join '::', 'Bot::Backbone::Service', $class_name;
        }

        Class::MOP::load_class($class_name);
        my $service = $class_name->new(
            %$service_config,
            name => $name,
            bot  => $self,
        );

        $self->add_service($service);
    }
}

sub run {
    my $self = shift;

    $self->construct_services;
    $_->initialize for ($self->list_services);
}

__PACKAGE__->meta->make_immutable;
