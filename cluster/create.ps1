param(
   [string] [Parameter(Mandatory = $true)] $Name,
   [string] [Parameter(Mandatory = $true)] $TemplateName,    # Name of the cluster ARM template - Options are 'silver.json' or 'onenode.json'
   [int] [Parameter(Mandatory = $true)] $InstanceCount,      # Number of Nodes to create. 'silver' requires at least 5 nodes.
   [string] [Parameter(Mandatory = $true)] $Location,         # Physical location of all the resources - Use this format 'centralus'
   [string] [Parameter(Mandatory = $true)] $TenantId,
   [string] [Parameter(Mandatory = $true)] $ClusterApplicationId,
   [string] [Parameter(Mandatory = $true)] $ClientApplicationId
)

. "$PSScriptRoot\..\Common.ps1"

$ResourceGroupName = "$Name-rg"  # Resource group everything will be created in
$KeyVaultName = "$Name-vault"    # Name of the Key Vault
$rdpPassword = "Password00;;"

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

# Ensure resource group we are deploying to exists.
EnsureResourceGroup $ResourceGroupName $Location

# Ensure that the Key Vault resource exists.
$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

# Ensure that self-signed certificate is created and imported into Key Vault
$cert = EnsureSelfSignedCertificate $KeyVaultName $Name

Write-Host "Applying cluster template $TemplateName..."
$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $cert.Thumbprint;
    sourceVaultResourceId = $keyVault.ResourceId;
    certificateUrlValue = $cert.SecretId;
    rdpPassword = $rdpPassword;
    vmInstanceCount = $InstanceCount;
    aadTenantId = $TenantId;
    aadClusterApplicationId = $ClusterApplicationId;
    aadClientApplicationId = $ClientApplicationId;
  }

New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\$TemplateName" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose