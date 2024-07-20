# Variables to set
$terraformCloudToken = "" # Replace with your Terraform Cloud API token
$organizationName = "RCHomeLab"  # Replace with your Terraform Cloud organization name
$workspaceName = "azure-jmusicbot"  # Replace with your Terraform Cloud workspace name
$tfVarsFilePath = "terraform.tfvars"  # Replace with the path to your terraform.tfvars file

# Check if terraform.tfvars file exists
if (-not (Test-Path $tfVarsFilePath)) {
    Write-Host "The terraform.tfvars file does not exist at the specified path: $tfVarsFilePath" -ForegroundColor Red
    exit 1
}

# Read the terraform.tfvars file
$tfVars = Get-Content -Path $tfVarsFilePath | Where-Object { $_ -match "=" }

# Prepare headers for Terraform Cloud API
$headers = @{
    "Authorization" = "Bearer $terraformCloudToken"
    "Content-Type"  = "application/vnd.api+json"
}

# Get the workspace ID
$workspaceUrl = "https://app.terraform.io/api/v2/organizations/$organizationName/workspaces/$workspaceName"
$response = Invoke-RestMethod -Uri $workspaceUrl -Headers $headers -Method Get
$workspaceId = $response.data.id

if (-not $workspaceId) {
    Write-Host "Failed to get the workspace ID. Please check your organization name and workspace name." -ForegroundColor Red
    exit 1
}

# Iterate through each variable in the terraform.tfvars file and set them as environment variables in Terraform Cloud
foreach ($line in $tfVars) {
    $splitLine = $line -split "=", 2
    $key = $splitLine[0].Trim()
    $value = $splitLine[1].Trim() -replace '^"|"$', ''
    $envVarName = "TF_VAR_$key"

    $payload = @{
        data = @{
            type = "vars"
            attributes = @{
                key = $envVarName
                value = $value
                category = "env"
                hcl = $false
                sensitive = $false
            }
            relationships = @{
                workspace = @{
                    data = @{
                        type = "workspaces"
                        id = $workspaceId
                    }
                }
            }
        }
    } | ConvertTo-Json -Depth 4

    $variableUrl = "https://app.terraform.io/api/v2/workspaces/$workspaceId/vars"
    $response = Invoke-RestMethod -Uri $variableUrl -Headers $headers -Method Post -Body $payload

    if ($response) {
        Write-Host "Set environment variable $envVarName = $value in Terraform Cloud workspace $workspaceName"
    } else {
        Write-Host "Failed to set environment variable $envVarName = $value in Terraform Cloud workspace $workspaceName" -ForegroundColor Red
    }
}

Write-Host "All variables from terraform.tfvars have been set as environment variables in the Terraform Cloud workspace with the TF_VAR_ prefix."