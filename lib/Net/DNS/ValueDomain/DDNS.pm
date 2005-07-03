package Net::DNS::ValueDomain::DDNS;

use strict;
use LWP::UserAgent;
use vars qw/$use_https/;

our $VERSION = '0.01';

use constant URL => 'dyn.value-domain.com/cgi-bin/dyn.fcg';
use constant SSL_PREFIX => 'ss1.xrea.com';

sub new {
    my $class = shift;
    my $args = shift;

    my $self = bless {}, $class;

    $self->_set($args) if ref $args eq 'HASH';

    eval "use Crypt::SSLeay";
    $use_https++ unless $@;

    $self->{_ua} = LWP::UserAgent->new;

    $self;
}

sub _set {
    my $self = shift;
    my $args = shift;

    return unless ref $args eq 'HASH';

    map { $self->{_arguments}->{$_} = $args->{$_} } keys %$args;
}

sub error {
    my $self = shift;
    my $error = shift;

    if ($error) {
	$self->{_error} = $error;
	$self->{_error} .= "\n" unless $self->{_error} =~ /\n$/;
	return 1;
    }

    return $self->{_error};
}

sub protocol {
    my $self = shift;

    return ($use_https) ? 'https' : 'http';
}

sub update {
    my $self = shift;
    my $args = shift;

    delete $self->{_arguments}->{domain};
    delete $self->{_arguments}->{host};
    $self->_set($args);

    die 'domain required' unless $self->{_arguments}->{domain};
    die 'password required' unless $self->{_arguments}->{password};
    
    my $ua = $self->{_ua};
    my $url = ($use_https) ? 'https://'.SSL_PREFIX.'/'.URL : 'http://'.URL;

    my $query = "?d=$self->{_arguments}->{domain}&$self->{_arguments}->{password}";
    $query .= "&h=$self->{_arguments}->{host}" if $self->{_arguments}->{host};
    $query .= "&i=$self->{_arguments}->{ip}" if $self->{_arguments}->{ip};
    
    my $res = $ua->request(HTTP::Request->new(GET => $url.$query));

    unless ($res->is_success) {
	$self->error($res->status_line);
	return;
    }
    
    unless($res->content =~ /status=0/) {
	my @contents = split /\r?\n/, $res->content;
	$self->error($contents[1]);
	return;
    }

    1;
}
    
1;
__END__

=head1 NAME

Net::DNS::ValueDomain::DDNS - Update your Value-Domain (https://www.value-domain.com/) DynamicDNS records.

=head1 SYNOPSIS

  use Net::DNS::ValueDomain::DDNS;
  
  my $ddns = Net::DNS::ValueDomain::DDNS->new;
  $ddns->update({
    domain => 'example.com',
    password => 'your password',
    host => 'www',
    ip => 'your ip',
  });
  $ddns->update({ domain => 'example.net', host => 'example' });


=head1 DESCRIPTION

This module help you to update your Value-Domain (https://www.value-domain.com/) DynamicDNS record(s).

=head1 METHODS

=item new(\%pamam)

Create a new Object. All \%param keys and values (except 'host' and 'domain') is kept in this object, and used by update() function.

=item update(\%param)

update your DynamicDNS record. \%param is:

=over 8

C<domain> - Your Domain name being updated. (Required)

C<password> - Your Value-Domain Dynamic DNS Password. (Required)

C<host> - Your Sub-domain name being updated. For example if your hostname is "www.example.com" you should set "www" here. (Optional)

C<ip> - The IP address to be updated. if empty, your current ip is used. (Optional)

=back

Return undef, if something error has occered. Use error() method for detail.

=item protocol()

return used protocol name. 'http' or 'https'.

=item error()

return last error.

=head1 AUTHOR

Daisuke Murase, E<lt>typester@unknownplace.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Daisuke Murase

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
