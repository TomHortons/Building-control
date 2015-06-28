package pmv_us ;
sub calc_pmv{
	my ($CLO,$TA,$TR,$MET,$VEL,$RH);
	################################
	#Initial entry 
	################################
	#Clothing(clo)
	$CLO = 1.09;#winter
	#$CLO = 0.56;#summer
	#Air temp. (Celsius)
	$TA = 34.0;
	#Mean radiant temp. (Celsius)
	$TR = 34.0;
	#Activity (met)
	$MET = 1.0;#reading books
	#Air speed (m/s)
	$VEL = 0.1;#不感気流
	#Relative humidity (%)
	$RH = 50.0;#
	################################
	#$B0z?t<u$1<h$j(B
	($CLO,$TA,$TR,$MET,$VEL,$RH)=@_;
	#################################
	##Clothing(clo)
	#$CLO = 1.10;
	##Air temp. (Celsius)
	#$TA = 24.0;
	##Mean radiant temp. (Celsius)
	#$TR = 22.0;
	##Activity (met)
	#$MET = 1.0;
	##Air speed (m/s)
	#$VEL = 0.15;
	##Relative humidity (%)
	#$RH = 50.0;
	#################################
	my $fnps = exp(16.6536 - 4030.183 / ($TA + 235));
	my $pa = $RH * 10 * $fnps;
	my $icl = 0.155 * $CLO;
	my $m = $MET * 58.15;
	
	my $fcl;
	if ($icl < 0.078){
		$fcl = 1 + 1.29 * $icl;
	}else{
		$fcl = 1.05 + 0.645 * $icl;
	}
	
	my $hcf = 12.1 * sqrt($VEL);
	my $taa = $TA + 273;
	my $tra = $TR + 273;
	
	my $tcla = $taa + (35.5 - $TA) / (3.5 * (6.45 * $icl + 0.1));
	my $p1 = $icl * $fcl;
	my $p2 = $p1 * 3.96;
	my $p3 = $p1 * 100;
	my $p4 = $p1 * $taa;
	my $p5 = 308.7 - 0.028 * $m + $p2 * ($tra / 100) ** 4;
	my $xn = $tcla / 100;
	my $xf = $tcla / 50;
	my $n = 0;
	my $eps = 0.0015;
	
	my ($hcn, $hc);
	while (abs($xn - $xf) > $eps){
		$xf = ($xf + $xn) / 2;
		$hcf = 12.1 * sqrt($VEL);
		$hcn = 2.38 * abs(100 * $xf - $taa) ** 0.25;
		if($hcf > $hcn){
			$hc = $hcf;
		}else{
			$hc = $hcn;
		}
		$xn = ($p5 + $p4 * $hc - $p2 * ($xf ** 4)) / (100 + $p3 * $hc);
		$n = $n + 1;
	}
	
	my $tcl = 100 * $xn - 273;
	
	my($hl1,$hl2,$hl3,$hl4,$hl5,$hl6);
	#skin diff loss
	$hl1 = 3.05 * 0.001 * (5733 - 6.99 * $m - $pa);
	
	#sweat loss
	if ($m > 58.15){
		$hl2 = 0.42 * ($m - 58.15);
	}else{
		$hl2 = 0;
	}
	
	#latent respiration loss
	$hl3 = 1.7 * 0.00001 * $m * (5867 - $pa);
	
	#dry respiration loss
	$hl4 = 0.0014 * $m * (34 - $TA);
	
	#radiation loss
	$hl5 = 3.96 * $fcl * ($xn ** 4 - ($tra / 100) ** 4);
	
	#convection loss
	$hl6 = $fcl * $hc * ($tcl - $TA);
	
	#thermal sensation to skin tras coef
	my $ts = 0.303 * exp(-0.036 * $m) + 0.028;
	my $tpo;
	
	if ($VEL < 0.2){
		$tpo = 0.5 * $TA + 0.5 * $TR;
	}else{
		if ($VEL < 0.6){
			$tpo = 0.6 * $TA + 0.4 * $TR;
		}else{
			$tpo = 0.7 * $TA + 0.3 * $TR;
		}
	}
	
	my $PMV = $ts * ($m - $hl1 - $hl2 - $hl3 -$hl4 - $hl5 - $hl6);
	my $PPD = 100 - 95 * exp(-0.03353 * $PMV ** 4 - 0.2179 * $PMV ** 2);
	
#	print "tpo:$tpo\n";
#	print "PMV:$PMV\n";
#	print "PPD:$PPD\n";
#	print "Number of iterations:$n\n";
	return $PMV;
	}

	1;
