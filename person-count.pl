#!/usr/bin/perl
#estimate number of people
#
#############################################################
#
#DEBUG
#
#############################################################

sub debug_print {
	print @_;#debug_mode
}

#############################################################
#
#MODULE
#
#############################################################

use DBI;
use DateTime;
use DateTime::Format::MySQL;
use warnings;

#############################################################
#
#DATA BASE
#
#############################################################
#
$dbname="server";
$scheme="public";
$user="user";
$password="password";
$host="localhost";
$conn=DBI->connect("dbi:Pg:dbname=$dbname;host=$host",$user,$password);
@select_table=("table1", "table2");
$insert_table="insert-table";
@sensor_id=("date","sii_co2_01","sii_co2_02","sii_co2_03","sii_co2_04","sii_co2_05","sii_co2_06","sii_co2_07","sii_co2_08","sii_co2_09");
@nop_raw=("date","nop_raw01","nop_raw02","nop_raw03","nop_raw04","nop_raw05","nop_raw06","nop_raw07","nop_raw08","nop_raw09","nop_raw10","nop_raw11","nop_raw12","nop_raw13","nop_raw14","nop_raw15","nop_raw16");
my $sec = 60;# 1minute sa
my @buff = (0,0,0,0,0);# 1minute sa

#############################################################
#
#Estimate number of people
#
#############################################################
print"###nop.pl###\n";
debug_print"###wait $sec seconds###\n";
sleep($sec);
debug_print"###loop start###\n";

while(1){


##4f
##init_parameter
	my @v = (229.3, 331.2, 619.5);#small middle large
	my @q_non_ven=(87.5, 79.5, 525.9);#small  middle large room non_ventilation
	my @q_ven=(253.8,328.5,740.6);#small  middle large room ventilation
	my @c0 = (404.0, 420, 409.0);#small middole large room steady-state co2
	my $k = 20000;#CO2 emission per person
	my $co2_now;
	my $co2_old;
	my @nop;#number of people
	my @nopc;#Round off number of people 

##setDateTime
	
	$dt = DateTime->now( time_zone => 'Asia/Tokyo' );
	$to_date = DateTime::Format::MySQL->format_datetime($dt);
	#($date,$time)=split(/ /,$to_date);
	$dt = $dt->subtract(minutes=>1);
	$from_date = DateTime::Format::MySQL->format_datetime($dt);
	debug_print "from_date:$from_date\n";
	debug_print "to_date:$to_date\n";
	
	
		
#middle rooms
	for($i=1; $i<7; $i++){#101,102,103,104,105,106
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[0] where date <= '$to_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_now = $row[0];
			debug_print "co2_now:$co2_now\n";
		}
		
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[0] where date <= '$from_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_old = $row[0];
			debug_print "co2_old:$co2_old\n";
		}
#check ventilation_control		
		$sql="select * from ventilation_control";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
#		while(@row = $sth->fetchrow_array){
		@row = $sth->fetchrow_array;
		debug_print "flag:@row\n";
		if($row[$i]==0){#制御なし
			$q=$q_ven[1];
		}else{#停止制御
			$q=$q_non_ven[1];	
		}
##calc_nop
		my $sec_sa = $sec/3600.0;
		my $in_exp=-$q*($sec_sa)/$v[1];
		my $EXP = exp($in_exp);
		
		$nop=($q*($co2_now-$c0[1]-(($co2_old-$c0[1])*$EXP)))/($k*(1-$EXP));
		debug_print "###result###\n";
		debug_print "nop:$nop\n";
		
##4sha5nyuui
		debug_print "###4sha5nyuu###\n";
		$nopc = $nop + 0.5;
		$nopc = sprintf("%d", $nopc);
		#$nopc = int($nop);
		if($nop < 0){$nop=0;}
		if($nopc < 0){$nopc=0;}
		if($nop > 80){$nop=80;}
		if($nopc > 80){$nopc=80;}
		debug_print "nopc:$nopc\n";
		
		push(@NOP_RAW,$nop);
		push(@NOP,$nopc);
	}

#large rooms 1F
	for($i=7; $i<10; $i++){#108,109,110
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[0] where date <= '$to_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_now = $row[0];
			debug_print "co2_now:$co2_now\n";
		}
		
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[0] where date <= '$from_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_old = $row[0];
			debug_print "co2_old:$co2_old\n";
		}
#check ventilation_control		
		$sql="select * from ventilation_control";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		@row = $sth->fetchrow_array;
		debug_print "flag:@row\n";
		if($row[$i+1]==0){
			$q=$q_ven[2];
		}else{
			$q=$q_non_ven[2];	
		}
##calc_nop
		my $sec_sa = $sec/3600.0;
		my $in_exp=-$q*($sec_sa)/$v[2];
		my $EXP = exp($in_exp);
		
		$nop=($q*($co2_now-$c0[2]-(($co2_old-$c0[2])*$EXP)))/($k*(1-$EXP));
		debug_print "###result###\n";
		debug_print "nop:$nop\n";
		
##4sha5nyuui
		debug_print "###4sha5nyuu###\n";
		$nopc = $nop + 0.5;
		$nopc = sprintf("%d", $nopc);
		#$nopc = int($nop);
		if($nop < 0){$nop=0;}
		if($nopc < 0){$nopc=0;}
		if($nop > 188){$nop=188;}
		if($nopc > 188){$nopc=188;}
		debug_print "nopc:$nopc\n";
		
		push(@NOP_RAW,$nop);
		push(@NOP,$nopc);
	}

#small rooms 
	for($i=1; $i<6; $i++){#205,206,207,208,209
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[1] where date <= '$to_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_now = $row[0];
			debug_print "co2_now:$co2_now\n";
		}
		
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[1] where date <= '$from_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_old = $row[0];
			debug_print "co2_old:$co2_old\n";
		}
#check ventilation_control		
		$sql="select * from ventilation_control";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		@row = $sth->fetchrow_array;
			debug_print "flag:@row\n";
		if($row[$i+14]==0){
			$q=$q_ven[0];
		}else{
			$q=$q_non_ven[0];	
		}
##calc_nop
		my $sec_sa = $sec/3600.0;
		my $in_exp=-$q*($sec_sa)/$v[0];
		my $EXP = exp($in_exp);
		
		$nop=($q*($co2_now-$c0[0]-(($co2_old-$c0[0])*$EXP)))/($k*(1-$EXP));
		debug_print "###result###\n";
		debug_print "nop:$nop\n";
		
##4sha5nyuui
		debug_print "###4sha5nyuu###\n";
		$nopc = $nop + 0.5;
		$nopc = sprintf("%d", $nopc);
		#$nopc = int($nop);
		if($nop < 0){$nop=0;}
		if($nop > 55){$nop=55;}
		if($nopc < 0){$nopc=0;}
		if($nopc > 55){$nopc=55;}
		debug_print "nopc:$nopc\n";
		
		push(@NOP_RAW,$nop);
		push(@NOP,$nopc);
	}


#large rooms 2F
	for($i=6; $i<8; $i++){#210,211
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[1] where date <= '$to_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_now = $row[0];
			debug_print "co2_now:$co2_now\n";
		}
		
		$sql="select $sensor_id[$i] from $dbname.$scheme.$select_table[1] where date <= '$from_date' order by date desc limit 1";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		while(@row = $sth->fetchrow_array){
			$co2_old = $row[0];
			debug_print "co2_old:$co2_old\n";
		}
#check ventilation_control		
		$sql="select * from ventilation_control";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		@row = $sth->fetchrow_array;
		debug_print "flag:@row\n";
		if($row[$i+14]==0){
			$q=$q_ven[2];
		}else{
			$q=$q_non_ven[2];	
		}
##calc_nop
		my $sec_sa = $sec/3600.0;
		my $in_exp=-$q*($sec_sa)/$v[2];
		my $EXP = exp($in_exp);
		
		$nop=($q*($co2_now-$c0[2]-(($co2_old-$c0[2])*$EXP)))/($k*(1-$EXP));
		debug_print "###result###\n";
		debug_print "nop:$nop\n";
		
##4sha5nyuui
		debug_print "###4sha5nyuu###\n";
		$nopc = $nop + 0.5;
		$nopc = sprintf("%d", $nopc);
		#$nopc = int($nop);
		if($nop < 0){$nop=0;}
		if($nop > 188){$nop=188;}
		if($nopc < 0){$nopc=0;}
		if($nopc > 188){$nopc=188;}
		debug_print "nopc:$nopc\n";
		
		push(@NOP_RAW,$nop);
		push(@NOP,$nopc);
	}



##insert nop
	$sql="insert into $dbname.$scheme.$insert_table values (nextval('nop_seq_no_seq'::regclass),'$to_date'";
	for($i=0; $i < 16; $i++){
		$sql= $sql . ", ";
		$sql= $sql . $NOP[$i];
	}
	$sql= $sql . ")";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
	$sql="insert into nop_raw values (nextval('nop_raw_seq_no_seq'::regclass),'$to_date'";
	for($i=0; $i < 16; $i++){
		$sql= $sql . ", ";
		$sql= $sql . $NOP_RAW[$i];
	}
	$sql= $sql . ")";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
		@NOP_RAW=();
		@NOP=();

##moving_average
	my $n=5;#要素数number of element
	for($k=1;$k<17;$k++){	
		
		debug_print "start moving average\n";
	my $n=5;#要素数number of element
	
		debug_print "select new data\n";
		$sql="select $nop_raw[$k] from nop_raw where date <= '$to_date' order by date desc limit 5";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;
	
		while(@row = $sth->fetchrow_array){
		debug_print "newdata to buff[0]\n";
			push(@buff,$row[0]);
		}
		for($i=0;$i<$n;$i++){
		debug_print "buff[$i]:$buff[$i]\n";
		}
		
		debug_print "start tmp=tmp + buff\n";
		$tmp=0;
		for($i=0;$i<$n;$i++){
			$tmp = $tmp + $buff[$i];
			debug_print "buff[$i]:$buff[$i]\n";
			debug_print "tmp:$tmp\n";
		}
		push(@m_ave,$tmp/$n);
		debug_print " moving average done \n";
		@buff=();
		
	}
		$sql="insert into nop_ave values (nextval('nop_ave_seq_no_seq'::regclass),'$to_date'";
		for($i=0; $i < 16; $i++){
			$sql= $sql . ", ";
			$sql= $sql . $m_ave[$i];
		}
		$sql= $sql . ")";
		debug_print "sql:$sql\n";
		$sth=$conn->prepare($sql);
		$sth->execute;

		@m_ave=();
##end
	debug_print"###loop end###\n";
	debug_print"###wait $sec second###\n";
	sleep($sec);
}
