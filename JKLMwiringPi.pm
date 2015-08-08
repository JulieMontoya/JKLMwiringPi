#!/usr/bin/perl -w
use strict;

#  I'll make these comments into proper POD later
#  It's more important to get the code up there *right now*, it can always
#  be tidied up later.  Besides, anyone downloading it this soon is bound to
#  be an experimentalist .....  Julie Kirsty Louise Montoya, 2015

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
#
#  ASKING methods return the answer asked for  (scalar or list).
#  TELLING methods return the object itself, for concatenation.
#
#  Note I've made heavy use of => throughout, but a comma also works.

#  my $gpio = JKLMwiringPi->setup() or die "Could not initialise GPIO!";

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

#  $gpio->pin_mode($pin => $direction [,$pin1 => $direction1 .....]);
#  $direction may be "0", "in", "IN", "1", "out" or OUT"

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

#  $gpio->ms_delay($duration);
#  (name clash; the underlying C function was already called "delay".)

sub ms_delay {
    my $self = shift;
    return undef unless $self;
    my $ms = shift;
    delay $ms + 0;
    return $self;
};

#  $state = $gpio->digital_read($pin);
#  @state = $gpio->digital_read($pin, $pin1, $pin2 ..... );
#  "1" means the pin is at +3.3 V, "0" means 0V.

sub digital_read {
    my $self = shift;
    return undef unless $self;
    my @ans = ();
    foreach (@_) {
        push @ans, digitalRead($_ + 0);
    };
    return wantarray ? @ans : $ans[0];
};

#  $gpio->digital_write($pin => $state [, $pin1 => $state1 ..... ]);
#  $state may be "0", "off", "OFF", "1", "on" or ON"

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

#  $gpio->write_vector($value => $units_pin, $twos_pin, $fours_pin .....)
#  Treats $value as a binary number  (bit vector)  and writes its bits to
#  several GPIO pins at once.  Pins are specified in order from LSB to MSB.

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

1;                                      #  MAGIC - DO NOT TRY TO UNDERSTAND THIS
        
