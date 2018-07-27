###
#
# Unmanage Node from SolarWinds
# Created by Chris Thayer - 2018
# http://www.tacoisland.net
#
# Changelog:
# v0.1 - July 27 2018 - Initial release
#
###


### Prerequisites ###
#
# SolarWinds Orion SDK
# https://github.com/solarwinds/OrionSDK/releases
#
###

### Usage and parameters ###
#
# Unmanage-SolarWindsNode.ps1 -OrionHost <orion hostname> -Username <orion username> -Password <orion password> [-Minutes <number>]
#
# OrionHost
# The hostname of your SolarWinds Orion server.
# Example: orion.domain.com
#
# Username
# Username for connecting to SolarWinds Orion
# This user must have permissions to unmanage nodes
# Example: domain\orionuser
#
# Password
# Password for the username provided
#
# Minutes
# (Optional) Number of minutes to unmanage node
# Default is 10
# Example: 2
#
# Full example:
# Unmanage-SolarWindsNode.ps1 -OrionHost orion.domain.com -Username "domain\orionuser" -Password "MyP@ssword" -Minutes 5
#
###

### BEGIN SCRIPT ###


param (
	[Parameter(Mandatory=$true)][string]$orionhost,
	[Parameter(Mandatory=$true)][string]$username,
	[Parameter(Mandatory=$true)][string]$password,
    [int]$minutes = 10
	)


# Write console output to log in temp folder
start-transcript "$($env:temp)\unmanage.log"


# Load SWIS snap in, error and quit if not installed
try {
    "Loading SWIS Snapin..."
    Add-PSSnapin SwisSnapin -ErrorAction stop
    }
catch {
    "Unable to load snap-in!"
    "Script cannot continue, exiting..."
    exit(-1)
    }


$hostname = $env:computername
"This nodes name is $hostname"


"Generating secure credentials..."
$sSecurePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($username, $sSecurePassword)


"Connecting to SolarWinds Information Service on $orionhost as user $username..."
$swis = connect-swis -credential $creds -hostname $orionhost


"Querying for node(s)..."
$oNodes = Get-SwisData -SwisConnection $swis -Query "SELECT nodeID FROM Orion.Nodes WHERE SysName LIKE '$($hostname)%'"


ForEach ($nodeID in $oNodes) {
	"Setting NodeID $nodeID unmanaged"
	$start = [DateTime]::UtcNow
	$end = [DateTime]::UtcNow.AddMinutes(10)
	Invoke-SwisVerb -SwisConnection $swis -EntityName Orion.Nodes -Verb Unmanage -Arguments @("N:$nodeID",$start,$end,"false")
}