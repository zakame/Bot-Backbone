package Bot::Backbone::Service::Role::BareMetalChat;

use v5.10;
use Moose::Role;

with 'Bot::Backbone::Service::Role::Chat';

# ABSTRACT: A chat service that is bolted on to bare metal

=head1 DESCRIPTION

This role is nearly identical to L<Bot::Backbone::Service::Role::Chat>, but is
used to mark a chat service as one that will perform the final sending of a
message to an external service (e.g., L<Bot::Backbone::Service::JabberChat> or
L<Bot::Backbone::Service::ConsoleChat>) rather than one that just does some
internal routing (e.g., L<Bot::Backbone::Service::GroupChat> or
L<Bot::Backbone::Service::DirectChat>).

=cut

has _message_queue => (
    is          => 'rw',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        '_enqueue_message'     => 'push',
        #'_empty_message_queue' => [ map => sub { undef $_ } ],
        '_empty_message_queue' => 'clear',
    },
);

after shutdown => sub {
    my $self = shift;
    for my $timer (@{ $self->_message_queue }) {
        undef $timer;
    }
    $self->_message_queue([]);
    #$self->_empty_message_queue;
};

1;
