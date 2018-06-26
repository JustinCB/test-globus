<ul>
<li><a href="../api/">APIs</a>
<ul>
<li><a href="../api/auth/">Auth</a></li>
<li><a href="../api/transfer/">Transfer</a></li>
<li><a href="../api/search/">Search</a></li>
<li><a href="https://globus-sdk-python.readthedocs.io/en/stable/">Python SDK</a></li>
<li><a href="../api/helper-pages/">Helper Pages</a></li>
</ul>
</li>
<li><a href="../how-to/">How To</a></li>
<li>Guides
<ul>
<li><a href="../globus-connect-server-installation-guide/">Globus Connect Server Installation Guide</a></li>
<li><a href="../globus-connect-server-v5-installation-guide/">Globus Connect Server v5 Installation Guide</a></li>
<li>Globus Test Guide</li>
<li><a href="../management-console-guide/">Management Console Guide</a></li>
<li><a href="../data-publication-user-guide/">Data Publication User Guide</a></li>
<li><a href="../data-publication-admin-guide/">Data Publication Admin Guide</a></li>
<li><a href="../authorization-authentication-guide/">Authorization/Authentication Guide</a></li>
<li><a href="../cli/">Command Line Interface</a></li>
<li><a href="../premium-storage-connectors/">Premium Storage Connectors</a></li>
<li><a href="../modern-research-data-portal/">Modern Research Data Portal</a></li>
</ul>
</li>
<li>Support
<ul>
<li><a href="../faq/">FAQs</a></li>
<li><a href="../security-bulletins/">Security Bulletins</a></li>
<li><a href="https://www.globus.org/mailing-lists">Mailing Lists</a></li>
<li><a href="https://www.globus.org/contact-us">Contact Us</a></li>
<li><a href="https://support.globus.org/requests">Check Support Tickets</a></li>
</ul>
</li>
</ul>
<h1>Globus Test Guide</h1>
<h2>Table of Contents</h2>
<ul><li><a href="#PREREQ">Before getting the scripts</a></li>
<li><a href="#TEST">Using test_globus.sh</a></li>
<li><a href="#END">Using endpoint_test.sh</a></li>
<li><a href="#OUT">Outputs of the scripts</a></li></ul>
<a name="PREREQ" id="PREREQ"></a><h2>Before getting the scripts</h2>
<ul><li>You must first install the globus connect server.  See the guide at <a href="https://docs.globus.org/globus-connect-server-v5-installation-guide/">https://docs.globus.org/globus-connect-server-v5-installation-guide/</a> for more information.</li>
<li>You must also install the globus-cli python package for transfers.  See the guide at <a href="https://docs.globus.org/cli/installation/">https://docs.globus.org/cli/installation/</a> for more information.</li></ul>
<a name="TEST" id="TEST"></a><h2>Using test_globus.sh</h2>
<ul><li>After installing the base globus packages, get test_globus.sh:<br />
<pre style="overflow:auto;"><code>curl -O https://github.com/JustinCB/test-globus/raw/master/test_globus.sh || wget https://github.com/JustinCB/test-globus/raw/master/test_globus.sh
chmod +x ./test_globus.sh</code></pre></li>
<li>You can then run the shell script, which will print information about all the collections on your server.  You may want to redirect the output to a file, as it produces a lot of it:<br />
<pre style="overflow:auto;"><code>./test_globus.sh >test_globus.log 2>&amp;1</code></pre></li></ul>
<a name="END" id="END"></a><h2>Using endpoint_test.sh</h2>
<ul><li>After installing the base globus packages, get endpoint_test.sh:<br />
<pre style="overflow:auto;"><code>curl -O https://github.com/JustinCB/test-globus/raw/master/endpoint_test.sh || wget https://github.com/JustinCB/test-globus/raw/master/endpoint_test.sh
chmod +x ./endpoint_test.sh</code></pre></li>
<li>You can then run the test script.  It runs the same tests as test_globus.sh, but it takes endpoint names &amp; attempts to resolve them to UUIDs &amp; generate &amp; transfer the same files to &amp; from those endpoints:<br />
<pre style="overflow:auto;"><code>./endpoint_test.sh &lt;endpoint_names> >endpoint_test.log 2>&amp;1</code></pre></li></ul>
<a name="OUT" id="OUT"></a><h2>Outputs of the scripts</h2>
<ul><li>If it succeeds, your installation of globus is most likely working.  If it fails, you can look at its output to see what went wrong:
<ul><li><ul><li><pre style="overflow:auto;"><code>Globus Connect ports 50000-51000 may be block'd in your firewall
Globus will not work if they are block'd &amp; this script will hang
You may also see this message if globus is down or the server is not yet started or is restarting</code></pre></li>
<li>Globus Connect Server requires ports 50000-51000 for transfers.  Transfers will fail if they are block'd</li></ul></li>
<li><ul><li><pre style="overflow:auto;"><code>http(s) may be block'd
Globus will not work properly if it's block'd
You may also see this message if the server is down, not yet started, or restarring</code></pre></li>
<li>Globus Connect Server won't work if https is block'd.  Globus Connect Server uses https as a control channel.</li></ul></li>
<li><ul><li><pre style="overflow:auto;"><code>Endpoint is down, so transfer probably fail'd</code></pre></li>
<li>The test scripts check the condition of the current test transfer.  If you get this, it means that the transfer was running, but the endpoint was not connected, &amp; so it would fail after a few hours, which would be much too long for a test script to continue running.  If you also get <code>Ensure connections on ports 50000-51000 aren't block'd by your firewall rules</code>, that means that the test script didn't detect anything attempting to listen on those ports, which may mean that they're block'd by your firewall.</li></ul></li>
<li><ul><li><pre style="overflow:auto;"><code>Transfer fail'd because endpoint is down</code></pre></li>
<li>This means that the endpoint fail'd to connect.  If you also got <code>Ensure connections on ports 50000-51000 aren't block'd by your firewall rules</code>, this means that you should check your firewall because they probably <i>are</i> block'd</li></ul></li>
<li><ul><li><pre style="overflow:auto;"><code>Test Error: Transfer timed out/finished &amp; is paused or canceled</code></pre></li>
<li>This means that the transfer was paused or canceled.  The script will exit because if it didn't it would hang indefinitely.</li></ul></li>
<li><ul><li><pre style="overflow:auto;"><code>&lt;file> fail'd with &lt;options></code></pre></li>
<li>The test scripts verify that the files were not changed after being transfer'd.  If you get this message, that means that the file changed in transfer, which is a problem.</li></ul></li></ul></li></ul>
</body>
</html>
