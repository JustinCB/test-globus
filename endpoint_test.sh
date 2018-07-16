#!/bin/sh
do_perftest ()
{
perf_val="`sudo dd if="$1" of="$2" bs="$3" count="$4" $5 2>&1 | awk '!/records ((in)|(out))/ && $1 ~ /[0-9][0-9\.]*/ && $(NF-3)!=0{printf "%.0f\n", $1/$(NF-3)}'`"
if [ ! "$perf_val" ] && [ "$5" ]
then
do_perftest "$1" "$2" "$3" "$4" ""
else
perf_tmp="`echo $perf_val | awk '{$1="";print}'`"
if [ "$perf_tmp" ]
then
perf_temp="`echo $perf_val | awk '{print $1}'`"
for perf_i in $perf_tmp
do
perf_temp=`expr '(' $perf_temp + $perf_i ')' / 2`
done
echo $perf_temp
elif [ "$perf_val" ]
then
echo $perf_val
else
echo 0
fi
fi
}
do_perftest_round ()
{
perftest_round_tmp=`do_perftest /dev/zero "$1" 1048576 1 "$2"`
perftest_round_temp=`do_perftest /dev/zero "$1" 8192 128 "$2"`
perftest_round_tmp=`expr '(' $perftest_round_tmp + $perftest_round_temp ')' / 2`
perftest_round_temp=`do_perftest /dev/zero "$1" 512 2048 "$2"`
expr '(' $perftest_round_tmp + $perftest_round_temp ')' / 2
}
globus_perftest ()
{
globus_perftest_tmp=`do_perftest_round "${1}/globus_test1" ""`
globus_perftest_temp=`do_perftest_round "${1}/globus_test1" conv=fdatasync`
globus_perftest_tmp=`expr '(' $globus_perftest_tmp + $globus_perftest_temp ')' / 2`
globus_perftest_temp=`do_perftest_round "${1}/globus_test1" conv=fsync`
globus_perftest_tmp=`expr '(' $globus_perftest_tmp + $globus_perftest_temp ')' / 2`
globus_perftest_temp=`do_perftest_round "${1}/globus_test1" oflags=dsync`
globus_perftest_tmp=`expr '(' $globus_perftest_tmp + $globus_perftest_temp ')' / 2`
globus_perftest_temp=`do_perftest_round "${1}/globus_test1" oflags=sync`
sudo rm -f "${1}/globus_test1"
globus_perftest_result_whole=`expr '(' $globus_perftest_tmp + $globus_perftest_temp ')' / 2`
globus_perftest_result_decimal=0
globus_perftest_byte_prefix=""
if [ $globus_perftest_result_whole -gt 10000 ]
then
globus_perftest_byte_prefix="k"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
if [ $globus_perftest_result_whole -gt 1000 ]
then
globus_perftest_byte_prefix="M"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`$globus_perftest_result_decimal
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
if [ $globus_perftest_result_whole -gt 1000 ]
then
globus_perftest_byte_prefix="G"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`$globus_perftest_result_decimal
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
if [ $globus_perftest_result_whole -gt 1000 ]
then
globus_perftest_byte_prefix="G"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`$globus_perftest_result_decimal
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
if [ $globus_perftest_result_whole -gt 1000 ]
then
globus_perftest_byte_prefix="T"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`$globus_perftest_result_decimal
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
if [ $globus_perftest_result_whole -gt 1000 ]
then
globus_perftest_byte_prefix="P"
globus_perftest_result_decimal=`echo $globus_perftest_result_whole | awk '{printf "%03d\n", ($1-((int($1/1000))*1000))}'`$globus_perftest_result_decimal
globus_perftest_result_whole=`expr $globus_perftest_result_whole / 1000`
fi
globus_perftest_result=$globus_perftest_result_whole
globus_perftest_result_decimal=`echo $globus_perftest_result_decimal | sed -e 's/0*$//'`
if [ "$globus_perftest_result_decimal" ]
then
globus_perftest_result="${globus_perftest_result}.$globus_perftest_result_decimal"
fi
echo "			$globus_perftest_result ${globus_perftest_byte_prefix}B/s"
}
collection_list ()
{
if [ ! "${collection_list_list_of_collections:+w}" ]
then
collection_list_list_of_collections="`sudo /opt/globus/bin/gcs-config collection list`"
fi
echo "$collection_list_list_of_collections"
}
gateway_list ()
{
if [ ! "${gateway_list_list_of_gateways:+w}" ]
then
gateway_list_list_of_gateways="`sudo /opt/globus/bin/gcs-config storage-gateway list`"
fi
echo "$gateway_list_list_of_gateways"
}
globus_ls () {
ls_num=`ls "$@" | awk 'NF>0' | wc -l`
ls_loops=`ls "$@" | grep -c ':'`
ls_prefix=""
ls_j=1
for ls_i in `seq 0 $loops`
do
if [ $ls_i != 0 ]
then
prefix="`ls "$@" | awk 'NF>0' | awk 'NR=='$j'{gsub(/:$/,"");print}'`"
ls_j=`expr $ls_j + 1`
fi
while [ ! "`ls "$@" | awk 'NF>0' | awk 'NR=='$ls_j' && /:$/'`" ] && ([ $ls_j -lt $num ] || [ $ls_j = $num ])
do
ls "$@" | awk 'NF>0' | awk 'NR=='$ls_j'{print "'"$prefix"'/"$0}' | sed -e 's#//*#/#g'
ls_j=`expr $ls_j + 1`
done
done
}
globus_stat () {
stats="`(stat -x $1 2>/dev/null || stat $1) | xargs`"
stat_j=`echo $stats | wc -w`
stat_i=1
stat_per=0
while [ $stat_i -lt $stat_j ] || [ $stat_i = $stat_j ]
do
stat="`echo $stats | awk '{print $'$stat_i'}'`"
if [ '\'"$stat" = '\(' ]
then
stat_i=`expr $stat_i + 1`
echo $stats | awk '{print "\t\t\t("$'$stat_i'}'
if [ $stat_per = 1 ]
then
stat_per=0
else
stat_per=1
fi
elif [ "$stat" = "IO" ]
then
stat_i=`expr $stat_i + 1`
echo $stats | awk '{print "\t\tIO "$'$stat_i'}'
stat_i=`expr $stat_i + 1`
echo $stats | awk '{print "\t\t\t"$'$stat_i'}'
stat_i=`expr $stat_i + 1`
if [ ! "`echo $stats | awk '{print $'$stat_i'}' | grep ':'`" ]
then
echo "		File Type:"
echo $stats | awk '{print "\t\t\t"$'$stat_i'}'
fi
elif [ "$stat" = "Access:" ] || [ "$stat" = "Modify:" ] || [ "$stat" = "Change:" ] || [ "$stat" = "Birth:" ]
then
echo "		$stat"
stat_i=`expr $stat_i + 1`
if echo $stats | awk '{print substr($'$stat_i',1,1)}' | grep [0-9] >/dev/null 2>&1
then
echo "			Date:"
echo $stats | awk '{print "\t\t\t\t"$'$stat_i'}'
stat_i=`expr $stat_i + 1`
echo "			Time:"
echo $stats | awk '{print "\t\t\t\t"$'$stat_i'}'
stat_i=`expr $stat_i + 1`
echo "			Time Zone:"
echo $stats | awk '{print "\t\t\t\tUTC"substr($'$stat_i',1,3)":"substr($'$stat_i',4,2)}'
else
echo $stats | awk '{print "\t\t\t"$'$stat_i'}'
fi
elif [ $stat_per = 1 ]
then
if [ `expr $stat_i % 2` = 1 ]
then
echo "			$stat"
else
echo "		$stat"
fi
elif [ `expr $stat_i % 2` = 1 ]
then
echo "		$stat"
else
echo "			$stat"
fi
stat_i=`expr $stat_i + 1`
done
echo "		Write Performance:"
globus_perftest $1
}
get_gcp () {
if ls globusconnectpersonal-*.*.* >/dev/null 2>&1
then
true
elif ls globusconnectpersonal-*.tar >/dev/null 2>&1
then
xar -xf `ls globusconnectpersonal-*.tar | awk 'NR==1'` >/dev/null
elif ls globusconnectpersonal-*.tgz >/dev/null 2>&1
then
tar -xzf `ls globusconnectpersonal-*.tgz | awk 'NR==1'` >/dev/null
else
wget -q https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz >/dev/null 2>&1 || curl -O https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz >/dev/null -s
tar -xzf globusconnectpersonal-latest.tgz >/dev/null
fi
ls -d globusconnectpersonal-*.*.* | awk 'NR==1'
}
globus_wait () {
downs=0
while true
do
globus task wait --timeout 30 $1
tmp=$?
if [ $tmp = 1 ]
then
if [ "`globus task show $1 | awk '/Details/{print $NF}'`" = "GC_NOT_CONNECTED" ]
then
downs=`expr $downs + 1`
if [ $downs = 1 ]
then
echo Endpoint is not connected after 1 try
else
echo Endpoint is not connected after $downs tries
fi
if [ $downs -gt 5 ]
then
>&2 echo "Endpoint is down, so transfer probably fail'd"
if [ ! "`netstat -lt | awk '$4 ~ /[\.:]((5[01]...)|(gsiftp))/'`" ]
then
>&2 echo "Ensure connections on ports 50000-51000 aren't block'd by your firewall rules"
fi
return 1
else
sleep 1
fi
elif [ "`globus task show $1 | awk '/Details/{print $NF}'`" = "CONNECT_FAILED" ]
then
>&2 echo "Transfer fail'd because endpoint is down"
if [ ! "`netstat -lt | awk '$4 ~ /:5[01].../ || $4 ~ /.5[01].../'`" ]
then
>&2 echo "Ensure connections on ports 50000-51000 aren't block'd by your firewall rules"
fi
return 1
elif [ "`globus task show $1 | awk '/Details/{print $NF}'`" = "TIMEOUT" ]
then
>&2 echo "Task timed out"
return 1
fi
if [ "`globus task show $1 | awk '/Status/{print $NF}'`" = "SUCCEEDED" ]
then
return 0
elif [ "`globus task show $1 | awk '/Status/{print $NF}'`" = "ACTIVE" ]
then
true
else
>&2 echo "Test Error: Transfer timed out/finished & is paused or canceled"
return 1
fi
elif [ $tmp != 0 ]
then
return $tmp
else
return 0
fi
done
}
make_test_dataset ()
{
mkdir -p /tmp/globus_test/empty_dir
touch /tmp/globus_test/0_bytes.txt
dd if=/dev/urandom of=/tmp/globus_test/128KB.bin bs=4096 count=32 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/16KB.bin bs=4096 count=4 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1_bytes.txt bs=1 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1KB.bin bs=1024 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1MB.bin bs=4096 count=256 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/256KB.bin bs=4096 count=64 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/2KB.bin bs=2048 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/32KB.bin bs=4096 count=8 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/4KB.bin bs=4096 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/512KB.bin bs=4096 count=128 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/64KB.bin bs=4096 count=16 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/8KB.bin bs=4096 count=2 iflag=fullblock status=none
mkdir -p /tmp/globus_test/not_empty_dir
touch /tmp/globus_test/not_empty_dir/0_bytes.txt
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/128KB.bin bs=4096 count=32 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/16KB.bin bs=4096 count=4 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1_bytes.txt bs=1 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1KB.bin bs=1024 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1MB.bin bs=4096 count=256 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/256KB.bin bs=4096 count=64 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/2KB.bin bs=2048 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/32KB.bin bs=4096 count=8 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/4KB.bin bs=4096 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/512KB.bin bs=4096 count=128 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/64KB.bin bs=4096 count=16 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/8KB.bin bs=4096 count=2 iflag=fullblock status=none
}
globus_transfer_helper () {
mkdir -p "`echo $4 | cut -d ':' -f2-`"
echo starting forward transfer
globus_wait `globus transfer -r $1 "$2" "$3" | awk 'END{print $NF}'`
echo forward transfer compleat
echo starting reverse transfer
globus_wait `globus transfer -r $1 "$3" "$4" | awk 'END{print $NF}'`
echo reverse transfer  compleat
echo beginning file checks
for transfer_i in `globus_ls \`echo $4 | cut -d ":" -f2-\`/*`
do
cmp -s $transfer_i `echo $2 | cut -d ':' -f2-`/`echo $i | sed -e "s#^\`echo $4 | cut -d ':' -f2-\`##"`
if [ $? != 0 ]
then
if [ `basename \`dirname $i\`` != `basename $4` ]
then
>&2 echo "/`basename \`dirname $i\``/`basename $i` fail'd with $1"
else
>&2 echo "/`basename $i` fail'd with $1"
fi
exit 1
fi
done
echo file checks done
echo removing temporary directory
rm -rf `echo $4 | cut -d ":" -f2-`
echo temporary directory removed
}
globus_transfer_test_helper () {
echo
echo starting transfer tests
echo
echo starting transfer test 1
globus_transfer_helper " " "$1" "$2" "$3"
echo transfer test 1 done
echo
echo starting transfer test 2
globus_transfer_helper "--preserve-mtime" "$1" "$2" "$3"
echo transfer test 2 done
echo
echo starting transfer test 3
globus_transfer_helper "--no-verify-checksum" "$1" "$2" "$3"
echo transfer test 3 done
echo
echo starting transfer test 4
globus_transfer_helper "--no-verify-checksum --preserve-mtime" "$1" "$2" "$3"
echo transfer test 4 done
echo
echo starting transfer test 5
globus_transfer_helper "--encrypt" "$1" "$2" "$3"
echo transfer test 5 done
echo
echo starting transfer test 6
globus_transfer_helper "--encrypt --preserve-mtime" "$1" "$2" "$3"
echo transfer test 6 done
echo
echo starting transfer test 7
globus_transfer_helper "--encrypt --no-verify-checksum" "$1" "$2" "$3"
echo transfer test 7 done
echo
echo starting transfer test 8
globus_transfer_helper "--encrypt --no-verify-checksum --preserve-mtime" "$1" "$2" "$3"
echo transfer test 8 done
echo
echo transfer tests done
}
endpoint_test_helper () {
echo "Testing Endpoints:"
echo
make_test_dataset >/dev/null
wd="$PWD"
cd $1
./globusconnectpersonal -stop >/dev/null 2>&1
test_ids=`globus endpoint create --personal 'test endpoint' | awk 'NR!=1{print $NF}'`
./globusconnectpersonal -setup `echo $test_ids | awk '{print $2}'` -dir /tmp/globuscfg >/dev/null
./globusconnectpersonal -start -dir /tmp/globuscfg -restrict-paths r/tmp/globus_test,rw/tmp/globus_test_returns -shared-paths r/tmp/globus_test,rw/tmp/globus_test_returns >/dev/null &
while [ "`./globusconnectpersonal -status | awk 'NR==1{print $3}'`" != "connected" ]
do
sleep 1
done
cd $wd
test_j=0
for test_i
do
if [ "$test_i" = "$1" ]
then
true
else
echo testing endpoint $test_j
globus_transfer_test_helper "`echo $test_ids | awk '{print $1}'`:/tmp/globus_test/" "${test_i}:/globus_test/" "`echo $test_ids | awk '{print $1}'`:/tmp/globus_test_returns/"
echo "done testing endpoint $test_j"
fi
test_j=`expr $test_j + 1`
done
echo
echo tests done
echo
echo cleaning up
echo removing test directory
rm -rf /tmp/globus_test
echo test directory removed
echo removing test directories on endpoints
for test_i
do
if [ "$test_i" != "$1" ]
then
globus_wait `globus delete -r "${test_i}:/globus_test/" | awk 'NR==2{print $NF}'`
fi
done
cd $1
echo stopping gcp
./globusconnectpersonal -stop >/dev/null 2>&1
echo gcp stopped
echo deleting test endpoint
printf "test "
globus endpoint delete `echo $test_ids | awk '{print $1}'`
echo removing gcp temporary config folder
rm -rf /tmp/globuscfg
echo gcp temporary config folder deleted
cd $wd
echo DONE
}
make_test_dataset ()
{
mkdir -p /tmp/globus_test/empty_dir
touch /tmp/globus_test/0_bytes.txt
dd if=/dev/urandom of=/tmp/globus_test/128KB.bin bs=4096 count=32 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/16KB.bin bs=4096 count=4 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1_bytes.txt bs=1 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1KB.bin bs=1024 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/1MB.bin bs=4096 count=256 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/256KB.bin bs=4096 count=64 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/2KB.bin bs=2048 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/32KB.bin bs=4096 count=8 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/4KB.bin bs=4096 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/512KB.bin bs=4096 count=128 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/64KB.bin bs=4096 count=16 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/8KB.bin bs=4096 count=2 iflag=fullblock status=none
mkdir -p /tmp/globus_test/not_empty_dir
touch /tmp/globus_test/not_empty_dir/0_bytes.txt
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/128KB.bin bs=4096 count=32 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/16KB.bin bs=4096 count=4 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1_bytes.txt bs=1 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1KB.bin bs=1024 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/1MB.bin bs=4096 count=256 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/256KB.bin bs=4096 count=64 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/2KB.bin bs=2048 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/32KB.bin bs=4096 count=8 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/4KB.bin bs=4096 count=1 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/512KB.bin bs=4096 count=128 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/64KB.bin bs=4096 count=16 iflag=fullblock status=none
dd if=/dev/urandom of=/tmp/globus_test/not_empty_dir/8KB.bin bs=4096 count=2 iflag=fullblock status=none
}
list_collection_names ()
{
collection_list | awk 'BEGIN{FS="|"} NR!=1{sub(/^ /,"",$4);gsub(/ $/,"",$4);print $4}'
}
list_names ()
{
collection_list | awk 'BEGIN{FS="|"} NR!=1{sub(/^ /,"",$3);gsub(/ $/,"",$3);print $3}'
}
list_types ()
{
collection_list | awk 'BEGIN{FS="|"} NR!=1{sub(/^ /,"",$2);gsub(/ $/,"",$2);print $2}'
}
list_uuid ()
{
collection_list | awk 'NR!=1{print $1}'
}
list_roots ()
{
root_i=2
roots_old_IFS="$IFS"
IFS="
"
for root_j in `list_types`
do
IFS="$roots_old_IFS"
if [ "$root_j" = "POSIX" ]
then
gateway_list | awk -F '|' '$3 == "'"`collection_list | awk -F '|' 'NR=='$root_i'{print $3}'`"'"{sub(/^ /,"",$NF);gsub(/ $/,"",$NF);print $NF;}'
else
echo /BAD/PATH/NOT/POSIX
fi
root_i=`expr $root_i + 1`
done
}
list_other_storage_gateway_uuids ()
{
for uuid_i in `gateway_list | awk 'NR!=1{print $1}'`
do
if [ ! "`sudo /opt/globus/bin/gcs-config storage-gateway show $uuid_i | grep domain`" ]
then
echo $uuid_i
fi
done
}
storage_gateway_show ()
{
if [ ! "${storage_gateway_show_info:+w}" ] || [ "$storage_gateway_showing" != "$1" ]
then
storage_gateway_show_info="`sudo /opt/globus/bin/gcs-config storage-gateway show $1`"
storage_gateway_showing="$1"
fi
echo "$storage_gateway_show_info"
}
get_storage_gateway_name ()
{
storage_gateway_show $1 | awk '/display-name/{$1="";sub(/^ /, "");gsub(/ $/, "");sub(/^"/,"");gsub(/"$/,"");print $0}'
}
get_storage_gateway_type ()
{
storage_gateway_show $1 | awk '/connector/{$1="";sub(/^ /, "");gsub(/ $/, "");sub(/^"/,"");gsub(/"$/,"");print $0}'
}
get_storage_gateway_root ()
{
storage_gateway_show $1 | awk '/root/{$1="";sub(/^ /, "");gsub(/ $/, "");sub(/^"/,"");gsub(/"$/,"");print $0}'
}
list_other_storage_gateways ()
{
echo
echo Printing information on other storage gateways
echo Note: these are not set up for transfers
echo You must create a new collection with globus.org to set them up
echo
echo
for i in `list_other_storage_gateway_uuids`
do
get_storage_gateway_name $i | awk '{print $0":"}'
echo "	Type:"
printf "\t\t"
get_storage_gateway_type $i
echo "	Display Name:"
printf "\t\t"
get_storage_gateway_name $i
if [ "`get_storage_gateway_type $i`" = "POSIX" ]
then
echo "	Storage Root:"
printf "\t\t"
get_storage_gateway_root $i
echo "	Stat:"
globus_stat "`get_storage_gateway_root $i`"
fi
done
}
echo "Endpoint tester starting."
echo "Note: if you're testing a local endpoint, try test_globus.sh"
echo "If you're testing a remote endpoint, & this hangs, the endpoint may be down"
echo
if [ $# = 0 ]
then
>&2 echo No endpoints to test
>&2 echo "Usage: $0 <list of endpoints>"
exit 0
fi
UUIDs=""
for i
do
tmp="`globus endpoint search "$i"`"
temp="`echo "$i" | sed -e 's/[\[\.\*\^\$\\]/\\&/g'`"
tmp="$UUIDs `echo "$tmp" | grep "$temp" | awk '{print $1}'`"
UUIDs="$tmp"
done
endpoint_test_helper `get_gcp` $UUIDs
