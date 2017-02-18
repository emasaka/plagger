package Plagger::Plugin::Filter::ExtractDate;
use strict;
use base qw( Plagger::Plugin );
use Encode;
use Plagger::Date;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup'  => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    for my $entry ($args->{feed}->entries) {
        $self->extract($entry);
    }
}

sub extract {
    my($self, $stuff) = @_;

    return if $stuff->date || !$stuff->body;

    my $datestr = $stuff->body;

    if ($self->conf->{dwim}) {
        if (my $date = Plagger::Date->parse_dwim($datestr)) {
            $stuff->date($date);
            Plagger->context->log(info => "Date '$datestr' is extracted and set");
        }
    } else {
        if (my $re = $self->conf->{extract_date}) {
            $datestr =~ m/$re/ or return;
            $datestr = $&;
        }

        my $format = $self->conf->{extract_date_format} or return;
        if (ref $format ne 'ARRAY') {
            $format = [ $format ];
        }
        my $date = (map { Plagger::Date->strptime($_, $datestr) } @$format)[0];
        if ($date) {
            if ($self->conf->{extract_date_timezone}) {
                $date->set_time_zone($self->conf->{extract_date_timezone});
            }
            $stuff->date($date);
            Plagger->context->log(info => "Date '$datestr' is extracted and set");
        }
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::ExtractDate - Extracts date from feed body

=head1 SYNOPSIS

  - module: Filter::ExtractDate
    config:
      extract_date: created .*$
      extract_date_format: created %a, %d %b %Y %T %z
      extract_date_timezone: Asia/Tokyo
      dwim: 0

=head1 DESCRIPTION

This plugin extracts date from feed body by regexp (if no date is given).

When dwim is true, it extracs date by Plagger::Date::parse_dwim.

=head1 CONFIG

=over 4

=item extract_date

Regexp of date string.

=item extract_date_format

strptime format of the string extracted by extract_date

=item extract_date_timezone

Time zone (optional)

=item dwim

When this is true, extract dates by Plagger::Date::parse_dwim.
Default to undef.

=back

=head1 AUTHOR

Masakazu Takahashi

=head1 SEE ALSO

L<Plagger>

=cut
