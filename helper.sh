#############Config GCP project

zone=tma-okd-zone
project=tma-okd
saname=okd-admin 

#authenticate to gcp
gcloud init

#create new gcp project and set as default
gcloud projects create tma-okd
gcloud config set project tma-okd


#enable billing and required APIs
#Enable billing account through Google Console
gcloud services enable compute.googleapis.com cloudapis.googleapis.com cloudresourcemanager.googleapis.com dns.googleapis.com \
iamcredentials.googleapis.com iam.googleapis.com servicemanagement.googleapis.com serviceusage.googleapis.com storage-api.googleapis.com storage-component.googleapis.com

gcloud compute project-info add-metadata    \
 --metadata google-compute-default-region=europe-west1,google-compute-default-zone=europe-west1-a


 #create DNS zone

 gcloud dns managed-zones create $zone \
    --description='DNS Zone for OKD installation' \
    --dns-name=dns-tmarkunin.xyz \
    --visibility=public

#create manualy if get error  https://cloud.google.com/dns/docs/zones/#gcloud_1


#Update the registrar records for the name servers that your domain uses
gcloud dns managed-zones describe $zone


#create service account for OKD installation
gcloud iam service-accounts create $saname \
    --description="account for OKD installation" \
    --display-name="okd-admin"

gcloud projects add-iam-policy-binding tma-okd \
    --member=serviceAccount:$saname@$project.iam.gserviceaccount.com --role=roles/owner

#generate JSON key for the service account

gcloud iam service-accounts keys create ~/key.json \
  --iam-account $saname@$project.iam.gserviceaccount.com


######################OKD installation##################
https://docs.okd.io/latest/installing/installing_gcp/installing-gcp-default.html#installing-gcp-default 

#generate SSH key

ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa

eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_rsa

#download installation file from  https://github.com/openshift/okd/releases


wget https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-07-14-153706-ga/openshift-install-linux-4.5.0-0.okd-2020-07-14-153706-ga.tar.gz

tar xvf openshift*.tar.gz

#logout from gcloud cli
gcloud auth revoke --all


#pull secret from https://cloud.redhat.com/openshift/install/pull-secret

#modify install-config.json

./openshift-install create install-config --dir=installconfig

#decrease number of master and worker nodes

./openshift-install create cluster --dir=installconfig     --log-level=info 

./openshift-install destroy cluster --dir=installconfig --log-level=info
