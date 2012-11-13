#!/usr/bin/python
# Simplified version of Adafruit_DHT_googledocs.ex.py

import re
import sys
import time
import datetime
import gspread

# ===========================================================================
# Google Account Details
# ===========================================================================

# Account details for google docs
email       = '***********'
password    = '***********'
spreadsheet = '***********'

# ===========================================================================
# Example Code
# ===========================================================================


# Login with your Google account
try:
  gc = gspread.login(email, password)
except:
  print "Unable to log in.  Check your email address/password"
  sys.exit()

# Open a worksheet from your spreadsheet using the filename
try:
  worksheet = gc.open(spreadsheet).sheet1
  # Alternatively, open a spreadsheet using the spreadsheet's key
  # worksheet = gc.open_by_key('0BmgG6nO_6dprdS1MN3d3MkdPa142WFRrdnRRUWl1UFE')
except:
  print "Unable to open the spreadsheet.  Check your filename: %s" % spreadsheet
  sys.exit()

# temp/humidity // sensor #1 at pin 24 (default)//
temp = float(sys.argv[1])
humidity = float(sys.argv[2])
# temp/humidity // sensor #2 at pin 25//
temp25 = float(sys.argv[3])
humidity25 = float(sys.argv[4])
# temp/humidity // sensor #3 at pin 22 //
temp22 = float(sys.argv[5])
humidity22 = float(sys.argv[6])

print "Temperature: %.1f C" % temp
print "Humidity:    %.1f %%" % humidity
 
# Append the data in the spreadsheet, including a timestamp
try:
  values = [datetime.datetime.now(), temp, humidity, temp25, humidity25, temp22, humidity22]
  worksheet.append_row(values)
except:
  print "Unable to append data.  Check your connection?"
  sys.exit()

# Wait 30 seconds before continuing
print "Wrote a row to %s" % spreadsheet
