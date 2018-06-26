#!/bin/sh
echo "#!/bin/sh" >functions.sh
cat globus_ls.ini globus_stat.ini get_gcp.ini globus_wait.ini make_test_dataset.ini globus_transfer_helper.ini globus_transfer_test_helper.ini endpoint_test_helper.ini make_test_dataset.ini list_collection_names.ini list_names.ini list_types.ini list_uuid.ini list_roots.ini >>functions.sh
cat functions.sh endpoint_test.ini >endpoint_test.sh
chmod +x endpoint_test.sh
cat functions.sh test_globus.ini >test_globus.sh
chmod +x test_globus.sh

