<# 
.SYNOPSIS  
     An Azure Automation Runbook to create VMs in an availability group
 
.DESCRIPTION 
    This runbook creates a number of VMs (default 2) in an availablility group. It will create and attach extra data disks, 
    attach to domain and virtual network if required.

    Can be used with New-CloudService and New-StorageAccount to automate environment creation

    Requires an Azure Automation Credential Asset for the Run Book and one for the Local Admin for the VM as well as one for 
    the Domain Admin if needed

.PARAMETER CredentialName 
    The name of the Azure Automation Credential Asset.
    This should be created using 
    http://azure.microsoft.com/blog/2014/08/27/azure-automation-authenticating-to-azure-using-azure-active-directory/  
 
 
.PARAMETER AzureSubscriptionName 
    The name of the Azure Subscription. 

 .PARAMETER VMName
    The name of the Virtual Machines. The machines will be named VMName1, VMName2 etc depending on the NoofVMs parameter
 
.PARAMETER NoOfVms
    The number of Virtual Machines to create

.PARAMETER VMSize
    The size of the virtual machines. Values are ExtraSmall, Small, Medium, Large, 
        ExtraLarge, A5, A6, A7, A8, A9, Basic_A0, Basic_A1, Basic_A2, Basic_A3, Basic_A4, 
        Standard_D1, Standard_D2, Standard_D3, Standard_D4, Standard_D11, Standard_D12, 
        Standard_D13, Standard_D14

.PARAMETER ServiceName
    Specifies the new or existing service name.If the service does not exist, this parameter 
    will create it for you

.PARAMETER image
    Specifies the name of the virtual machine image to use for the operating system disk.
    By default this Server 2012 R2 will be used a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201412.01-en.us-127GB.vhd

.PARAMETER AdminUserCred 
    The name of the Azure Automation Local Admin Credential Asset.

.PARAMETER VNetName 
    Specifies the virtual network name where the new virtual machine will be deployed.

.PARAMETER Subnet 
    Specifies the Subnet Name.

.PARAMETER NoDataDisks 
    Specifies the number of Data Disks to add to each VM. NOTE the number available will depend on the VM size chosen
    See here for details http://msdn.microsoft.com/library/dn197896.aspx

.PARAMETER DataDiskSize
    Specifies the size of the DataDisks in GB. Defaults to 1000GB

.PARAMETER Domain
    Specifies the domain to join the Virtual Machines to

.PARAMETER DomainAdminCred
    The name of the Azure Automation Domain Admin Credential Asset.

.PARAMETER StorageAccountName
    The name of the Storage Account.

.EXAMPLE 
    New-AvailabilityGroupVM -CredentialName auto -AzureSubscriptionName 'Free Trial' `
    -VMName SQL -NoOfVms 2 -VMSize A4 -ServiceName ProjectBeard `
    -image fb83b3509582419d99629ce476bcb5c8__SQL-Server-2014-RTM-12.0.2430.0-Std-ENU-Win2012R2-cy14su11 `
    -AdminUserCred LocalAdmin  `
     -StorageAccountName thebeardsqlstorage
    
    This will create 2 Virtual Machines named SQL1 and SQL2 of size D4 in the cloud service ProjectBeard 
    using the SQL 2014 Server 2012 R2 image on the SQL subnet of the BeardNet virtual network with 4 1000Gb 
    DataDisks with a local admin from the LocalAdminCred credential and join them to TheBeard.Local domain 
    with a local admin from the LocalAdminCred credential

.EXAMPLE 
    New-AvailabilityGroupVM -CredentialName MasterCred -AzureSubscriptionName SubName -VMName AppName `
    -NoOfVms 3 -VMSize A5 -ServiceName ProjectBeard  -AdminUserCred LocalAdminCred -VNetName BeardNet `
    -Subnet App -Domain TheBeard.local -DomainAdminCred DomainAdminCred -StorageAccountName thebeardappstorage

    This will create 3 Virtual Machines named AppName1 and AppName2 of size A5 in the cloud service ProjectBeard 
    using the default Server 2012 R2 image on the App subnet of the BeardNet virtual network with a local admin 
    from the LocalAdminCred credential and join them to TheBeard.Local domain

.OUTPUTS
    None
 
.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com
            with a lot of help from 'Azure Automation - New VM Service Tier' by Wes Kroesbergen
            https://gallery.technet.microsoft.com/scriptcenter/Azure-Automation-New-VM-d6ff7c3b#content 
    DATE: 04/01/2015 
#> 

Workflow New-AvailabilityGroupVM
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$CredentialName,
        [Parameter(Mandatory=$true)]
        [string]$AzureSubscriptionName,
        [Parameter(Mandatory=$true)]
        [string]$VMName,
        [Parameter(Mandatory=$false)]
        [int]$NoOfVms = 2 ,
        [Parameter(Mandatory=$true)]
        [string]$VMSize,
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        [Parameter(Mandatory=$false)]
        [string]$image = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201412.01-en.us-127GB.vhd',
        [Parameter(Mandatory=$true)]
        [string]$AdminUserCred,
        [Parameter(Mandatory=$false)]
        [string]$VNetName,
        [Parameter(Mandatory=$false)]
        [string]$Subnet,
        [Parameter(Mandatory=$false)]
        [int]$NoDataDisks,
        [Parameter(Mandatory=$false)]
        [int]$DataDiskSize, # in GB
        [Parameter(Mandatory=$false)]
        [string]$Domain,
        [Parameter(Mandatory=$false)]
        [string]$DomainAdminCred,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName
    )        
    Write-Output "Creating VMs. Please wait for a few minutes......"
         # Get the credential to use for Authentication to Azure and Azure Subscription Name
    $Cred = Get-AutomationPSCredential -Name $CredentialName
    
    # Connect to Azure and Select Azure Subscription
    $AzureAccount = Add-AzureAccount -Credential $Cred
    $AzureSubscription = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    Set-AzureSubscription -SubscriptionName $AzureSubscriptionName -CurrentStorageAccountName $StorageAccountName

    $AvailabilitySetName = $VMName + 'AvailSet'
    Write-Output "Creating $NoOfVms VMs using $image in $ServiceName on $StorageAccountName with $NoDataDisks extra Data Disks"
    $AdminUser = Get-AutomationPSCredential -Name $AdminUserCred
    $adminuser
    $AdminUsername = $AdminUser.Username
    $AdminUsername
    $AdminPassword = $AdminUser.GetNetworkCredential().Password
    $AdminPassword

    if($DomainAdminCred)
    {
    $DomainAdmin = Get-AutomationPSCredential -Name $DomainAdminCred
    $DomainAdminUserName = $DomainAdmin.Username
    $DomainAdminPassword = $DomainAdmin.GetNetworkCredential().Password
    }
    InlineScript {
    $AdminUsername = $Using:AdminUser.Username
    $AdminPassword = $Using:AdminPassword
    $DomainAdminUserName = $Using:DomainAdminUserName
    $DomainAdminPassword = $Using:DomainAdminPassword
                #Create an array of VM Names
                $Vms = @()
                $NoOfVms = $Using:NoOfVms 
                    while ($NoOfVms -gt 0)
                        {
                        $Name = $Using:VMName + $NoOfVms
                        $Vms = $VMs + $Name
                        $NoOfVms--
                        }
                $vmConfigs = @()
                foreach ($VM in $VMs)
                    {
                    $vmConfig = New-AzureVMConfig -ImageName $Using:image -InstanceSize $Using:VMSize -Name $VM -DiskLabel "OS" 
		            # Modify provisioning config depending on whether domain join is required
                    if($Using:Domain)
                        {
                        $vmDetails = Add-AzureProvisioningConfig -VM $vmConfig -WindowsDomain -DisableAutomaticUpdates -JoinDomain $Using:Domain -Domain $Using:Domain -DomainUserName $DomainAdminUserName -DomainPassword $DomainAdminPassword -AdminUsername $AdminUsername -Password $AdminPassword
					    }
                    else
                        {
					    $vmDetails = Add-AzureProvisioningConfig -VM $vmConfig -Windows -DisableAutomaticUpdates -AdminUsername $AdminUsername -Password $AdminPassword
                        }		
                    # Set the VM subnet
                    if($Using:Subnet)
                        {
                        $subnet = Set-AzureSubnet -SubnetNames $Using:Subnet -VM $vmConfig -WarningAction SilentlyContinue 
	                    }
                    # Add any required data disks
                    $counter = 0
                    while ($counter -lt $Using:NoDataDisks)
                        {
                        $dataDiskName = "DataDisk$counter"
                        if ($Using:DataDiskSize) {$size = $Using:DataDiskSize}
                        else {$size = 1000}
                        Add-AzureDataDisk -CreateNew -DiskSizeInGB $size -DiskLabel $dataDiskName -LUN $counter -VM $vmConfig 
					    $counter++
                        }

                    Set-AzureAvailabilitySet -AvailabilitySetName $Using:AvailabilitySetName -VM $vmConfig 
                    # Add the VM configuration object to the vmConfigs array for future creation
                    $vmConfigs += $vmConfig   
                    } # end foreach

                if($Using:VNetName)
                    {
                    New-AzureVM -ServiceName $Using:ServiceName -VNetName $Using:VNetName -VMs $vmConfigs 
                    }
                else
                    {
                    New-AzureVM -ServiceName $Using:ServiceName -VMs $vmConfigs 
                    }
                }
}
