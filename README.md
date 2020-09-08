# Terraform Onboarding

## Example

~~~hcl
module "strongdm_onboarding" {
  source = "github.com/peteroneilljr/strongdm_onboarding"

  # Prefix will be added to resource names
  prefix = "education"

  # EKS resoruces take approximately 20 min
  create_eks               = true
  # Mysql resources take approximately 5 min
  create_mysql             = true
  # RDP resources take approximately 10 min
  create_rdp               = true
  # HTTP resources take approximately 5 min
  create_http              = true
  # Kibana resources take approximately 15 min
  create_kibana            = true
  # Gateways take approximately 5 min
  create_strongdm_gateways = true

  # Leave variables set to null to create resources in default VPC.
  vpc_id     = null
  subnet_ids = null

  # List of existing users to grant resources to
  # NOTE: An error will occur if these users are already assigned to a role
  grant_to_existing_users = [
    "peter+prod@strongdm.com",
  ]

  # New accounts to create with access to all resources
  admin_users = [
    "peter+admin1@strongdm.com", 
    "peter+admin2@strongdm.com", 
    "peter+admin3@strongdm.com", 
  ]

  # New accounts to create with read-only permissions
  read_only_users = [
    "peter+user1@strongdm.com",
    "peter+user2@strongdm.com",
    "peter+user3@strongdm.com",
  ]

  # Tags will be added to strongDM and AWS resources.
  tags = {}
}
~~~

## What to build

extracted from: https://github.com/strongdm/education/issues/80

A terraform script that can be used to quickly deploy an example strongDM setup in AWS. The purpose of this terraform script is to give a trial user resources they can play with immediately. It should be delivered as a Github repository containing the Terraform scripts along with markdown documentation that tells the user:

1. How to run the scripts (environment variables, etc.)
2. What to expect
3. What to do next

### AWS Components
- Redundant EC2 instances
    - With strongDM Gateways installed
- RDS Postgres instance
    - Read-only credentials
    - Read-write credentials
- EC2 instance
    - Hosts demo web app
- _Optional_  - Windows instance
- _Optional_ - EKS Cluster

_Everything created in AWS should be tagged as created by strongDM._

### strongDM Configuration

- Gateways setup
- RDS enrolled as two datasources:
    - Read-only
    - Read-write
- EC2 instance enrolled for SSH with certificate authentication configured
- Website connecting to EC2 hosted web app
- _Optional_ - RDP datasource configured
- _Optional_ - EKS cluster configured
- High privilege strongDM role
    - Read-write RDS
    - SSH
    - Website
    - RDP
    - EKS
- Low privilege strongDM role
    - Read-only RDS
    - Website
- Admin assigned to high privilege role

_All datasources, servers, websites, clusters, and roles should be tagged in strongDM so that we can identify them in the database._

**Who are the current subject matter experts for this feature?**
Britt, Peter, Sebastian


**Are there any particular dates be aware of?**
No.


