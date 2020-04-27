#!/usr/local/bin/python3
#
# getReport.py
# Xavier Bizoux, GEL
# March 2020
#
# Extract report information to be used in a CI/CD process
#
# Change History
#
# sbxxab 24MAR2020
#
####################################################################
#### DISCLAIMER                                                 ####
####################################################################
#### This program  provided as-is, without warranty             ####
#### of any kind, either express or implied, including, but not ####
#### limited to, the implied warranties of merchantability,     ####
#### fitness for a particular purpose, or non-infringement.     ####
#### SAS Institute shall not be liable whatsoever for any       ####
#### damages arising out of the use of this documentation and   ####
#### code, including any direct, indirect, or consequential     ####
#### damages. SAS Institute reserves the right to alter or      ####
#### abandon use of this documentation and code at any time.    ####
#### In addition, SAS Institute will provide no support for the ####
#### materials contained herein.                                ####
####################################################################

####################################################################
#### COMMAND LINE EXAMPLE                                       ####
####################################################################
#### ./getReport.py -a myAdmin                                  ####
####                -p myAdminPW                                ####
####                -sn http://myServer.sas.com:80              ####
####                -an app                                     ####
####                -as appsecret                               ####
####                -rl "/Users/sbxxab/My Folder"               ####
####                -rn CarsReport                              ####
####                -o  /tmp/CICD                               ####
####################################################################
import json
import argparse
from functions import authenticateUser, getReportContent

# Define arguments for command line execution
parser = argparse.ArgumentParser(
    description="Extract report information to be used in a CI/CD process")
parser.add_argument("-a",
                    "--adminuser",
                    help="User used for the Viya connection and who will update the preferences.",
                    required=True)
parser.add_argument("-p",
                    "--password",
                    help="Password for the administrater user.",
                    required=True)
parser.add_argument("-sn",
                    "--servername",
                    help="URL of the Viya environment (including protocol and port).",
                    required=True)
parser.add_argument("-an",
                    "--applicationname",
                    help="Name of the application defined based on information on https://developer.sas.com/apis/rest/",
                    required=True)
parser.add_argument("-as",
                    "--applicationsecret",
                    help="Secret for the application based on information on https://developer.sas.com/apis/rest/",
                    required=True)
parser.add_argument("-rl",
                    "--reportlocation",
                    help="Location of the report within SAS Viya",
                    required=True)
parser.add_argument("-rn",
                    "--reportname",
                    help="Name of the report within SAS Viya",
                    required=True)
parser.add_argument("-o",
                    "--output",
                    help="Path to save the report information. For example a GIT repository location",
                    required=True)


# Read the arguments from the command line
args = parser.parse_args()
adminUser = args.adminuser
adminPW = args.password
serverName = args.servername
applicationName = args.applicationname
applicationSecret = args.applicationsecret
reportLocation = args.reportlocation
reportName = args.reportname
gitFolder = args.output

# Authenticate administrative user and get authentication token
token = authenticateUser(serverName, adminUser, adminPW,
                         applicationName, applicationSecret)

# Extract BIRD representation of the report
reportContent = getReportContent(serverName, token, reportLocation, reportName)

# Create a JSON representation of the report
data = {"name": reportName, "location": reportLocation,
        "content": reportContent.json()}

# Generate output file
outFile = gitFolder + reportName + ".json"
with open(outFile, "w") as out:
    json.dump(data, out)