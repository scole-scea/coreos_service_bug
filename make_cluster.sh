# Script to make a cluster for testing unit files stuck in a "No such
# file or directory" state.

# We make 5 nodes, all set up with etcd & fleet on CoreOS, but
# otherwise nothing special.

# Note: The environment variable SSH_SOURCE_CIDR should be set to a
# CIDR where you'd like to ssh from. In our case, this is the external
# address of our corporate firewall; obviously it'll be something
# different for other people.

token=$(curl -s https://discovery.etcd.io/new)

cat << EOF > cloud-config.txt
#cloud-config
coreos:
  etcd:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    discovery: $token
    # multi-region and multi-cloud deployments need to use \$public_ipv4
    addr: \$private_ipv4:4001
    peer-addr: \$private_ipv4:7001
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
EOF


# Make a network
gcloud compute networks create coreos-issue-8
# Make firewall rules
gcloud compute firewall-rules create ci8-internal --network coreos-issue-8 --allow icmp tcp:1-65535 udp:1-65535 --source-ranges 10.240.0.0/16 &
gcloud compute firewall-rules create ci8-allow-ssh --network coreos-issue-8 --allow tcp:22 --source-ranges $SSH_SOURCE_CIDR &
wait

if false; then
# Make 5 instances
gcloud compute instances create ci8-host-{a..e}                                            \
                                --zone us-central1-a                                       \
                                --metadata-from-file user-data=cloud-config.txt            \
                                --network coreos-issue-8                                   \
                                --image coreos                                             \
                                --scopes bigquery datastore sql storage-rw userinfo-email  \
                                --machine-type n1-standard-1                               \
                                --maintenance-policy MIGRATE &


wait

else

for id in a b c d e; do
  gcloud compute instances create ci8-host-$id         \
                                  --zone us-central1-a                                       \
                                  --metadata-from-file user-data=cloud-config.txt            \
                                  --network coreos-issue-8                                   \
                                  --image coreos                                             \
                                  --scopes bigquery datastore sql storage-rw userinfo-email  \
                                  --machine-type n1-standard-1                               \
                                  --maintenance-policy MIGRATE
  sleep 2
done

fi