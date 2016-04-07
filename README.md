# EC2 Backup

The description of Homework 6 is [here](https://www.cs.stevens.edu/~jschauma/615/s16-hw4.html).

Refer to [manual](https://www.cs.stevens.edu/~jschauma/615/ec2-backup.txt) here,

1, Create a volume of the appropriate size.

* If -v not specified, create a new volume with double size(at least.)
* Get volume-id

2, Attaching it to an EC2 instance.

* Create a new instance. Get instance-id.
* Attach volume on the instance.(/dev/sdf)

3, Copy the files from the given directory into this volume.

###Details
1, Use Fedora and install aws on it. Then config ssh. [Guide](https://lists.stevens.edu/pipermail/cs615asa/2013-March/000794.html)

2. rsync works on local, test for network.

3. network works


###Experiments & Step
1, Create Volume and Instance

2, Attach Volume to instance

3, In server, make file system

	$ mkfs 
4, Mount to directory

5, Change owner of the directory

	$ chgrp fedora $DIR
	$ chown fedora $DIR -R
* Maybe 4 & 5 can do [together](http://superuser.com/questions/320415/linux-mount-device-with-specific-user-rights)

6, ...
