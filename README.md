# Stuck Service Files Example

This is a set of two scripts that demonstrate the issue we're currently having with Fleet services getting
stuck in a loaded-but-missing state, with systemd reporting "No such file or directory".

The first script is `make_cluster.sh` which uses Google Compute Engine commands to bring up a 5-node CoreOS cluster,
hosted in Google's cloud. It uses your own Google account credentials, so if you don't have access to the Google cloud, 
it won't work and you'll need to build a cluster some other way.

The second script is `exercise.sh` which first uses a Google Cloud command to find an external IP addresses for
one of the nodes in the cluster, and then sets `FLEETCTL_TUNNEL` to communicate that way. Then the script launches a service
called `issue8` on each of the nodes, which also causes `other-helper` to also launch.

Then it "updates" the `issue8` service, and performs a rolling upgrade on the cluster.

And at the result, all of the `other-helper` services are stuck dead.

```
scole@scole-kobold:~/devops/issue8 (master)$ fleetctl status other-helper@2.service
● other-helper@2.service
   Loaded: not-found (Reason: No such file or directory)
   Active: inactive (dead) since Fri 2015-03-20 20:11:16 UTC; 2min 53s ago
 Main PID: 1593
   CGroup: /system.slice/system-other\x2dhelper.slice/other-helper@2.service
           ├─1593 /bin/bash -c while true; do sleep 120; done
           └─1743 sleep 120

Mar 20 20:10:31 ci8-host-a.c.ace-ripsaw-671.internal systemd[1]: Starting CoreOS/bugs/issues/8 helper service...
Mar 20 20:10:31 ci8-host-a.c.ace-ripsaw-671.internal systemd[1]: Started CoreOS/bugs/issues/8 helper service.
Mar 20 20:11:16 ci8-host-a.c.ace-ripsaw-671.internal systemd[1]: Stopping CoreOS/bugs/issues/8 helper service...
Mar 20 20:11:16 ci8-host-a.c.ace-ripsaw-671.internal systemd[1]: Stopped CoreOS/bugs/issues/8 helper service.
Mar 20 20:11:20 ci8-host-a.c.ace-ripsaw-671.internal systemd[1]: Cannot add dependency job for unit other-helper@2.service, ignoring: Unit other-helper@2.service failed to load: No such file or directory.
scole@scole-kobold:~/devops/issue8 (master)$ 
```
