
# Installing Terraform Enterprise in demo mode and recovering it from snapshot 

In this project we will provide TF code that builds an environment in AWS Cloud and install Terraform Enterprise in a NAT instance. In case of previous snapshots present, the installation will revet to the last one.

## About Terraform Enterprise
Terraform Enterprise is on-prem version of Terraform Cloud. This means that it implements the functionality of Terraform Cloud in private managed and secured infrastructure with additional enterprise-grade architectural features like audit logging and SAML single sign-on.


### Prerequisites
 - Install Terraform CLI:
Download and install accordingly to your OS as described here:
https://www.terraform.io/downloads.html




### Open a terminal


 OS system | Operation
 ------------ | -------------
| Windows | Start menu -> Run and type cmd |
| Linux  |Start terminal |
| macOS | Press Command - spacebar to launch Spotlight and type "Terminal," then double-click the search result. |

### Download this repo
- clone the repo locally
```
clone git@github.com:yaroslav-007/vagrant-ptfe-demo-self-automated.git
cd vagrant-ptfe-demo-self-automated
```
# Prerequisite tasks

 - In main.tf AWS credentials should be populated
 - In ./key ssh keys should be generated
 - You have to have a domain and create zone in aws (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) and populate its id in dns.tf
 - Obtain a license for TFE and located in ./ptfe-ec2/license-file.rli
 - Check ./ptfe-ec2/settings.json and ./ptfe-ec2/replicated.conf and change the domain that you will use.



### Run terrafom 

Run terraform to build the infrastructure:
`terraform apply`

### Make snapshot
Open a browser for location `https://ptfe.example.com:8800/` (you should be able to access the ptfe instance for example with socks described here: https://www.digitalocean.com/community/tutorials/how-to-route-web-traffic-securely-without-a-vpn-using-a-socks-tunnel)

On the top right you can initiate a snapshot by clicking on `Start Snapshot` 


### Destroy the ptfe instance.

From AWS Console destroy the ptfe instance and run `terraform apply` again. It will rebuild ptfe instance and restore form snapshot if it is present. 