#!/bin/python3

import datetime
import sys
import logging
import argparse

import pytube

# Background Colors to log messages
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def Log(message):
    print(f"{bcolors.BOLD}{bcolors.OKBLUE}[{datetime.datetime.now()}] {bcolors.OKCYAN}{message}")

def LogError(message):
    print(f"{bcolors.BOLD}{bcolors.OKBLUE}[{datetime.datetime.now()}] {bcolors.FAIL}{message}")    

def LogOk(message):
    print(f"{bcolors.BOLD}{bcolors.OKBLUE}[{datetime.datetime.now()}] {bcolors.OKGREEN}{message}")        

try:

    parser = argparse.ArgumentParser(description='Youtube video downloader information')
    parser.add_argument('--url', dest='link', type=str, help='youtube video URL', required=True)
    parser.add_argument('--high-res', dest='highRes', type=str, help='get video data with maxmium resolution available', default='True', required=False)
    parser.add_argument('--path', dest='path', type=str, help='output path to store downloaded file', default='output', required=False)
    parser.add_argument('--filename', dest='filename', type=str, help='output filename to create video file', default=f"video_{datetime.datetime.now()}", required=False)
    
    args = parser.parse_args()
       
    Log(f"Trying to download {args.link}...")
    yt = pytube.YouTube(args.link)
    
    if args.highRes:
        Log(f"Get data on high-res...")
        yt.streams.get_highest_resolution().download(args.path, filename=args.filename)
    else:
        yt.streams.first().download(args.path)
    
    LogOk("Done!")
    Log(f"File created on \"{args.path}/{args.filename}\"")
    
except Exception as  e: 
    LogError(f"Error: {e}")