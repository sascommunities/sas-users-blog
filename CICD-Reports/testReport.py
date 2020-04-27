#!/usr/local/bin/python3
#
# testReport.py
# Xavier Bizoux, GEL
# March 2020
#
# Test report as part of a CI/CD process
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
#### ./testReport.py -a myAdmin                                 ####
####                -p myAdminPW                                ####
####                -sn http://myServer.sas.com:80              ####
####                -an app                                     ####
####                -as appsecret                               ####
####                -i  /tmp/CICD/CarsReport.json               ####
####################################################################

import json
import argparse
import os
from functions import authenticateUser, getReportImage

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
parser.add_argument("-i",
                    "--input",
                    help="File to collect the report information. For example a GIT repository location",
                    required=True)


# Read the arguments from the command line
args = parser.parse_args()
adminUser = args.adminuser
adminPW = args.password
serverName = args.servername
applicationName = args.applicationname
applicationSecret = args.applicationsecret
inFile = args.input

# Authenticate administrative user and get authentication token
token = authenticateUser(serverName, adminUser, adminPW,
                         applicationName, applicationSecret)

# Read information from the JSON file
with open(inFile) as input:
    data = json.load(input)

# Generate an image from the first section of the report
reportImage = getReportImage(serverName, token, data["location"], data["name"])

# Collect performance data from the image generation
perfData = {
    "testDate": reportImage["creationTimeStamp"],
    "duration": reportImage["duration"]
}

# Write the performance data to the perf file of the report.
# If the file doesn't exist, it will be created automatically.
outFile = inFile.replace(".json", ".perf")
if os.path.isfile(outFile):
    with open(outFile) as out:
        data = json.load(out)
        data["performance"].append(perfData)
else:
    data = {"name": data["name"],
            "location": data["location"], "performance": [perfData]}

with open(outFile, "w") as out:
    json.dump(data, out)