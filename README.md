# Azure Hub-Spoke Network with Firewall (Bicep)

This project contains Bicep templates to deploy a secure **Hub and Spoke** network topology in Microsoft Azure.

The architecture includes a central **Hub** virtual network that hosts shared services like **Azure Firewall**, **Azure Bastion**, and a **VPN Gateway**. It is connected to two separate **Spoke** virtual networks. All traffic between the spokes and to/from the internet is routed through and inspected by the Azure Firewall, providing a centralized point for security and control.

This setup is ideal for organizations looking to centralize network management, security, and connectivity in a scalable way.

***

## Architecture

The Bicep template will deploy the following infrastructure:

* **A Hub Virtual Network**: Contains dedicated subnets for:
    * Azure Firewall (`AzureFirewallSubnet`)
    * Azure Bastion (`AzureBastionSubnet`)
    * VPN Gateway (`GatewaySubnet`)
* **Two Spoke Virtual Networks**: Each with a single subnet for workload resources.
* **VNet Peering**: Bidirectional peering is established between the Hub and each Spoke.
* **Azure Firewall**: A managed, cloud-based network security service.
    * All outbound traffic from the spokes is forced through the firewall using Route Tables.
    * Pre-configured with sample rules to demonstrate traffic control.
* **Route Tables**: User-Defined Routes (UDRs) on each spoke subnet to direct all traffic (`0.0.0.0/0`) to the Azure Firewall.
* **Test Virtual Machines**: An Ubuntu VM is deployed in each spoke to help validate the setup.
* **Azure Bastion**: Provides secure and seamless RDP/SSH connectivity to your virtual machines directly from the Azure portal over SSL.
* **VPN Gateway**: Enables hybrid connectivity between your on-premises network and Azure.
* **Public IP Addresses**: Separate static public IPs for the Firewall, Bastion Host, and VPN Gateway.

***

## Prerequisites

* An active **Azure subscription**.
* **Azure CLI** or **Azure PowerShell** installed on your local machine.
* Sufficient permissions to create resources in the target Azure subscription (e.g., Owner or Contributor role).

***


## Deployment Steps

You can deploy this Bicep file using either Azure CLI or Azure PowerShell.

### 1. Clone the Repository

```sh
git clone <your-repo-url>
cd <your-repo-directory>
```

### 3. Deploy the Bicep File
Deploy the resources to the resource group you just created. You will be prompted to enter the adminPassword.

#### Azure CLI


```Bash
az deployment group create \
  --resource-group MyResourceGroup \
  --template-file main.bicep \
  --parameters adminPassword=<Your-Secure-Password>
```

#### Azure PowerShell

```PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName MyResourceGroup `
  -TemplateFile main.bicep `
  -adminPassword (Read-Host -AsSecureString -Prompt "Enter VM Admin Password")
```
**Note**: The deployment can take a significant amount of time, primarily due to the creation of the Azure Firewall and VPN Gateway resources (often 30+ minutes).

## Post-Deployment Validation
After the deployment is complete, you can validate the setup by testing the firewall rules.

**1. Find Resource IPs**: In the Azure Portal, navigate to your resource group and find the Public IP of the Azure Firewall (HubFirewallPublicIP) and the private IPs of the two VMs (VM1inSpoke1 and VM2inSpoke2).

**2. Connect via Bastion**:

* Go to the VM1inSpoke1 virtual machine resource in the Azure Portal.

* Click on Connect -> Bastion.

* Enter the adminUsername and adminPassword you provided during deployment to start an SSH session in your browser.

**3. Test Spoke-to-Spoke Communication (Network Rule)**:

* Inside the Bastion session for VM1inSpoke1, ping the private IP of the second VM. This traffic is routed through the firewall and should be allowed by the ICMP network rule.


```Bash
ping <private-ip-of-vm2>
```

**4. Test Outbound to Internet (Application Rule)**:

* From the same Bastion session, test the application rule allowing access to Google.


```Bash
curl -I [www.google.com](https://www.google.com)
# You should receive an HTTP/2 200 OK response.
```
**5. Test Inbound from Internet (NAT Rule)**:

* From your local machine (not the Bastion session), try to SSH to VM2inSpoke2 using the Firewall's public IP address. This connection is translated by the DNAT rule on the firewall.


```Bash
ssh <adminUsername>@<firewall-public-ip>
```
### License
This project is licensed under the MIT License. See the LICENSE file for details.