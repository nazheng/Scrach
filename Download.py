import os
from azure.storage.common import CloudStorageAccount


class DownLoadJob():
    "This is the class for download job"

    def __init__(self, jobSession, targetFolder, sourceShare, sourceDir=None):
        print('+++++ Create download job +++++')
        self.jobSession = jobSession
        self.sourceShare = sourceShare
        self.sourceDir = sourceDir
        self.targetFolder = targetFolder

    def startdownload(self):
        "method for downloading the data from share"

        if self.sourceDir != None:
            print('----- Checking folder - ' + self.sourceDir)
            generator = self.jobSession.list_directories_and_files(
                self.sourceShare, self.sourceDir)
        else:
            print('----- Checking folder - ' + self.sourceShare)
            generator = self.jobSession.list_directories_and_files(
                self.sourceShare)

        for file_or_dir in generator:
            classstr = str(type(file_or_dir))
            if 'Directory' in classstr:
                    dirpath = self.targetFolder + '/' + file_or_dir.name
                    try:
                        os.makedirs(dirpath)
                    except OSError:
                        if not os.path.isdir(dirpath):
                            raise
                    if self.sourceDir != None:
                        subdirpath = self.sourceDir + "/" + file_or_dir.name
                    else:
                        subdirpath = file_or_dir.name
                    print('--------- Enumerating subfolder - ' + file_or_dir.name)
                    innerjob = DownLoadJob(
                        self.jobSession, dirpath, self.sourceShare, subdirpath)
                    innerjob.startdownload()
            else:
                destfilepath = self.targetFolder + '/' + file_or_dir.name
                print('-------- Downloading file - ' + file_or_dir.name)
                self.jobSession.get_file_to_path(
                    self.sourceShare, self.sourceDir, file_or_dir.name, destfilepath)


STORAGE_ACCOUNT_NAME = ''
STORAGE_ACCOUNT_KEY = ''

print('Download the files from Azure File Share')

try:
    sourceaccount = CloudStorageAccount(
        STORAGE_ACCOUNT_NAME, STORAGE_ACCOUNT_KEY)
    session = sourceaccount.create_file_service()
    job = DownLoadJob(session, "~/temp", 'dir')
    job.startdownload()
except Exception as e:
    print('Error occurred in the sample.', e)
