package DateTime::Format::Human::Duration;

use warnings;
use strict;
require DateTime::Format::Human::Duration::Locale;

use version; our $VERSION = qv('0.0.1');

sub new {
    bless { 'locale_cache' => {} }, 'DateTime::Format::Human::Duration';  
}

sub format_duration_between {
    my ($span, $dt, $dtb, %args) = @_;
    my $dur = $dt - $dtb;

    if (!exists $args{'locale'}) {
        $args{'locale'} = $dt->{'locale'}{'id'};
    }
    
    return $span->format_duration($dur, %args);    
}

sub format_duration {
    my ($span, $duration, %args) = @_;

    my @raw = $duration->in_units( qw(years months weeks days hours minutes seconds nanoseconds) ); 
    my @n = map { abs($_) } @raw; # no negative numbers
    my $say = '';
    
    # $dta - $dtb:
    #   if dta < dtb means past -> future (Duration units will have negatives)
    #   else its either this absolute instant (no_time) or the past
    if ( grep { $_ < 0 } @raw ) {
        if ( exists $args{'future'} ) {
            $say = $args{'future'}    
        }        
    }
    else {
        if ( exists $args{'past'} ) {
            $say = $args{'past'}    
        }
    }
    
    ####
    ## this is essencially the hashref that is returned from DateTime::Format::Human::Duration::en::get_human_span_hashref() : #
    ####
    my $setup = {
        'no_oxford_comma' => 0,
        'no_time' => 'no time', # The wait will be $formatted_duration   
        'and'     => 'and',    
        'year'  => 'year',
        'years' => 'years',
        'month'  => 'month',
        'months' => 'months',
        'week'  => 'week',
        'weeks' => 'weeks',
        'day'  => 'day',
        'days' => 'days',
        'hour'  => 'hour',
        'hours' => 'hours',
        'minute'  => 'minute',
        'minutes' => 'minutes',
        'second'  => 'second',
        'seconds' => 'seconds',
        'nanosecond'  => 'nanosecond',
        'nanoseconds' => 'nanoseconds',        
    };

    my $locale = DateTime::Format::Human::Duration::Locale::calc_locale($span, $args{'locale'});
 
    if($locale) {
        if ( ref $locale eq 'HASH' ) {
            %{ $setup } = (
                %{ $setup },
                %{ $locale },
            );            
        }
        elsif ( ref $locale eq 'CODE') {
            return $locale->( @n, \%args );
        }
    }

    # this is what a locale's get_human_span_from_units_array() should do:
    # my (@n, $args_hr) = @_;

    # reorder @n use if appropriate for locale
    # @n has been pass through abs() so that its never negative
    my @parts = grep { $_ } (
        $n[0] ? ( $n[0]. ' ' . ($n[0] == 1 ? $setup->{'year'}   : $setup->{'years'})) : '',  
        $n[1] ? ( $n[1] . ' ' .($n[1] == 1 ? $setup->{'month'}  : $setup->{'months'})) : '',
        $n[2] ? ( $n[2] . ' ' .($n[2] == 1 ? $setup->{'week'}   : $setup->{'weeks'})) : '',
        $n[3] ? ( $n[3] . ' ' .($n[3] == 1 ? $setup->{'day'}    : $setup->{'days'})) : '',
        $n[4] ? ( $n[4] . ' ' .($n[4] == 1 ? $setup->{'hour'}   : $setup->{'hours'})) : '', 
        $n[5] ? ( $n[5] . ' ' .($n[5] == 1 ? $setup->{'minute'} : $setup->{'minutes'})) : '', 
        $n[6] ? ( $n[6] . ' ' .($n[6] == 1 ? $setup->{'second'} : $setup->{'seconds'})) : '',  
        $n[7] ? ( $n[7] . ' ' .($n[7] == 1 ? $setup->{'nanosecond'} : $setup->{'nanoseconds'})) : '',   
    );

    my $no_time = exists $args{'no_time'} ? $args{'no_time'} : $setup->{'no_time'};
    return $no_time if !@parts;

    my $last = @parts > 1 ? pop(@parts): '';

    ## We want to use the so-called Oxford comma to avoid ambiguity. 
    ## For that reason we make locale's specifically tell us they do not want it.
    my $string = $setup->{'no_oxford_comma'} 
        ? join(', ', @parts) . ($last ? " $setup->{'and'} $last" : '')
        : join(', ', @parts) . (@parts > 1  ? ',' : '') . ($last ? " $setup->{'and'} $last" : '')
        ;

    if ( $say ) {
       $string = $say =~ m{%s} ? sprintf($say, $string): "$say $string";    
    }

    return $string;
}

1; 

__END__

=head1 NAME

DateTime::Format::Human::Duration - Get a locale specific string describing the span of a given duration

=head1 VERSION

This document describes DateTime::Format::Human::Duration version 0.0.1

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Format::Human::Duration

    my $span = DateTime::Format::Human::Duration->new();
    my $dur = $dta - $dtb;
    print $span->format_duration($dur); # 1 year, 2 months, 3 minutes, and 1 second
  
    print $span->format_duration_between($dta, $dtb); # 1 year, 2 months, 3 minutes, and 1 second

=head1 DESCRIPTION

Get a localized string representing the duration.

For example:

    1 second
    2 minutes and 3 seconds
    3 weeks, 1 day, and 5 seconds
    4 years, 1 month, 2 days, 6 minutes, 1 second, and 345000028 nanoseconds

=head1 INTERFACE 

=head2 new()

Create span object, no args

=head2 format_duration()

First argument is a DateTime::Duration object

After that you can optionally pass some 'standard args' as a hash as described below

=head2 format_duration_between()

First two args are DateTime objects

After that you can optionally pass some 'standard args' as a hash as described below

=head2 standard args

=over 4

=item 1 'locale' 

locale of the $dt object will be used if you do not specify this

Valid values are a string of the locale (E.g 'fr'), a DateTime object, or a DateTime object's 'locale' key.

=item 2 since we're working with 2 datetime objects of known points we can have past and future tenses.

=over 4

=item * past

String to use if duration is past tense. Can have a sprintf '%s' or else is prepended with a trailing space.

=item * future

String to use if duration is future tense. Can have a sprintf '%s' or else is prepended with a trailing space.

=item * no_time 

Override the 'no_time' in the locale hash.

=back

If duration is baseless (IE ambiguouse) then 'past' and 'future' is used based on if $dur->in_units has negatives or not.

Also by nature it's not split into type groups:

An example is

  DateTime::Duration->new('seconds'=> 62)
  
Will result in '62 seconds' not '1 minute and 2 seconds'

For more sane results always be specific by using 2 datetime object to get a duration object

=back

    print $dt->format_duration_between(
        $dta,
        $dtb, 
        'past'   => 'Your account expired %s ago.', 
        'future' => 'Your account expires in %s.', 
        'no_time'=> 'Your account just expired.',
    );

This facilitates, for example, this L<Locale::Maketext> vernacular which becomes:

   'Your account [duration,_1,_2,expired %s ago,expires in,just expired].' => '[Votre compte [duration,_1,_2,a expiré il ya,expire dans,vient d'expirer].'

=head1 LOCALIZATION

Localization is provided by the included DateTime::Format::Human::Duration::Locale modules.

Included are DateTime::Format::Human::Duration::Locale::es, DateTime::Format::Human::Duration::Locale::fr, DateTime::Format::Human::Duration::Locale::pt

More will be included as time permits/folks volunteer/CLDR becomes an option

They are setup this way:

DateTime::Format::Human::Duration::Locale::XYZ where 'XYZ' is the ISO code of DateTime::Locale

It can have one of 2 functions used in this order:

=over 4

=item get_human_span_from_units_array()

Try to use get_human_span_hashref() if the locale is disposed to it since its much easier... That said:

Takes the arguments as described in the example below, should return the localized "span" string.

    sub get_human_span_from_units_array {
        my ($years, $months, $weeks, $days, $hours, $minutes, $seconds, $nanoseconds, $args_hr) = @_; # note: has no negative numbers
        ...
        return $string; # 1 year, 2days, 4 hours, and 17 minutes
    }

=item get_human_span_hashref()

Takes no arguments, should return a hashref of this structure:

    sub get_human_span_hashref {
        return {
            'no_oxford_comma' => 1,
            'no_time' => 'pas le temps',
            'and'     => 'et',    
            'year'  => 'an',
            'years' => 'ans',
            'month'  => 'mois',
            'months' => 'mois',
            'week'  => 'semaine',
            'weeks' => 'semaines',
            'day'  => 'jour',
            'days' => 'jours',
            'hour'  => 'heure',
            'hours' => 'heures',
            'minute'  => 'minute',
            'minutes' => 'minutes',
            'second'  => 'seconde',
            'seconds' => 'seconds',
            'nanosecond'  => 'nanoseconde',
            'nanoseconds' => 'nanosecondes',      
        };
    }

=back

=head1 LOCALIZATION of DateTime::Format modules

L<DateTime> does an excellent job at implementing localization. Often L<DateTime::Format> based class's either don't support localization or they implement it haphazardly and inconsistently.

With this module I hope to model a localization scheme that is inline with L<DateTime> and is consistent and reuseable between <DateTime::Format> based classes.

The idea is to determine the locale to use based on a DateTime object.

XYZ::Locale should handle looking up (and caching if appropriate) the locale and loading the necessary locale module XYZ::Locale::fr

The specific locale module holds the data and possibly logic neccesary to do what XYZ does in the vernacular of the given locale.

=head2 TODO 

Eventually the generic logic will be re-broken out into its own module for re-use by your class and I'll have more detailed POD about how to do it.

In the meantime if you're interested please contact me and I'd be happy to help and/or expediate this TODO.

Also, Dave Rolksy has mentioned to me that this sort of locale data might be appropriate for DateTime::Locale directly from CLDR. If that happens this module will be changed to use that if possible.

=head1 FAQ

=head2 Why would I want to use this?

So you can localize your application's output of time periods without having to do a lot of logic each time you wanted to say it.

L<Locale::Maketext::Utils> has/will have a duration() bracket notation method which prompted this module's existence

duration() was prompted by its datetime() brother, all of which uses the most excellent DateTime project!

=head2 Why did my duration say '62 seconds' instead of '1 minute and 2 seconds'

Because you used an ambiguous duration (one without a base) so there is no way to 
apply date math and accurately represent the number of each given item in that 
duration since it may or may not span leap-[second, days, years, etc..]

In other words do this (so that your duration can be specifically calculated):

    $dtb = $dta->clone->add('seconds'=> 62);
    my $duration = $dta - $dtb; # has a base, its not ambiguous
    print $span->format_duration($duration); # 1 minutes and 2 seconds

not this:

    my $duration = DateTime::Duration->new('seconds'=> 62); # no base, it is ambiguous
    print $span->format_duration($duration); # 62 seconds

Note L</format_duration_between>(), does not suffer from this since we're using a specific DateTime object already.

    print $span->format_duration_between( $dt, $dt->clone()->add('seconds'=> 62) ); # 1 minute and 2 seconds

=head2 Why do you put a comma before the 'and' in a group of more than 2 items?

We want to use the so-called Oxford comma to avoid ambiguity.

=head2 My DateTime::Format::Human::Duration::Locale::XX still outputs in English!

That is because it defined neither the get_human_span_hashref() or the get_human_span_from_units_array() functions

It must define one of them or defaults are used.

=head2 Why didn't you just use 'DateTime::Format::Duration'

Essencially DateTime::Format::Duration is an object representing a single strftime() type string to apply to any given duration. This is not flexible enough for the intent of this module.

DateTime::Format::Duration is not a bad module its just for a different purpose than DateTime::Format::Human::Duration

=over 4

=item * It was not localizable

You either got '2 days' or '1 days' which a) forces it to be in English and b) doesn't even make sense in English.

You could get around that by adding logic each time you wanted to call it but that is just messy.

=item * Had to keep an item even if it was zero

If 'days' was in there you got '0 days', we only want items with a value to show.

That'd also require a lot of logic each time you wanted to call which is again messy.

=item * This module has no need for reparsing output back into an object

Since the datetime info for 2 points in time are generally in a form easily rendered into a DateTime object it'd be silly to even attempt to store and parse the output of this module back into an object. 

Plus since it all depends on the locale it is in it'd be difficult.

=back

The purpose of DateTime::Format::Human::Duration was to generate a localized human language description of a duration without the caller needing to supply any logic.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own

=head1 CONFIGURATION AND ENVIRONMENT

DateTime::Format::Human::Duration requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-datetime-format-span@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
