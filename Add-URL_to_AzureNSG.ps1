# ***************************************************************************
#
# Purpose: Add URL to NSG using IP lookup
#
# ------------- DISCLAIMER -------------------------------------------------
# This script code is provided as is with no guarantee or waranty concerning
# the usability or impact on systems and may be used, distributed, and
# modified in any way provided the parties agree and acknowledge the 
# Microsoft or Microsoft Partners have neither accountabilty or 
# responsibility for results produced by use of this script.
#
# Microsoft will not provide any support through any means.
# ------------- DISCLAIMER -------------------------------------------------
#
# ***************************************************************************

if (Get-Module -Name AzureRM -ListAvailable) {
    Write-Warning -Message 'Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.'
 } else {
   # Install-Module -Name Az -AllowClobber -Scope CurrentUser -Verbose
 }
 
 #Script Varibles
 $SubscriptionId = "Put Your Tenat ID Here"
 $nsgNames = @('DEV-NSG', 'DEV-NSG2')
 $ruleDesc = "Add URL to NSG"
 $rulePort = 443
 $priority = 2000 #Starting Number for your Priority
 
 #Your List of URLS
 $URLS = @(
     'crl.microsoft.com'
     'go.microsoft.com'
     'activation.sls.microsoft.com'
     'sts.manage.microsoft.com'
     'autodiscover.microsoftsecurityexperts.onmicrosoft.com'
     'global.sts.msidentity.com'
     'portal.cloudappsecurity.com'
     '*.microsoft.com'
     )
 
 #Logging into Azure and Setting your subscription
 Connect-AzAccount -SubscriptionId $SubscriptionId
 
 #Function To update NSG
 function AddOrUpdateURLRecord {
     Process {
         $ruleName="URL-$u"
         $nsg = Get-AzNetworkSecurityGroup -Name $_
         $ruleExists = (Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg).Name.Contains($ruleName);
         $rule = $nsg | Get-AzNetworkSecurityRuleConfig -Name $ruleName
         if($ruleExists)
         {
             # Update the existing rule with the new IP address
             Set-AzNetworkSecurityRuleConfig `
                 -Name $ruleName `
                 -Description $ruleDesc `
                 -Access Allow `
                 -Protocol TCP `
                 -Direction Outbound `
                 -Priority $rule.Priority `
                 -SourceAddressPrefix * `
                 -SourcePortRange * `
                 -DestinationAddressPrefix $ipV4 `
                 -DestinationPortRange $rulePort `
                 -NetworkSecurityGroup $nsg
         }
         else
         {
             # Create a new rule
             $nsg | Add-AzNetworkSecurityRuleConfig `
                 -Name $ruleName `
                 -Description $ruleDesc `
                 -Access Allow `
                 -Protocol TCP `
                 -Direction Outbound `
                 -Priority $priority `
                 -SourceAddressPrefix * `
                 -SourcePortRange * `
                 -DestinationAddressPrefix $ipV4 `
                 -DestinationPortRange $rulePort
         }
 
         # Save changes to the NSG
         $nsg | Set-AzNetworkSecurityGroup
     }
 }
 
 #Core Loop through all URLS to create Rules
     ForEach ($u in $URLS){
 
     $ipV4 = [System.Net.Dns]::GetHostAddresses("$u")
     $priority++
     $nsgNames | AddOrUpdateURLRecord
 
     }
