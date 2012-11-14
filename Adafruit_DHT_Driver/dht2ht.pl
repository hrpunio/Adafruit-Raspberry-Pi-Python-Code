#!/usr/bin/perl

use GD::Graph::lines;

#  Log file name:
my $DHTLog='DHT22.log';
#  It is assumed Log file has the following format (produced by dht2ht.sh):
#
#  @20121114160101
#  24=2 Using pin #24 Data (40): 0x2 0x2b 0x0 0xc6 0xf3 Temp =  19.8 *C, Hum = 55.5 % 
#  25=1 Using pin #25 Data (40): 0x3 0xde 0x0 0x2d 0xe Temp =  4.5 *C, Hum = 99.0 % 
#  22=1 Using pin #22 Data (40): 0x2 0xbe 0x0 0xaf 0x6f Temp =  17.5 *C, Hum = 70.2 % 
#
# Temperature chart name:
my $chart_t = "sensirion_t.png";
# Humidity chart name:
my $chart_h = "sensirion_h.png";
# HTML title/creator, etc:
my $HTML_creator = 'Tomasz Przechlewski';
my $HTML_title = 'Temperature/humidity measurement';
my $CSS_dir = "http://pinkaccordions.homelinux.org/style";
my $JS_dir = "http://pinkaccordions.homelinux.org/script";

# Sensor names:
my %SensorNames = ( '24' => 'Room', '22' => 'Porch', '25' => 'Garden');
# Sensors numbers:
my @Sensors = (24, 25, 22);
# Sensor colors at charts:
my @SensorColors = ( 'red', 'blue', 'green', 'magenta', 'orange' );

# How many readings to display?:
my $max_readings = 240 ;

## Reading the LOG file:

open (DHT, "$DHTLog") || die "cannot open $DHTLog\n";

while (<DHT>) {
  if (/@/) {
    $tempNo=0;
    ## seconds are thrown away:
    $date = substr($_, 1, 11) ;
  }
  else {
    $tempNo++;
    $_ =~ /\#([0-9][0-9]) /;
    $sensor_Id = $1;

    if ( $_ =~ /^[0-9]+=\?/) { 
      $temp = $hum = "x" ;
    } else {
      $_ =~ m/Temp\s+=\s+(\-?[0-9\.]+)/; $temp = $1;
      $_ =~ m/Hum\s+=\s+(\-?[0-9\.]+)/; $hum = $1;
      print STDERR "*** $date: t = $temp h = $hum ***\n";
    }

    $TempDHT{$date}{$sensor_Id} = "$temp" ;
    $HumDHT{$date}{$sensor_Id} = "$hum" ;

  }
} ## //while

close (DHT);

## Generating  HTML table:
## HTML header (possibly needs adoption)

print '<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="content-type" content="text/html; charset=utf-8" />';
print "<meta name='DC.date' content='2012-10-4T20:0:43CET'/>\n"
  . "<meta name='DC.creator' content='$HTML_creator' />\n"
  . "<meta name='DC.rights' content='(c) $HTML_creator'/>\n"
  . "<link rel='stylesheet' type='text/css' href='$CSS_dir/tp-base.css' title='ES'/>"
  . "<link rel='alternate stylesheet' type='text/css' href='$CSS_dir/tp-bw.css' title='NS'/>"
  . "<link rel='alternate stylesheet' type='text/css' href='$CSS_dir/tp-big.css' title='BS'/>"
  . "<script type='text/javascript' src='$JS_dir/tp.js'></script>\n";
print '<style type="text/css"> td { padding: 3px 9px 3px 9px ; text-align: right ; }
         table { font-family : sans-serif ; border: 1px dotted; }
         td.t_hdr { text-align: center } td.pv { background: #656dbc } td.qv { background: #656dbc }</style>';
print "<title xml:lang='pl'>$HTML_title</title>\n";
print "<meta name='DC.title' content='$HTML_title' /></head><body>\n";

print "<h3>$HTML_title</h3>\n";

print "<p>Temperature, humidity and <a href='http://en.wikipedia.org/wiki/Dew_point'>Dew
 point</a> measurement with
<a href='https://www.sparkfun.com/products/10167'>SparkFun's</a>? DHT-22 sensors.</p>
<p>Charts: <a href='./$chart_t'>Temperature</a>
 | <a href='./$chart_h'>Humidity</a></p>\n";

## Print table header
print "<table class='tr.comment'>\n";
print "<tr class='main'><td rowspan='2'>Date/Time</td>" ;

for $sens ( @Sensors ) {  print "<td colspan='3' class='t_hdr'>$SensorNames{$sens}</td>"; }

print  "</tr><tr class='main'>\n";

for $sens ( @Sensors ) {  print "<td>T °C</td><td>H °C</td><td>Dp °C</td>" }

print  "</tr>\n";

## Table body:
foreach $d (reverse sort keys %TempDHT) {
  $cdt = ${d} ; $cdt = substr($cdt, 0, 8) . "_" . substr($cdt, 8, 2) . ":" . substr($cdt, 10, 1) . "0";

   print "<tr><td>$cdt </td>";

   $row_txt =  "";

   push(@TempDates, $d);

   my $sr_temp = $sr_hum = $sr_n = 0;
   for $sens ( @Sensors ) {

      if (exists ($TempDHT{$d}{$sens})) {
	 $ct_ = $TempDHT{$d}{$sens} ; $ch_ = $HumDHT{$d}{$sens};
         $sr_temp += $ct_ ; $sr_hum += $ch_ ; $sr_n++;

	 if ($ch_ == 0) {## humidity is 0, ie. missing!
	   $dew_point = 0 ;
	 }
	 else { $dew_point = dewpoint_approximation($ct_, $ch_); }

         ## output
         $row_txt .= sprintf "<td> %.2f</td><td> %.2f</td><td> %.2f</td>", $ct_, $ch_, $dew_point ;

	 push( @{ $SDataT{$sens} }, $TempDHT{$d}{$sens} );
	 push( @{ $SDataH{$sens} }, $HumDHT{$d}{$sens} );
         push( @{ $SDataDewP{$sens} }, $dew_point);

      } else {
         $row_txt .= "<td> x </td><td> x </td><td> x </td>";

	 ### missing values denote as  `0'
	 push( @{ $SDataT{$sens} }, 0 );
	 push( @{ $SDataH{$sens} }, 0 );
         push( @{ $SDataDewP{$sens} }, 0);

      }
   }

  print "$row_txt</tr>\n";

  push (@DatyCzasy, substr($date, 0, 10)); # short form of date (for chart)

  $lineNo++;

  if ($lineNo > $max_readings ) { last ; }
}

## HTML footer (possibly needs adoption)

print "</table>\n";
print "<p>Number of readings: $lineNo</p>\n";

print "<p><a href='../index.html' class='bfooter' ><img longdesc='[[back.png'
src='/icons/back.png' alt='Back'/>Back</a></p>\n";

print "</body></html>\n";

### ### ### Charts:

my $lst_day = $DatyCzasy[$#DatyCzasy];
my $fst_day = $DatyCzasy[0];
my $BaselineKolor = 'black';
my $BaseLineStyle = 3; # dotted line
my $NormalLineStyle = 1;
my $chart_width = 820;
my $chart_height = 500 ;
my $long_ticks = 0 ;
my $xskip = 24 ;
my $x_label_txt = 'Time';

@TempDates = reverse(@TempDates);

# Temperature:

my @data = \@TempDates; ##

my @LineStyles = ( (1) x ($#Sensors + 1), (3) x ($#Sensors + 1));

##print STDERR "@LineStyles\n";

for $s ( @Sensors ) { @{$SDataT{$s}} = reverse @{$SDataT{$s}}; 
  push (@data, $SDataT{$s} );  }

## DewPoint:
for $s ( @Sensors ) { @{$SDataDewP{$s}} = reverse @{$SDataDewP{$s}}; 
  push (@data, $SDataDewP{$s} );  }

@Kolory = ( @SensorColors[0..$#Sensors], @SensorColors[0..$#Sensors] );

my @legend = ();

for $s ( @Sensors ) { push @legend, $SensorNames{$s} } 
## Add dew point to legend:
for $s ( @Sensors ) { push @legend, "$SensorNames{$s}/Dp" } 

draw_chart(\@data, \@legend, 40, -25, 13, $chart_t, "Temp/Dew point", "Temp. [C]" );

# Humidity:

my @data = \@TempDates;

## if my @LineStyles error, why?
@LineStyles = ((1) x ($#Sensors + 1));

for $s ( @Sensors ) { @{$SDataH{$s}} = reverse @{$SDataH{$s}};
    push (@data, $SDataH{$s} ); }

@Kolory = @SensorColors[0..$#Sensors];

my @legend = ();
for $s ( @Sensors ) { push @legend, $SensorNames{$s} } 

draw_chart(\@data, \@legend, 100, 0, 20, $chart_h, "Humidity", "Hum [%]" );

### ### ###
sub draw_chart {
  my $data_ref = shift ;    ## ref. to data
  my $legend_ref = shift ;  ## ref. to legend

  my $y_max_value = shift ; ## max Y value
  my $y_min_value = shift ; ## min Y value
  my $y_tick_number = shift ;

  my $chartname = shift;
  my $chart_title_name = shift;
  my $y_label_txt = shift;

  my @data = @$data_ref; # dereferencing ref to local @data ;
  my @legend_txt = @$legend_ref; # ditto

  # Add baseline if appropriate:
  if ($y_min_value < 0) {

    for ($i=0; $i<=$#TempDates; $i++) { push (@Zeros, 0) }

    push (@data, \@Zeros );
    push (@LineStyles, $BaseLineStyle);
    push (@Kolory, $BaselineKolor); ## Add baseline
  }

  my $mygraph = GD::Graph::lines->new($chart_width,  $chart_height);

  $mygraph->set_text_clr('black');
  $mygraph->set(
    x_label     => $x_label_txt,
    y_label     => $y_label_txt,
    title       => "$chart_title_name: $lst_day--$fst_day",
    long_ticks  => $long_ticks,  ### 1 or 0
    #
    # Draw datasets in 'solid', 'dashed' and 'dotted-dashed' lines
    # Style poszczególnych linii: [ostatnia jest kropkowana]:
    line_types  => \@LineStyles,
    # Set the thickness of line
    line_width  => 2,
    # ** Kolory poszczególnych linii: ***
    dclrs  => \@Kolory,
    # Opcja x_tick_number  generuje b³êdy:
    # Illegal division by zero at /usr/share/perl5/GD/Graph/axestype.pm line 1289, <> chunk 1.
    #x_tick_number => 16,
    #x_tick_number => 'auto',
    ##x_tick_offset => 144,
    ## Drukuje co _$xskip_ etykietê:
    x_label_skip => $xskip,
    ##y_label_skip => 5,
    ## ## ##
    y_tick_number => $y_tick_number,
    y_max_value => $y_max_value,
    y_min_value => $y_min_value,
    ## ## ##
    transparent => 0, ## non-transparent
    bgclr => 'white',
    fgclr => 'black',
    borderclrs => 'black',
    boxclr => '#ede7e7',
    labelclr => 'black',
    #axislabelclr,
    legendclr => 'black',
  ) or warn $mygraph->error;

  $mygraph->set_legend_font(GD::gdMediumBoldFont);

  $mygraph->set_legend( @legend_txt ) ;

  my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

  ## for cgi script uncomment below: ## ### ###
  ##print "Content-type: image/png\n\n";

  open ( IMG, ">$chartname") or die " *** Problems opening: $chartname ***" ;

  print IMG $myimage->png;

  close (IMG);

  return ;
} ## //draw_chart

sub dewpoint_approximation {

  ## ### ###
  # approximation valid for
  # 0 degC < T < 60 degC
  # 1% < RH < 100%
  # 0 degC < Td < 50 degC 
  ## ### ###
  ## cf also: http://www.decatur.de/javascript/dew/index.html
  ## ### ###

  my $T = shift ;  # Dry-bulb temperature C
  my $Hr = shift ; # Relative humidity

  my $a = 17.271 ;
  my $b = 237.7 ; # degC

  return ( ($b * gamma($T, $Hr, $a, $b)) / ($a - gamma($T, $Hr, $a, $b)) )
}##//dewpoint_approximation

## ### ###
sub gamma {
  my $x = shift ;
  my $h = shift ;

  my $a = shift ;
  my $b = shift ;

  return ( ($a * $x / ($b + $x)) + log ($h / 100.0) );
}##//gamma

## ### ###
