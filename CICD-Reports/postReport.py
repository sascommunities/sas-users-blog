#!/usr/local/bin/python3
#
# postReport.py
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
#### ./postReport.py -a myAdmin                                 ####
####                -p myAdminPW                                ####
####                -sn http://myServer.sas.com                 ####
####                -an app                                     ####
####                -as appsecret                               ####
####                -i  /tmp/CICD/CarsReport.json               ####
####################################################################

import json
import argparse
from functions import authenticateUser, createReport

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

with open(inFile) as input:
    data = json.load(input)

report = createReport(serverName, token, data["location"], data["name"], data["content"])