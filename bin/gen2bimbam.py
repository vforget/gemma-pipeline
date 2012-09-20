#!/usr/bin/python

from multiprocessing import Pool
import sys
import os
import gc

# Managable buffer size. For ~6,000 individuals consumes ~300MB of physical memory.
buffer_size = 10800000

def gen_to_mgf(f):
    ''' Calculates dosage of minor allele for a all individuals for one SNP'''
    # Dosage list for 2nd allele
    a2 = [(float(f[i+1]) + float(f[i+2])*2) for i in range(5, len(f), 3)]
    a2d = sum(a2)
    totd = ((len(f)-5) / 3)
    # if sum dosage for 2nd allele exceed minor allele threshold exceeds 
    # 1/2 the total possible dosage for all alleles, it is not the 
    # minor allele. Return the dosage for the other allele.
    if a2d > totd:
        sys.stderr.write("Warning: SNP %s -- Dosage for allele 2 exceeds MAF threshold \
of 0.5: %s > %s. Returning dosage for allele 1 instead.\n" % (f[1], a2d, totd))
        return [f[3], f[4]] + ["%0.3f" % (float(f[i+1]) + float(f[i])*2) \
                                   for i in range(5, len(f), 3)]
    return [f[4], f[3]] + ["%0.3f" % x for x in a2]

def write_mgf(a):
    ''' Gets dosage values for a chunk of data. 
    Saves dosage values to pre-determined a filename. '''
    d = a[0]
    fn = a[1]
    m = [x.strip().split(" ") for x in d]
    t = [[f[1]] + gen_to_mgf(f) for f in m]
    sys.stderr.write("Writing output to %s\n" % (fn))
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
            p.map(write_mgf, chunk)
            chunk = [] 
            p.close()
            # Clean up, prevent small but appreciable increase in memory usage.
            gc.collect()
        
        c += 1
    # Process last chunks of data
    p = Pool(POOL_SIZE)
    p.map(write_mgf, chunk)
    p.close()
    gfh.close()
