# get_secret() crashes in PyGObject, so gcr proves our ciphertext through
# receive() (fails on a bad key or padding) and sends its own secret for us to decrypt
import sys, gi
gi.require_version("Gcr", "4")
from gi.repository import Gcr

ex = Gcr.SecretExchange.new(None)

def out(s):
    sys.stdout.write(s.replace("\n", "\\n") + "\n")
    sys.stdout.flush()

def inp():
    return sys.stdin.readline().rstrip("\n").replace("\\n", "\n")

assert ex.receive(inp())
out(ex.send("gcr says ñ 0123456789", -1))
out(str(ex.receive(inp())))
