
import sys

queries = frozenset([x.strip() for x in open(sys.argv[1]).readlines()])
sys.stderr.write("Read %s entires from %s\n" % (len(queries), sys.argv[1]))

for l in sys.stdin:
    k = l[:20].split()[1]
    if k in queries: print l,
