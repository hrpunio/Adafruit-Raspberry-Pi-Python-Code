#!/usr/bin/perl
##use POSIX qw(log10);
use GD::Graph::lines;

my $DHTLog="/home/pi/Logs/DHT/DHT22.log";
my %SensorNames = ("24" => 'Pokój', "25" => 'Weranda', "22" => 'Ogród');
my @Sensors = ("24", "25", "22"); ## ważna jest kolejność

open (DHT, "$DHTLog") || die "cannot open $DHTLog\n";

while (<DHT>) {
   if (/@/) {$tempNo=0;
	## wycinamy końcówkę (jezeli konczy się na zero to pełna godzina
	$date = substr($_, 1, 11) ; 
   }
   else {
	$tempNo++;
	$_ =~ /\#([0-9][0-9]) /; $sensor_Id = $1;

        if ( $_ =~ /^[0-9]+=\?/) { 
           $temp = $hum = "x" ; ##$TempDHT{$date}{$sensor_Id} = $HumDHT{$date}{$sensor_Id} = "x"
        } else {
           $_ =~ m/Temp\s+=\s+(\-?[0-9\.]+)/; $temp = $1; 
           $_ =~ m/Hum\s+=\s+(\-?[0-9\.]+)/; $hum = $1; 
 	   print STDERR "*** $date: t = $temp h = $hum ***\n";
        }

	if ($date =~ /0$/) { ## Pełna godzina
           $TempDHT{$date}{$sensor_Id} = "$temp" ;
           $HumDHT{$date}{$sensor_Id} = "$hum" ;

        }
   }
} ## //while

close (DHT);


print '<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="DC.date" content="2012-10-4T20:0:43CET"/>
<meta name="DC.creator" content="Tomasz Przechlewski" />
 <meta name="DC.rights" content="(c) Tomasz Przechlewski"/>
 <link rel="stylesheet" type="text/css" href="/style/tp-base.css" title="ES"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-bw.css" title="NS"/>
 <link rel="alternate stylesheet" type="text/css" href="/style/tp-big.css" title="BS"/>
 <script type="text/javascript" src="/script/tp.js"></script>
 <style type="text/css"> td { padding: 3px 9px 3px 9px ; text-align: right ; }
         table { font-family : sans-serif ; border: 1px dotted; }
         td.t_hdr { text-align: center } td.pv { background: #656dbc } td.qv { background: #656dbc }
</style>
<title xml:lang="pl">Pomiar temperatury/wilgotności--stacja meteorologiczna</title>
<meta name="DC.title" content="Pomiar temperatury/wilgotności--stacja meteorologiczna" /></head><body>';

print "<h3>Pomiar temperatury/wilgotności</h3>\n";

print "<p>Temperatura, wilgotność i <a href='http://pl.wikipedia.org/wiki/Temperatura_punktu_rosy'>temperatura
 punktu rosy</a>.  Współrzędne geograficzne punktu pomiaru:
<a href='http://pinkaccordions.homelinux.org/staff/tp/Geo/show_point.html?lat=54.43966270&amp;lon=18.55015754'>54.43966270/18.55015754</a>.
Do rejestrowania wykorzystywane są czujniki
<a href='http://www.flickr.com/photos/tprzechlewski/8164399252/'>DHT-22</a> (firmy
<a href='https://www.sparkfun.com/products/10167'>SparkFun</a>?)</p>
<p>Pierwszy pomiar: 20121109_09:30.
Wykresy: <a href='./DHT22_img.html#temp_'>Temperatura</a>
 | <a href='./DHT22_img.html#hum_'>Wilgotność</a></p>
<!-- http://proto-pic.co.uk/humidity-and-temperature-sensor-dht22/ -->\n";

print "<table class='tr.comment'>\n";
print "<tr class='main'><td rowspan='2'>Data/Godzina</td><td colspan='2' class='t_hdr'>Pokój (P)</td><td colspan='2' class='t_hdr'>Ogród (O)</td><td colspan='2' class='t_hdr'>Weranda (W)</td><td colspan='3' class='t_hdr'>Punkt rosy</td></tr>"
	. "<tr class='main'><td>T °C</td><td>H %</td><td>T °C</td><td>H %</td><td>T °C</td><td>H %</td>"
	#. "<td class='pv'>T24%</td><td class='pv'>T25%</td><td class='pv'>T22%</td>"
 	#. "<td class='qv'>H24%</td><td class='qv'>H25%</td><td class='qv'>H22%</td>"
	#. "<td>Mean T</td><td>Sd T</td><td>Mean H</td><td>Sd H</td>";
	 . "<td>P °C</td><td>O °C</td><td>W °C</td>"
         . "</tr>\n";

## ### ##
foreach $d (reverse sort keys %TempDHT) {
  $cdt = ${d} ; $cdt = substr($cdt, 0, 8) . "_" . substr($cdt, 8, 2) . ":" . substr($cdt, 10, 1) . "0";
 
   print "<tr><td>$cdt </td>";
  
   $row_txt = $row_txt_dewp =  "";

   push(@TempDates, $d);

   my $sr_temp = $sr_hum = $sr_n = 0;
   for $sens ( @Sensors ) {

      if (exists ($TempDHT{$d}{$sens})) {
	 $ct_ = $TempDHT{$d}{$sens} ; $ch_ = $HumDHT{$d}{$sens};
         $sr_temp += $ct_ ; $sr_hum += $ch_ ; $sr_n++;

	 if ($ch_ == 0) {## humidity is 0, ie. missing reading
	   $dew_point = 0 ; } 
	 else { $dew_point = dewpoint_approximation($ct_, $ch_); }

         ## dodajemy zero po ${d} żeby było ładniej (pełna godzina)
         $row_txt .= "<td>$ct_ </td><td>$ch_ </td>";   
	 $row_txt_dewp .= sprintf "<td> %.2f</td>", $dew_point;

	 ### ## na potrzeby wykresu: ## ###
	 ### ## print STDERR "???=> $TempDHT{$d}{$sens}\n";
	 push( @{ $SDataT{$sens} }, $TempDHT{$d}{$sens} );
	 push( @{ $SDataH{$sens} }, $HumDHT{$d}{$sens} );
         push( @{ $SDataDewP{$sens} }, $dew_point);
	 ### ##

      } else {
         $row_txt .= "<td>x</td><td> x </td>";   
	 $row_txt_dewp .= "<td> x </td>";

	 ### jeżeli nie ma wstaw `0'
	 push( @{ $SDataT{$sens} }, 0 );
	 push( @{ $SDataH{$sens} }, 0 );
         push( @{ $SDataDewP{$sens} }, 0);

      }
   }

   ### Policzenie średniej
   $sr_temp = $sr_temp/$sr_n; $sr_hum = $sr_hum/$sr_n;
   $row_txt_t = $row_txt_h = "";

   my $var_temp = $var_hum = $sr_n = 0;

   for $sens ( @Sensors ) {
      if (exists ($TempDHT{$d}{$sens})) {
          #$temp_p = $TempDHT{$d}{$sens}/$sr_temp*100 ;
          #$hum_p = $HumDHT{$d}{$sens}/$sr_hum*100 ; 
          #
	  #$var_temp += ($TempDHT{$d}{$sens} - $sr_temp)*($TempDHT{$d}{$sens} - $sr_temp);
	  #$var_hum += ($HumDHT{$d}{$sens} - $sr_hum)*($HumDHT{$d}{$sens} - $sr_hum);
      	  #$sr_n++;

          ## dodajemy zero po ${d} żeby było ładniej (pełna godzina)
          $row_txt_t .= sprintf "<td class='pv'>%.2f</td>", $temp_p;
          $row_txt_h .= sprintf "<td class='qv'>%.2f</td>", $hum_p;
      }
      else {
          $row_txt_t .= "<td>x</td>";
          $row_txt_h .= "<td>x</td>";
      }
   }  
   
   #$var_temp = sqrt($var_temp / $sr_n) ;
   #$var_hum = sqrt($var_hum / $sr_n );
   #
   #printf "$row_txt $row_txt_t $row_txt_h <td>%.3f</td><td>%.3f</td><td>%3f</td><td>%.3f</td> </tr>\n",
   #    $sr_temp, $var_temp, $sr_hum, $var_hum;
   print "$row_txt $row_txt_dewp </tr>\n";

   push (@DatyCzasy, substr($date, 0, 10)); # drukowana data jest skrócona

   $lineNo++;

   if ($lineNo > 240 ) { last ; }
 }

print "</table>\n";
print "<p>$lineNo odczytów</p>\n";

print "<p><a href='../index.html' class='bfooter' ><img longdesc='[[back.png'
src='/icons/back.png' alt='Powrót'/>Powrót</a></p>\n";

print "</body></html>\n";

## ###
my $chart__name__t = "/var/www/stats/sensirion_t.png";
my $chart__name__h = "/var/www/stats/sensirion_h.png";

my $lst_day = $DatyCzasy[$#DatyCzasy];
my $fst_day = $DatyCzasy[0];

##my @Kolory = ( 'green', '#FF8C00', 'red', 'blue', '#5CB3FF', 'black' );
my $BaselineKolor = 'black';
my $BaseLineStyle = 3; # linia kropkowana
my $NormalLineStyle = 1;
my $chart_width = 820;
my $chart_height = 500 ;
my $long_ticks = 0 ;
my $xskip = 24 ;
my $mov_avg_pts = 0; ## not used (yet!)

@TempDates = reverse(@TempDates);

my @data = \@TempDates; ##

my @tmp__ = keys %SensorNames ;  

$SensorTNo = $#tmp__ + 6; ## dew point
## @LineStyles to array zawierajacy $#SensorTNo jedynek :
my @LineStyles = ((1, 3) x $SensorTNo);

for $s ( @Sensors ) {
    @{$SDataT{$s}} = reverse @{$SDataT{$s}}; 
    push (@data, $SDataT{$s} );

    @{$SDataDewP{$s}} = reverse @{$SDataDewP{$s}}; 
    push (@data, $SDataDewP{$s} ); ## dew point
 }

my @Kolory = ( 'red', 'red', 'blue', '#5CB3FF', 'green', 'green', 'black' ); # ostatni kolor to kolor y=0
my @legend_All_Sensors = ("P", "PRp", "O", "PRo", "W", "PRw");
draw_chart(\@data, \@legend_All_Sensors, 40, -25, 13, $chart__name__t, "Temperatura/Punkt rosy", "Temp. [C]" );

## Wykres wilgotnosci: ### ### #### #### #### #### ### #### #### #### #### ####

my @data = \@TempDates; 

$SensorTNo = $#tmp__ + 1;
## jeżeli my @LineStyles to błąd czemu?
@LineStyles = ((1) x $SensorTNo);

for $s ( @Sensors ) {
    @{$SDataH{$s}} = reverse @{$SDataH{$s}}; 
    push (@data, $SDataH{$s} ); }
  
@Kolory = ( 'red', 'blue', 'green', '#5CB3FF', 'black' ); # pierwsze trzy się liczą 
@legend_All_Sensors = ("P", "O", "W");

draw_chart(\@data,  \@legend_All_Sensors, 100, 0, 20, $chart__name__h, "Wilgotnosc", "Wilg. [%]" );

##########
sub draw_chart {
  my $data_ref = shift ; ## wskaznik do danych
  my $legend_ref = shift ; ## wskaznik do legendy

  my $y_max_value = shift ;
  my $y_min_value = shift ;
  my $y_tick_number = shift ;

  my $chartname = shift;
  my $chart_title_name = shift;
  my $y_label_name = shift;

  my @data = @$data_ref; ## dereferencing ref to local @data ;
  my @legend_txt = @$legend_ref; ## ditto

  my $Lines_At_Chart_ = $#data +1;

  ## @sens = sort keys %STemp ; print STDERR "@TempDates\n"@sens\n@data\n";
  ## dodac linie zera:
  #
  if ($y_min_value < 0) {## jeżeli wykres nie zawiera dolnej ćwiartki XY nie ma sensu
     for ($i=0; $i<=$#TempDates; $i++) { push (@Zeros, 0) }
     push (@data, \@Zeros ); $Lines_At_Chart_ +=1 }

  my $mygraph = GD::Graph::lines->new($chart_width,  $chart_height);

  push (@LineStyles, $BaseLineStyle);

  @Kolory = @Kolory[0..$Lines_At_Chart_]; push @Kolory, $BaselineKolor;
  ##print STDERR ">>@LineStyles\n"; print STDERR ">>@Kolory\n";
  my $chart_type = $mov_avg_pts> 0? "" : "";

  $mygraph->set_text_clr('black');
  $mygraph->set(
    x_label     => 'Czas',
    y_label     => $y_label_name,
    title       => "$chart_title_name$chart_type: $lst_day--$fst_day",
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

  print STDERR "*** Liczba linii na wykresie: $#data ***\n";

  my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

  ## for cgi script uncomment: ## ### ###
  ##print "Content-type: image/png\n\n";

  open ( IMG, ">$chartname") or die " *** Problems opening: $chartname ***" ;

  print IMG $myimage->png;

  close (IMG);

  return ;
} ## // ///



## ### ###
# approximation valid for
# 0 degC < T < 60 degC
# 1% < RH < 100%
# 0 degC < Td < 50 degC 
## ### ###
## cf also: http://www.decatur.de/javascript/dew/index.html
## ### ###

sub dewpoint_approximation {
   my $T = shift ;  # Dry-bulb temperature C
   my $Hr = shift ; # Relative humidity

   my $a = 17.271 ;
   my $b = 237.7 ; # degC
 
   return ( ($b * gamma($T, $Hr, $a, $b)) / ($a - gamma($T, $Hr, $a, $b)) )
}

## ### ###
sub gamma {
   my $x = shift ; 
   my $h = shift ; 

   my $a = shift ; 
   my $b = shift ; 
   ##print STDERR "**** $x $h $a $b ****\n";

   return ( ($a * $x / ($b + $x)) + log ($h / 100.0) );
}

## ### ###
