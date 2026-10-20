import sys
import os
import numpy as np
from netCDF4 import Dataset

# Function used to pull data for scripps pier from thredds
def scrippspier(*args, **kwargs):
    #args - strings, used for variable names to pull from the data
    #kwargs - year=YYYY, used to pull data from a year in range 2005-2021, I don't think I have to restrict to those years actually that was just that homework but I
    #Returns array of arrays of variables
    
    urls = [] # make empty dataset
    for i in range(17):
        url = f"https://thredds.sccoos.org/thredds/dodsC/autoss/scripps_pier-20{i+5:02d}.nc" #take each url and append it to dataset
        urls.append(url)

    year = kwargs.get('year',None) #grab year
    if year is not None:
        nc = Dataset(urls[int(year)-2005]) # Pick year of dataset
    else:
        print('Provide year between 2005-2021 in form year=YYYY')
        return None
    data = {}
    for arg in args: #takes the arguments in *args for variables
        if arg in nc.variables:
            data[arg] = nc.variables[arg][:] #adds each variable to a larger dataset
            print(data[arg])
        else:
            print(f"Variable '{arg}' not found in dataset.") #check for the argument in the dataset
            extracted_data[arg] = None
    nc.close() #close the connection
    return data