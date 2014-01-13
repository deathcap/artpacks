
AdmZip = require 'adm-zip'

zip = new AdmZip('test.zip')
zipEntries = zip.getEntries()

for zipEntry in zipEntries
  console.log zipEntry.toString()

