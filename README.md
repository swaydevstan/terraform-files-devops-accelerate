# Terraform manifests to deploy Azure resources
> Terraform manifests to deploy a load balancer, single VM instance and virtual machine scale sets to Azure

This repository conatins solutions to DevOps Accelerate Infrastructure as code. Resources created as required are shown below:

* Images showing Terraform plan output for single VM Instance
  ![Plan Output 1](./images/single-instance-plan-1.PNG)
  ![Plan Output 1](./images/single-instance-plan-2.PNG)

* Image showing Terraform plan output for single VM Instance
  ![Apply Output](./images/single-instance-apply-results.PNG)

* Image showing running single VM Instance
  ![Running VM](./images/single-instance-running.PNG)

* Image showing deployed loadbalancer 
  ![Running LB](./images/loadbalancer.PNG)


### Use command below to deploy resources to your Azure Cloud Environment
- `terraform init` - To initialize the working directory and pull down the provider
- `terraform plan` - To go through a "check" and confirm the configurations are valid
- `terraform apply` - To create the resource