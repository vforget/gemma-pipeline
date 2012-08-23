#!/usr/bin/python

from multiprocessing import Pool
import sys
import os
import gc

# Managable buffer size. For ~6,000 individuals consumes ~300MB of physical memory.
buffer_size = 10800000

def to_float(m):
    ''' Calculates dosage values for minor allele '''
    return [[f[1], f[3], f[4]] + ["%0.3f" % (float(f[i+1]) + float(f[i+2])*2) for i in range(5, len(f), 3)] for f in m]

def dosage(a):
    ''' Gets dosage values for a chunk of data. 
    Saves dosage values to pre-determined a filename. '''
    d = a[0]
    fn = a[1]
    m = [x.strip().split(" ") for x in d]
    t = to_float(m)
    o = open(fn, "w")
    print >> o, "\n".join(",".join(r) for r in t)
    o.close()

if __name__ == "__main__":
    # Path to SNPTEST .gen file
    fullpath = sys.argv[1]
    # Number of processors to use
    POOL_SIZE = int(sys.argv[2])
    # Path to temporary directory to store chunks of dosage data
    tmpdir = sys.argv[3]
    
    dirpath, filename = os.path.split(fullpath)
    root, ext = os.path.splitext(filename)
    
    d = []
    gfh = open(fullpath)
    c = 0
    chunk = []
    while 1:
        # Get chunk of imputed data
        d = gfh.readlines(buffer_size)
        if not d:
            break
        fn = tmpdir + "/" + root + "." + str(c) + ".d"
        # Append chunk to pool of work
        chunk.append([d, fn])
        # If gathered enough work ...
        if len(chunk) == POOL_SIZE:
            p = Pool(POOL_SIZE)
            # Calculate dosage for chunks in parallel
            p.map(dosage, chunk)
            chunk = [] 
            p.close()
            # Clean up, prevent small but appreciable increase in memory usage.
            gc.collect()
        
        c += 1
    # Process last chunks of data
    p = Pool(POOL_SIZE)
    p.map(dosage, chunk)
    p.close()
    gfh.close()
