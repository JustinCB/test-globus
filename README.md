*   [APIs](https://docs.globus.org/api/)
    *   [Auth](https://docs.globus.org/api/auth/)
    *   [Transfer](https://docs.globus.org/api/transfer/)
    *   [Search](https://docs.globus.org/api/search/)
    *   [Python SDK](https://globus-sdk-python.readthedocs.io/en/stable/)
    *   [Helper Pages](https://docs.globus.org/api/helper-pages/)
*   [How To](https://docs.globus.org/how-to/)
*   Guides
    *   [Globus Connect Server Installation Guide](https://docs.globus.org/globus-connect-server-installation-guide/)
    *   [Globus Connect Server v5 Installation Guide](https://docs.globus.org/globus-connect-server-v5-installation-guide/)
    *   Globus Test Guide
    *   [Management Console Guide](https://docs.globus.org/management-console-guide/)
    *   [Data Publication User Guide](https://docs.globus.org/data-publication-user-guide/)
    *   [Data Publication Admin Guide](https://docs.globus.org/data-publication-admin-guide/)
    *   [Authorization/Authentication Guide](https://docs.globus.org/authorization-authentication-guide/)
    *   [Command Line Interface](https://docs.globus.org/cli/)
    *   [Premium Storage Connectors](https://docs.globus.org/premium-storage-connectors/)
    *   [Modern Research Data Portal](https://docs.globus.org/modern-research-data-portal/)
*   Support
    *   [FAQs](https://docs.globus.org/faq/)
    *   [Security Bulletins](https://docs.globus.org/security-bulletins/)
    *   [Mailing Lists](https://www.globus.org/mailing-lists)
    *   [Contact Us](https://www.globus.org/contact-us)
    *   [Check Support Tickets](https://support.globus.org/requests)
# Globus Test Guide
## Table of Contents

*   <a href="#INTRO">Introduction</a>
*   [Before getting the scripts](#PREREQ)
*   [Using test_globus.sh](#TEST)
*   [Using endpoint_test.sh](#END)
*   [Outputs of the scripts](#OUT)

<a name="INTRO" id="INTRO"></a><h2>Introduction</h2>
<p>I'm sure you have two questions: what is this for? &amp; how can I use it?  These two scripts are designed for to test endpoints &amp; to get information that can help troubleshooting.  They are designed to work with GCS(Globus Connect Server) version 5.  If you manage to get them working with GCSv4, you should probably fork them on github.  test_globus.sh will print information on all your collections &amp; storage gateways.  Storage gateways are set up with your server &amp; collections are set up with globus so you can transfer to &amp; from them.  endpoint_test.sh attempts to look up endpoints/collections that you supply on the command line &amp; runs the same tests with them as test_globus.sh runs with your local collections on your server.  The lookup can sometimes have trouble, though, but you can also pass it a UUID, which isn't as likely to have trouble on lookup.</p>

<a name="PREREQ" id="PREREQ"></a>
## Before getting the scripts

*   You must first install the globus connect server. See the guide at <https://docs.globus.org/globus-connect-server-v5-installation-guide/> for more information.
*   You must also install the globus-cli python package for transfers. See the guide at <https://docs.globus.org/cli/installation/> for more information.

<a name="TEST" id="TEST"></a>
## Using test_globus.sh
*   After installing the base globus packages, get test_globus.sh:  

        curl -O https://raw.githubusercontent.com/JustinCB/test-globus/master/test_globus.sh || wget https://raw.githubusercontent.com/JustinCB/test-globus/master/test_globus.sh
        chmod +x ./test_globus.sh
*   You can then run the shell script, which will print information about all the collections on your server. You may want to redirect the output to a file, as it produces a lot of it:  

        ./test_globus.sh >test_globus.log 2>&1
<a name="END" id="END"></a>
## Using endpoint_test.sh
*   After installing the base globus packages, get endpoint_test.sh:  

        curl -O https://raw.githubusercontent.com/JustinCB/test-globus/master/endpoint_test.sh || wget https://raw.githubusercontent.com/JustinCB/test-globus/master/endpoint_test.sh
        chmod +x ./endpoint_test.sh
*   You can then run the test script. It runs the same tests as test_globus.sh, but it takes endpoint names & attempts to resolve them to UUIDs & generate & transfer the same files to & from those endpoints:  

        ./endpoint_test.sh <endpoint_names_or_uuids> >endpoint_test.log 2>&1
<a name="OUT" id="OUT"></a>
## Outputs of the scripts
*   If it succeeds, your installation of globus is most likely working. If it fails, you can look at its output to see what went wrong:
    *   *        Globus Connect ports 50000-51000 may be block'd in your firewall
                 Globus will not work if they are block'd & this script will hang
                 You may also see this message if globus is down or the server is not yet started or is restarting
        *   Globus Connect Server requires ports 50000-51000 for transfers. Transfers will fail if they are block'd
    *   *        http(s) may be block'd
                 Globus will not work properly if it's block'd
                 You may also see this message if the server is down, not yet started, or restarring
        *   Globus Connect Server won't work if https is block'd. Globus Connect Server uses https as a control channel.
    *   *        Endpoint is down, so transfer probably fail'd
        *   The test scripts check the condition of the current test transfer. If you get this, it means that the transfer was running, but the endpoint was not connected, & so it would fail after a few hours, which would be much too long for a test script to continue running. If you also get `Ensure connections on ports 50000-51000 aren't block'd by your firewall rules`, that means that the test script didn't detect anything attempting to listen on those ports, which may mean that they're block'd by your firewall.
    *   *        Transfer fail'd because endpoint is down
        *   This means that the endpoint fail'd to connect. If you also got `Ensure connections on ports 50000-51000 aren't block'd by your firewall rules`, this means that you should check your firewall because they probably _are_ block'd
    *   *        Test Error: Transfer timed out/finished & is paused or canceled
        *   This means that the transfer was paused or canceled. The script will exit because if it didn't it would hang indefinitely.
    *   *        <file> fail'd with <options>
        *   The test scripts verify that the files were not changed after being transfer'd. If you get this message, that means that the file changed in transfer, which is a problem.
