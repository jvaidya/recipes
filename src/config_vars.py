import socket
if '.local' in socket.gethostname():
    BASE_DIR = '/Users/jiten/src/recipes/website'
    hostname = 'localhost'
else:
    BASE_DIR = '/storage/website'
    hostname = '10.1.10.10'

