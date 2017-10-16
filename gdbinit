set sysroot

python
print('Invoked "set sysroot" to enable debugging locally')

import sys, os
sys.path.insert(0, os.environ["DRAKE_GDB_ROOT"])

import drake_gdb 
drake_gdb.register_printers()

# http://droettboom.com/blog/2015/11/20/gdb-python-extensions/
def setup_python(event):
    import libpython
gdb.events.new_objfile.connect(setup_python)

end
