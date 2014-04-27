package Bot::Backbone::Service::Role::Chat;
use v5.10;
use Moose::Role;

with 'Bot::Backbone::Service::Role::SendPolicy';

use Bot::Backbone::SendPolicy::Aggregate;

# ABSTRACT: Chat services must implement this role

=head1 DESCRIPTION

A chat service is one that sends and receives messages to other entities.

See L<Bot::Backbone::Service::ConsoleChat> and
L<Bot::Backbone::Service::JabberChat>.

=head1 ATTRIBUTES

=head2 chat_consumers

This is a list of L<Bot::Backbone::Service::Role::ChatConsumer>s that have registered to
receive messages from this chat service. A chat consumer is registered using the
C<register_chat_cnosumer> method. A C<list_chat_consumers> method is provided to
list the registered consumers.

=cut

has chat_consumers => (
    is          => 'ro',
    isa         => 'ArrayRef', # 'ArrayRef[DOES Bot::Backbone::Service::Role::ChatConsumer]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        register_chat_consumer => 'push',
        list_chat_consumers    => 'elements',
    },
);

=head1 REQUIRED METHODS

=head2 send_message

  # Send a direct message
  $chat->send_message({
      to          => $to_username,
      text        => 'blah blah blah',
  });

  # Send a group message
  $chat->send_message({
      group       => $to_group,
      text        => 'blah blah blah',
  });

Sends a message to a group or individual using this chat service. This is used
when the message is not being made as a direct reply to a message received from
the chat service.

If both C<group> and C<to> are passed, the preference should be to send to the C<group>.

This role also provides a wrapper around your chat's implementation of
C<send_message>, which will apply the current service's send policy to the
message. The most restrictive send policy encountered at any point will win. 

A send policy may be explicitly provided by setting the C<send_policy> setting
in the parameters to a L<Bot::Backbone::SendPolicy> object. Missing this
parameter will result in an error. The C<send_policy_result> may also be set to
reflect the most restrictive send policy result encountered so far.

=head1 METHODS

=head2 send_reply

  $chat->send_reply($message, \%options);

Given a message generated by this chat service, this should send a reply to the
origin of the message, whether that be a group or individual or other entity.

The second argument is a hash reference of options, which is used to modify the
reply further. See L</send_message> for additional options and be aware that
individual chat implementations may provide more options in addition to those
shown here.

=cut

sub send_reply {
    my ($self, $message, $options) = @_;

    $self->send_message({
        group => $message->group,
        to    => $message->from->username,
        %$options,
    });
}

=head2 resend_message

  $chat->resend_message($message);

This should be called whenever a message is received from the chat service. This
message willb e forwarded to all of the registered L</chat_consumers>.

=cut

sub resend_message {
    my ($self, $message) = @_;

    for my $consumer ($self->list_chat_consumers) {
        $consumer->receive_message($message);
    }
}

1;
