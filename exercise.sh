# Make the bug happen.




# get our tunnel ip.
export FLEETCTL_TUNNEL=$(gcloud compute instances list --regex ci8-host-a --format json | sed -n '/"natIP":/ s/.*[^0-9.]\([0-9.]\+\)[^0-9.].*/\1/p')

fleetctl list-units


fleetctl submit systemd-reload.service
fleetctl start systemd-reload.service

cp issue8@.service-before issue8@.service

fleetctl submit issue8@.service other-helper@.service
fleetctl load issue8@1.service issue8@2.service issue8@3.service issue8@4.service issue8@5.service
fleetctl load other-helper@1.service other-helper@2.service other-helper@3.service other-helper@4.service other-helper@5.service
fleetctl start issue8@1.service issue8@2.service issue8@3.service issue8@4.service issue8@5.service

echo "Just launched:"
fleetctl list-units

# Those services (artificially) take 15 seconds to start.

sleep 20

echo "Should all be running:"
fleetctl list-units


# Upload an altered issue8 service file
cp issue8@.service-after issue8@.service
fleetctl --debug destroy issue8@.service
fleetctl --debug submit issue8@.service

# Rolling upgrade:

for ((id=1; id<=5; id++)); do
  fleetctl --debug destroy issue8@$id.service
  fleetctl --debug load issue8@$id.service
  fleetctl --debug start issue8@$id.service
  sleep 10
done

echo "Should all be updated, and either running or in start-pre"
fleetctl --debug list-units

# But the other-helper's are all dead, because "No such file or directory".
fleetctl --debug status other-helper@1.service

