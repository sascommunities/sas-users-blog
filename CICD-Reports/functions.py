import requests
import json
import time


def authenticateUser(serverName, adminUser, adminPW, appName, appSecret):
    # Function to authenticate the administrative user and get the authentication token
    url = "{0:s}/SASLogon/oauth/token".format(serverName)
    data = {"grant_type": "password",
            "username": adminUser,
            "password": adminPW}
    auth = (appName, appSecret)
    headers = {'Content-type': 'application/x-www-form-urlencoded'}
    auth_r = requests.post(url, data=data, auth=auth, headers=headers)
    return auth_r.json()['access_token']


def getFolder(serverName, token, location):
    # Function to retrieve folder information
    url = "{0:s}/folders/folders/@item".format(serverName)
    parameters = {"path": location}
    headers = {
        'Accept': 'application/vnd.sas.content.folder+json',
        'authorization': 'Bearer ' + token
    }
    folder = requests.get(url, params=parameters, headers=headers)
    return folder.json()


def getReport(serverName, token, location, name):
    # Function to retrieve report information
    folderId = getFolder(serverName, token, location)['id']
    url = "{0:s}/folders/folders/{1:s}/members".format(
        serverName, folderId)
    parameters = {"filter": 'contains(name,"' + name + '")'}
    headers = {
        'Accept': 'application/vnd.sas.collection+json',
        'Accept-Language': 'string',
        'authorization': 'Bearer ' + token
    }
    report = requests.get(url, params=parameters, headers=headers)
    return report.json()['items'][0]


def getReportContent(serverName, token, location, name):
    # Function to retrieve the BIRD representation of the report
    reportUri = getReport(serverName, token, location, name)['uri']
    url = "{0:s}{1:s}/content".format(serverName, reportUri)
    parameters = {}
    headers = {
        'Accept': 'application/vnd.sas.report.content+json',
        'Accept-Language': 'string',
        'authorization': 'Bearer ' + token
    }
    content = requests.get(url, params=parameters, headers=headers)
    return content


def deleteReport(serverName, token, reportUri):
    # Function to delete an existing report based on a provided URI
    url = "{0:s}{1:s}".format(serverName, reportUri)
    headers = {
        'Accept': '*/*',
        'authorization': 'Bearer ' + token
    }
    requests.delete(url, headers=headers)


def updateReportContent(serverName, token, report, reportContent):
    url = "{0:s}/reports/reports/{1:s}/content".format(
        serverName, report.json()['id'])
    body = reportContent
    headers = {
        'Content-Type': 'application/vnd.sas.report.content+json',
        'If-Match': report.headers["ETag"],
        'authorization': 'Bearer ' + token
    }
    requests.put(url,
                 json=body,
                 headers=headers)


def createReport(serverName, token, location, reportName, reportContent):
    try:
        reportUri = getReport(
            serverName, token, location, reportName)['uri']
        deleteReport(serverName, token, reportUri)
    except IndexError:
        print("Report not {0:s} found in {1:s}".format(
            reportName, location))
    folderId = getFolder(serverName, token, location)["links"][0]['uri']
    url = "{0:s}/reports/reports".format(serverName)
    body = {"name": reportName,
            "description": reportName}
    parameters = {"parentFolderUri": folderId}
    headers = {
        'Content-Type': 'application/vnd.sas.report+json',
        'Accept': 'application/vnd.sas.report+json',
        'authorization': 'Bearer ' + token
    }
    report = requests.post(url,
                           json=body,
                           params=parameters,
                           headers=headers)
    updateReportContent(serverName, token, report, reportContent)
    return report


def getJob(serverName, token, jobId):
    url = "{0:s}/reportImages/jobs/{1:s}".format(serverName, jobId)
    params = {
        "wait": 5
    }
    headers = {
        'Accept': 'application/vnd.sas.report.images.job+json',
        'authorization': 'Bearer ' + token
    }
    job = requests.get(url, params=params, headers=headers)
    return job


def getReportImage(serverName, token, location, name):
    # Function to retrieve an image from the report
    reportUri = getReport(serverName, token, location, name)["uri"]
    url = "{0:s}/reportImages/jobs#requestsParams".format(serverName)
    params = {
        "reportUri": reportUri,
        "size": "600x600",
        "layoutType": "entireSection",
        "wait": 5,
        "refresh": True
    }
    headers = {
        'Accept': 'application/vnd.sas.report.images.job+json',
        'Accept-Language': 'string',
        'Accept-Locale': 'string',
        'authorization': 'Bearer ' + token
    }
    job = requests.post(url, params=params, headers=headers)
    if job.json()["state"] not in ["completed", "error"]:
        while job.json()["state"] == "running":
            job = getJob(serverName, token, job.json()['id'])
    return job.json()