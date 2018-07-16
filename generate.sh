#!/bin/sh
echo "#!/bin/sh" >functions.sh
cat globus_perftest.ini collection_list.ini gateway_list.ini globus_ls.ini globus_stat.ini get_gcp.ini globus_wait.ini make_test_dataset.ini globus_transfer_helper.ini globus_transfer_test_helper.ini endpoint_test_helper.ini make_test_dataset.ini list_collection_names.ini list_names.ini list_types.ini list_uuid.ini list_roots.ini list_other_storage_gateways.ini >>functions.sh
cat functions.sh endpoint_test.ini | awk 'NF != 0{sub(/^[\t ]*/,"");gsub(/#[A-TV-fhj-ln-rstvwz ][A-z0-9@\/\-\&,#\'\''\\\(\)"\$ ]+$/,"");gsub(/[\t ]*$/,"");print}' >endpoint_test.sh
chmod +x endpoint_test.sh
cat functions.sh test_globus.ini | awk 'NF != 0{sub(/^[\t ]*/,"");gsub(/#[A-TV-fhj-ln-rstvwz ][A-z0-9@\/\-\&,#\'\''\\\(\)"\$ ]+$/,"");gsub(/[\t ]*$/,"");print}' >test_globus.sh
chmod +x test_globus.sh

