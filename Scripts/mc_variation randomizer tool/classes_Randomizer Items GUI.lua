package.path = package.path..';'..debug.getinfo(1,"S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" 
require('Functions/User Interface')
require('Functions/Randomize Functions')

testing()