#!/usr/bin/perl -w
use strict;

#  Anyone downloading it this soon is bound to be an experimentalist .....
#  Julie Kirsty Louise Montoya, 2015

=head1 NAME

    JKLMwiringPi -- A Perl module for the Raspberry Pi, providing a Perl-style
    interface to the GPIO, wrapping around the popular WiringPi library.

=head1 SYNOPSIS

    use JKLMwiringPi;
    my $gpio = JKLMwiringPi->setup      or die "Nadgers!";
    $gpio->pin_mode(0 => "out", 8 => "in");
    my $led = 1;
    while ($gpio->digital_read(8)) {
        $gpio->digital_write(0 => $led)->ms_delay(500);
        $led = 1 - $led;
    };

=cut

=head1 DESCRIPTION

This module is intended to provide a "more Perl-like" interface to the GPIO
pins of the Raspberry Pi.

=head2 METHODS

   Note: I've made heavy use of => throughout, but a comma also works.

   "Asking" methods return the answer asked for  (scalar or list).
   "Telling" methods return the object itself, for concatenation.

=cut

package JKLMwiringPi;
use strict;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/setup pin_mode ms_delay digital_read digital_write/;

#  We use Inline::C to wrap  (some of)  Gordon's functions as though they were
#  Perl functions .....

use Inline C => Config =>
    ENABLE => AUTOWRAP =>
    LIBS => "-lwiringPi ";

use Inline C => <<"--END-C--";
    int  wiringPiSetup() ;
    void pinMode(int pin, int mode) ;
    int  digitalRead(int pin) ;
    void digitalWrite(int pin, int value) ;
    void delay(unsigned int howLong);
--END-C--

#  .....  But they still use ugly C calling conventions.  So next, we define
#  some methods for accessing the GPIO object in a more "Perl-like" fashion,
#  hiding all the C-ugliness away in this module ;)

=over 12

=item C<setup>
Initialises the GPIO and returns a new gpio object, or undef if unsuccessful.

=back

    my $gpio = JKLMwiringPi->setup();
=cut

sub setup {
    my $proto = shift;                          #  MAGIC - DO NOT TRY TO UNDERSTAND THIS
    my $class = ref($proto) || $proto;          #  MAGIC - DO NOT TRY TO UNDERSTAND THIS
    my $self = undef;
    
    my $success = wiringPiSetup;
    if ($success >= 0) {
        $self = {"success" => $success};
        bless $self, $class;                    #  MAGIC - DO NOT TRY TO UNDERSTAND THIS
        return $self;
    };
    return undef;
};

=over 12

=item C<pin_mode>
-- Sets one or several GPIO pins as either inputs or outputs.

=back

   $gpio->pin_mode($pin => $direction [,$pin1 => $direction1 .....]);
   $direction may be "0", "in" or "IN"; or "1", "out" or "OUT".

=cut

sub pin_mode {
    my $self = shift;
    return undef unless $self;
    my ($pin, $mode, $mode1);
    while (@_ > 1) {
        $pin = shift;
        $mode = shift;
        $mode1 = 0;
        if ($mode =~ /[1oO]/) {
            $mode1 = 1;
        };
        pinMode $pin + 0, $mode1;
    };
    return $self;
};

=over 12

=item C<ms_delay>
-- Waits for a specified time in milliseconds.

=back

   $gpio->ms_delay($duration);
   (name clash; the underlying C function was already called "delay".)

=cut

sub ms_delay {
    my $self = shift;
    return undef unless $self;
    my $ms = shift;
    delay $ms + 0;
    return $self;
};

=over 12

=item C<digital_read>
-- Reads one or more digital I/O pins.

=back

   $state = $gpio->digital_read($pin);
   @state = $gpio->digital_read($pin, $pin1, $pin2 ..... );
   "1" means the pin is at +3.3 V, "0" means 0V.
   If called in a list context, returns a list.

=cut

sub digital_read {
    my $self = shift;
    return undef unless $self;
    my @ans = ();
    foreach (@_) {
        push @ans, digitalRead($_ + 0);
    };
    return wantarray ? @ans : $ans[0];
};

=over 12

=item C<digital_write>
-- Writes one or more digital I/O pins.

=back

   $gpio->digital_write($pin => $state [, $pin1 => $state1 ..... ]);
   $state may be "0", "off" or "OFF"; or "1", "on" or ON".
   
=cut

sub digital_write {
    my $self = shift;
    return undef unless $self;
    my ($pin, $state, $state1);
    while (@_ > 1) {
        $pin = shift;
        $state = shift;
        $state1 = 0;
        if ($state =~ /[1nN]/) {
            $state1 = 1;
        };
        digitalWrite $pin + 0, $state1;
    };
    return $self;
};

=over 12

=item C<write_vector>
-- Writes several digital I/O pins at once, according to a bit vector.

=back

   $gpio->write_vector($value => $units_pin, $twos_pin, $fours_pin .....)
   Treats $value as a binary number  (bit vector)  and writes its bits to
   several GPIO pins at once.  Pins are specified in order from LSB to MSB.

=cut

sub write_vector {
    my $self = shift;
    my $vector = shift;
    $vector += 0;
    my $bit_value = 1;
    my ($state, $pin);
    
    foreach $pin(@_) {
       if ($vector & $bit_value) {
           $state = 1;
       }
       else {
           $state = 0;
       };
       digitalWrite $pin, $state;
       $bit_value *= 2;
    };
    return $self;
};

=head1 LICENCE

This module is licenced under the Lesser GPL, version 3.
Perl is an interpreted language, so you are already distributing the Source
Code anyway  :)

=head1 AUTHOR

Julie Kirsty Louise Montoya L<mailto:bluerizlagirl@gmail.com>

=cut

1;                                      #  MAGIC - DO NOT TRY TO UNDERSTAND THIS
