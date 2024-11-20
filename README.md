# Deploy an enviroment in Azure, using Terraform  

The environment is prepared to deploy:  
> - A Domain controller running Windows Server 2016 Datacenter Desktop Experience  
> - An Exchange 2016 CU20 server in Windows Server 2016 Datacenter Desktop Experience  
> - A Windows 10 client machine  

## Download terraform.exe if not in path yet  
you can download terraform file from [here](https://www.terraform.io/downloads.html).  

## Logon to your Azure enviroment first  
open a windows powershell (or you can use a powershell terminal in your desired IDE) and run:  
```powershell
az login
```
Your default browser will open and request for you to logon.  
Onced logged in, the powershell window will display all your available subscriptions.  
Identify the one you want, and take note of the "id".  
Now we need to bind (or set) the Azure's subscription:  
```powershell
az account set --subscription 12345678-1234-abcd-1234-123456789012
```

## Variables that you might want to modify  

Please check "variables.tf" file to modify following variables at your desired:  

| Variable Name       | Default value | Description |
|:--------------------|:---------------:|:-------------|
| resource_group_name | _none_ | Your Resource Group name where all your resources will be created on. |
| location            | eastus | Your azure datacenter default location for all your resources. |
| PublicIP            | _none_ | Your current Public IP. This IP will be used to allow RDP connections only from your workstation. you can run the Powershell command `irm ipinfo.io` to know your current IP.|
| dcname              | DC     | Domain Controller computer name. |
| dcIP                | 10.0.2.10 | Domain Controller's internal static IP Address. |
| exname              | Ex2016    | Exchange Server computer name. | 
| Ex2016IP            | 10.0.2.16 | Exchange 2016 server's internal static IP Address. | 
| notification_email  | _none_ | This is the email account where we will send a summary email when the deployment is finished. It can be any email address. | 
| clientname          | Win10     | Windows 10 client computer name. |
| active_directory_domain | azure.lab   | The name of the Active Directory domain, for example '*_azure.lab_*' |
| active_directory_netbios_name | azure | The netbios name of the Active Directory domain, for example '*_azure_*' |
| admin_username      | labadmin  | The username associated with the local administrator account on the virtual machine |
| admin_password      | LS1setup! | The password associated with the local administrator account on the virtual machine |


## Start the deployment  
Once your are logged on to Azure, binded to your subscription and all variables in place, you can run the command:  
```powershell
.\Terraform.exe init
```

You can now run a command to get the plan of the execution, and validate all resources which will be created/modified/deleted:  
```powershell
.\Terraform.exe plan
```

If your plan looks fine, you can deploy to Azure:  
```powershell
.\Terraform.exe apply
```
_the plan will execute again. If you agree with the plan, you will be required to type the word 'yes' and hit enter._  

In case you would like to wipe all the resources and start from scratch, you can run:  
```powershell
.\Terraform.exe destroy
```

## Once the deployment finishes  

Once the deployment is ocurring, Terraform will show as finished in the terminal.
But additional tasks are running in the servers.

When it finishes, an email should be sent out to your notification email address, stating that the Exchange deploy finished successfully.
If by any change you don't get this email after a 2 hours period, connect to the Exchange server machine, open event viewer, and check the "custom view" for events.