source topo.tcl;
source ReadFile.tcl;

proc getPid { nid } {

	global host_per_pod;
	set ToR [expr $nid/$host_per_pod];
	return $ToR;
}

proc getHid { nid } {

	global host_per_pod;
	set host [expr $nid%$host_per_pod];
	return $host;
}

for {set i 0} {$i < $FLOW_NUM} {incr i} {

	set mptcp($i) [new Mptcp];
	$mptcp($i) set-id [expr $i];
	$mptcp($i) max_tcp_num_ $NUM_SUB;
	$mptcp($i) scheduler_ $SCHED;
	$mptcp($i) length_ $R_WIN;
	
	set snid [$flows($i) getSNid];
	set rnid [$flows($i) getRNid];
	
	
	for {set j 0} {$j<$NUM_SUB} {incr j} {

		set fl [expr $i*$NUM_SUB+$j];
		set tcp($fl) [new Agent/TCP/Newreno];
		set tcp_sink($fl) [new Agent/TCPSink];
	
		set sp [getPid $snid];		# the pod where a sender belongs to
		set sh [getHid $snid];		# the sender's index in its pod
		set rp [getPid $rnid];		# the pod where a receiver belongs to
		set rh [getHid $rnid];		# the receiver's index in its pod

		# attach flows on their corresponding nodes
		$ns attach-agent $hosts($sp,$sh) $tcp($fl);
		$ns attach-agent $hosts($rp,$rh) $tcp_sink($fl);
		$ns connect $tcp($fl) $tcp_sink($fl);
		#$tcp($fl) set fid_ $fl;
		#$tcp_sink($fl) set fid_ $fl;
		
		$mptcp($i) attach-tcp $tcp($fl);
	}
}

for {set i 0} {$i < $FLOW_NUM} {incr i} {
	
	set fl $i;
	set at [$flows($fl) getAT];
	set fs [$flows($fl) getFS];
	set send_size [expr $packetSize*$fs]
#	set send_size $fs;

	$ns at [expr 0.9+$at] "$mptcp($fl) send $send_size";
}

# background flow
#set k 0;
#set bg_tcp [new Agent/TCP/Newreno];
#set bg_tcpsink [new Agent/TCPSink];
#$bg_tcp set fid_ [expr 10001+$k];
#$bg_tcpsink set fid_ [expr 10001+$k];
#$ns attach-agent $b_hosts($k) $bg_tcp;
#$ns attach-agent $b_hosts([expr $k+1] $bg_tcpsink;
#$ns connect $bg_tcp $bg_tcpsink
#set bg_ftp [new Application/FTP];
#$bg_ftp attach-agent $bg_tcp;
#$ns at 0.05 "$bg_ftp start"
#$ns at 1 "$bg_ftp stop"

$ns at $endTime "finish"
$ns run
