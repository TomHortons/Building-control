#!/usr/bin/perl
#insert pmv
#
#############################################################
#
#DEBUG
#
#############################################################

sub debug_print {
#	print @_;#debug_mode
}

#############################################################
#
#MODULE
#
#############################################################



require '/home/fusion/ito/yagami/insert_pmv_new/pmv_us.pl' ;
use DBI;
use Encode;
use DateTime;
use DateTime::Format::MySQL;
use warnings;

$dbname="server";
$user="user";
$password="password";
$host="localhost";
$conn=DBI->connect("dbi:Pg:dbname=$dbname;host=$host",$user,$password);


$dt = DateTime->now( time_zone => 'Asia/Tokyo' );
$to_date = DateTime::Format::MySQL->format_datetime($dt);
($date,$time)=split(/ /,$to_date);
$dt = $dt->subtract(minutes=>1);
$from_date = DateTime::Format::MySQL->format_datetime($dt);
debug_print "from_date:$from_date\n";
debug_print "to_date:$to_date\n";

@temp_sensor_id=(sii_temp01,sii_temp02,sii_temp03,sii_temp04,sii_temp05,sii_temp06,sii_temp07,sii_temp08,sii_temp09,sii_temp10,sii_temp11,sii_temp12);
@humid_sensor_id=(sii_humid01,sii_humid02,sii_humid03,sii_humid04,sii_humid05,sii_humid06,sii_humid07,sii_humid08,sii_humid09,sii_humid10,sii_humid11,sii_humid12);
#select avg(temp) and avg(hum) 	
	for($j=0;$j<12;$j++){	
		$sql="select avg($temp_sensor_id[$j]), avg($humid_sensor_id[$j]) from yagami01 where date >= '$from_date' and date <= '$to_date'";
	debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		$temperature = 0;
		$humidity = 0;
		while(@row = $sth->fetchrow_array){
			$temperature += $row[0];
			$humidity += $row[1];
		}
		$tmp = &pmv_us::calc_pmv(1.0,$temperature,$temperature,1.0,0.1,$humidity);
		push(@pmv,$tmp);
		debug_print "tmp_sensor_id:$temp_sensor_id[$j],humid_sensor_id:$humid_sensor_id[$j],temperature:$temperature,humidity:$humidity,pmv:$tmp\n";
	}
	for($j=0;$j<9;$j++){	
		$sql="select avg($temp_sensor_id[$j]), avg($humid_sensor_id[$j]) from yagami02 where date >= '$from_date' and date <= '$to_date'";
	debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		$temperature = 0;
		$humidity = 0;
		while(@row = $sth->fetchrow_array){
			$temperature += $row[0];
			$humidity += $row[1];
		}
#		$tmp = &pmv_us::calc_pmv(0.56,$temperature,$temperature,1.0,0.1,$humidity);
		$tmp = &pmv_us::calc_pmv(1.3,$temperature,$temperature,1.0,0.1,$humidity);
		push(@pmv,$tmp);
		debug_print "tmp_sensor_id:$temp_sensor_id[$j],humid_sensor_id:$humid_sensor_id[$j],temperature:$temperature,humidity:$humidity,pmv:$tmp\n";
	}
	debug_print "pmv:@pmv\n";
#create insert sql		
	$sql="insert into pmv values(nextval('pmv_seq_no_seq'::regclass), '$to_date'";
	for($i=0; $i < 6; $i++){
		$sql= $sql . ", ";
		$sql= $sql . $pmv[$i];
	}
#average of double sensor rooms
	for($i=6; $i <12 ; $i=$i+2){
		$tmp = ($pmv[$i] + $pmv[$i+1])/2;
		$sql= $sql . ", ";
		$sql= $sql . $tmp;
	}
	for($i=12; $i < 17; $i++){
		$sql= $sql . ", ";
		$sql= $sql . $pmv[$i];
	}
#average of double sensor rooms
	for($i=17; $i <20 ; $i=$i+2){
		$tmp = ($pmv[$i] + $pmv[$i+1])/2;
		$sql= $sql . ", ";
		$sql= $sql . $tmp;
	}
	$sql= $sql . ")";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		@pmv=();

