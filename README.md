# EC2 Backup

The description of Homework 6 is [here](https://www.cs.stevens.edu/~jschauma/615/s16-hw4.html).

Refer to [manual](https://www.cs.stevens.edu/~jschauma/615/ec2-backup.txt) here,

1, Create a volume of the appropriate size.

* If -v not specified, create a new volume with double size(at least.)
* Get volume-id

2, Attaching it to an EC2 instance.

* Create a new instance. Get instance-id.
* Attach volume on the instance.

3, Copy the files from the given directory into this volume.

###Details
1, Use Fedora and install aws on it. Then config ssh. [Guide](https://lists.stevens.edu/pipermail/cs615asa/2013-March/000794.html)

2. rsync works on local, test for network.
