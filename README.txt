From Mail List:

tar <options> <dir> | ssh <instance> "dd of=<volume>"

There is no use of tar(1) on the remote side.  tar(1) is only used to
create an archive of the data; the remote volume is treated as raw block
storage, much like a local magnetic tape or other raw disk device might.
