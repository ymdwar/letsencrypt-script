#! /usr/bash
# set your aliyun api
aliyun_api_key="your aliyun key"
aliyun_api_sec="your aliyum sec"
# set your domain name (eg:  example.com)
domain_name="your domain name"

function __debug() {
  echo "[`date`][DEBUG] $1 "
}

function __error(){
    echo -e “\033[41;33m[`date`][ERROR] $1 \033[0m” 
}

## only support CentOS6/7
__debug "check the the OS has been supportted."
if ! grep -qs -e "release 6." -e "release 7." /etc/redhat-release; then
    __error "This script only supports CentOS/RHEL 6 and 7."
    exit 1;
fi

if [ -z $aliyun_api_key ]; then
  __error "the aliyun_api_key and aliyun_api_key must be setting."
  exit 1;
fi

if [ -z $domain_name ]; then
   __error "the domain name must be setting."
   exit 1;
fi

__debug "the operation system and software updating...."
yum update

__debug "install nginx"
yum install -y nginx 

__debug "dowanlod acme.sh and install it. "
curl https://get.acme.sh | sh
source ~/.bashrc

__debug "acme.sh has been ready. init the variable. "

# pasrse 
domain_param=" -d $domain_name -d www.$domain_name"
     
cert_dir="/etc/my_ssl_cert"
my_key_file="$cert_dir/key.pem"
my_ca_file=$cert_dir/ca.pem    
my_cert_file=$cert_dir/cert.pem
my_fullchain_file="$cert_dir/fullchain.pem"
__debug "check the cert dir"
if [ ! -d $cert_dir ]; then
  mkdir $cert_dir
fi

__debug "export aliyun Ali_Key and Ali_Secret.  "
export Ali_Key=${aliyun_api_key}
export Ali_Secret=${aliyun_api_sec}
__debug "excute issue domain cert domain param is $domain_param"
acme.sh --debug --issue $domain_param --dns dns_ali

__debug "install cert to the cert dir"
acme.sh --debug --installcert $domain_param  \
        --keypath  $my_key_file \
        --capath   $my_ca_file \
        --certpath  $my_cert_file \
        --fullchainpath $my_fullchain_file \
        --reloadcmd  "nginx restart"  
__debug "complete"


__debug "config the firewall"
if ! systemctl is-active firewalld > /dev/null; then
    systemctl start firewalld.service
fi
firewall-cmd --permanent --add-service="nginx"
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload

systemctl enable nginx.service
systemctl restart nginx.service

__debug "complete all, enjoy it :) "
