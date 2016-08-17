#!/bin/bash
array=(1 2 3 4)
intern_array=(8 9 10 11)

#host is 172.16.0.13x (1-4)
host="172.16.0.13"
name="spark-"
MASTER="172.16.0.131"
intern_host="192.168.111."
num=1
key_location="/tmp/cloud.key"
public_keys_location="/tmp/keys"

host_content=`cat<<HOST
192.168.111.9 spark-1
172.16.0.131 spark-1
192.168.111.8 spark-2
172.16.0.132 spark-2
192.168.111.10 spark-3
172.16.0.133 spark-3
192.168.111.11 spark-4
172.16.0.134 spark-4
HOST`

if [ ! -f ${key_location} ]; then
cat > ${key_location} <<\RSA_KEY
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAs2pH7OOVUJPINctZfnnRUzxOhtcjksTqMTrZ+aMkwFioyMJf
LkHeYjoqw2jRSZ6tZRp7K9o3V5NfzZr2YR8egFkzjGi9RHAHlPoN9wr69ma9M/+w
ChbXepI9R0+iR8LneZ1NmpwYNJvo9YITyA+cBEnB26CJzpHefLsDgOIkNf600GfY
4DHI/IEh/SUVs6RJRJqC7ryYWoH1EZRm4D1EctzOAvG4dRk0ig/S0NxPfwa6u0+F
0txUxI0fVSTZu8KQ3xsxvOc4KUXAX9JT3hOXWhJhGtPX2frsDRbvVTNItSz5+82W
VubQdW2uyuPQ/o77M6WC6VqQQS0Z+nSbdwKkewIDAQABAoIBAQCQXkIYFR0uJGxj
FQkjY2STxKAvkmg2jqsgCAoj/SnyeKUAPp+WOjx27/U/HlXiFoPSKhfYtpP3rUfW
yw3cIs1JW/3FyvYZXshLEVcxZa2BnjQ65lDCHZUwNQKIIkUj12qpinFKqrYzhw1S
mGPQhPb24F7Umn6pMOlFlrp/9/hJVR0sAgqErEVn7HKgfK2TUIvmQu7XMdw1vxq1
rvGCBadvMiLMyVpnjrrFgXeHOX/4l98XoFldrxEVRHvhHDh6PqOtUiKhLrt7O46B
F8+P63JVlgRQ4MxApb/APo3p7nIx5Zf1F3OEnSiFBMYRcr/c+H4x+deqvJLuhSxq
DkCN1nFJAoGBANto0aO7h8jzwT12Cv+7dboTB6W0JJZx0HpwmQDghZU19oj1PB/r
Pew4jscuDraAVw4UklhL5dr0mqO8YKNzzlOqVt0S80iiBhbWkH/UcUofJz7zU9WD
tWQIlFClcOADOcMUObqNuaJOB5jjiviVviZX3YF2avjn4nMCpqb5lz9lAoGBANFV
/30T+HjcWzLjhkWj6uRYwAAeBZmMttsFIZjl6REVy0Yrouj8sC2aZwGGjgwEGYcI
HMqVWqsN6CMhilgQ3Db5IriZ40CkRLoLA+5DQuGT1MJ6baEnRA74vxOZWrUVT+u6
3bJggZRM9NDlflg0WNVQBCxv8IUf68ve2DCs0sZfAoGAUTIoKrySknZKc/FEPsFj
3tl+Af95bsdtzHHw3Vc5eC+BLcv7VSCcSNfhVqqfvUAfd1F7mvtzc6UDuUZUSQjp
OSMXhDaoG6ACOt9qmDPJPRHsVyp7Qs+8B+n44SNocy4eaSgJ+RTLttnDi/vhCP95
X/0yNt/Y1IYT0lYP0EkbhNUCgYAw1EWHMHxZ/NSNF0N/xQ+KeiU3IcmempMgnZ7L
on1uDc5frNgQTrjtukFiurcxmFc4By1oF9SRZ+oJH868Yhpr/EscElFPB8I8P0uI
bUoRgkEzqAkgeR9H+r/fW3ssGC+PRgRmklpHdHf6rj19Z6B9CXAfyXCqLNr8sBtv
pzB3MwKBgQC33BXEcjoOnBncgSGop+YgR43SWkKtnbGXnkexOVtDtR38mgE/enkL
6xyWvE6SlNWp6eWbJVZvmpryEb2DdUfJYIlIC1cOVwY5dGBP+U7vgx2hn9yzTIWK
LeiOuSb/O35RcK8l2C47jh974WiQqtfWbFfHOU1hfpvlRalosO+guQ==
-----END RSA PRIVATE KEY-----
RSA_KEY
chmod 600 ${key_location}
fi

Setup ()
{
for index in ${array[@]}; do
specify_host=$host$index
#Add fingerprint for the servers to Local
ssh-keygen -R $specify_host
ssh-keyscan -H $specify_host >> ~/.ssh/known_hosts

#Set Root Passwd and Enable login
ssh -i ${key_location} ubuntu@$specify_host "echo -e 'root\nroot'|sudo passwd"
ssh -i ${key_location} ubuntu@$specify_host "sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys"
ssh -i ${key_location} root@$specify_host "addgroup hadoop;useradd -m -p $(openssl passwd hduser) -g hadoop hduser"
ssh -i ${key_location} root@$specify_host "cp /home/ubuntu/.ssh/authorized_keys /home/hduser/.ssh/authorized_keys;chown -R hduser:hadoop /home/hduser/.ssh"
ssh -i ${key_location} root@$specify_host "adduser hduser sudo"
ssh -i ${key_location} root@$specify_host "chsh -s /bin/bash hduser"
ssh -i ${key_location} root@$specify_host "apt-get update;apt-get install -y openjdk-7-jdk python-dev python-pip"


#Deploy hadoop
ssh -i ${key_location} hduser@$specify_host "echo 'export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64' >> /home/hduser/.bashrc"
scp -i ${key_location} -r ~/hadoop hduser@$specify_host:/home/hduser/
scp -i ${key_location} -r ~/spark hduser@$specify_host:/home/hduser/

#Modify /etc/hosts
ssh -i ${key_location} root@$specify_host "echo '$host_content' >> /etc/hosts" 

#Generage SSH Key
ssh -i ${key_location} hduser@$specify_host "yes ''|ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q"
for sub_index in ${array[@]}; do
specify_subhost=$name$sub_index
ssh -i ${key_location} hduser@$specify_host "ssh-keygen -R $specify_subhost"
ssh -i ${key_location} hduser@$specify_host "ssh-keyscan -H $specify_subhost >> ~/.ssh/known_hosts"
done

done

#Gather public keys and Deploy to Bother Nodes
if [ ! -f ${public_keys_location} ]; then
for index in ${array[@]}; do
specify_host=$host$index
echo $specify_host
ssh -i ${key_location} hduser@$specify_host "cat ~/.ssh/id_rsa.pub" >> /tmp/keys 
done
fi
for index in ${array[@]}; do
specify_host=$host$index
cat ${public_keys_location} | ssh -i ${key_location} hduser@$specify_host "cat >> ~/.ssh/authorized_keys"
done
}


stop_computing ()
{
# Please execute with proper user
~/hadoop/sbin/stop-all.sh;
~/spark/stop-all.sh
}

start_computing ()
{
# Please execute with proper user
~/hadoop/sbin/start-all.sh;
~/spark/sbin/start-all.sh
#check
jps
}

init_localfs ()
{
# Please execute with root
rm -rf /home/hduser/hadoop/tmp_nfs /home/hduser/hadoop/tmp;
mkdir /home/hduser/hadoop/tmp_nfs;mkdir /home/hduser/hadoop/tmp;
mkdir -p ~/hadoop/tmp_nfs/dfs;
mkdir -p ~/hadoop/tmp_nfs/dfs/name;
mkdir -p ~/hadoop/tmp_nfs/dfs/data
chown hduser:hadoop -R /home/hduser/hadoop/tmp_nfs
chown hduser:hadoop -R /home/hduser/hadoop/tmp
}

umount_device ()
{
# Execute with root
umount /home/hduser/hadoop/tmp_nfs;
#umount /home/hduser/hadoop/tmp;
}

mount_device ()
{
# Execute with root
rm -rf /home/hduser/hadoop/tmp_nfs /home/hduser/hadoop/tmp;
mkdir /home/hduser/hadoop/tmp_nfs;mkdir /home/hduser/hadoop/tmp;
mount /dev/vdb1 /home/hduser/hadoop/tmp_nfs;
rm -rf  /home/hduser/hadoop/tmp_nfs/dfs;
mkdir -p /home/hduser/hadoop/tmp_nfs/dfs;
mkdir -p /home/hduser/hadoop/tmp_nfs/dfs/name;
mkdir -p /home/hduser/hadoop/tmp_nfs/dfs/data
chown hduser:hadoop -R /home/hduser/hadoop/tmp_nfs
chown hduser:hadoop -R /home/hduser/hadoop/tmp
}

init_device ()
{
# Execute with root
echo 'd
n
p
1


w' | fdisk /dev/vdb;
mkfs.ext4 /dev/vdb1;
}

init_hdfs_and_launch ()
{
# Execute with user
####Format Master HDFS namenode
~/hadoop/bin/hdfs namenode -format -force
~/hadoop/sbin/start-all.sh;
~/spark/sbin/start-all.sh
#check
jps
}

Switch_Local_to_LVM ()
{
###Stop Hadoop & Spark
ssh -i ${key_location} hduser@$MASTER "$(typeset -f stop_computing); stop_computing"

for index in ${array[@]}; do
specify_host=$host$index
ssh -i ${key_location} root@$specify_host "$(typeset -f mount_device); mount_device"
done
ssh -i ${key_location} hduser@$MASTER  "$(typeset -f init_hdfs_and_launch ); init_hdfs_and_launch"
}

Switch_LVM_to_Local ()
{
ssh -i ${key_location} hduser@$MASTER "$(typeset -f stop_computing); stop_computing"
for index in ${array[@]}; do
specify_host=$host$index
ssh -i ${key_location} root@$specify_host "$(typeset -f umount_device); umount_device"
ssh -i ${key_location} root@$specify_host "$(typeset -f init_localfs); init_localfs"
done
ssh -i ${key_location} hduser@$MASTER  "$(typeset -f init_hdfs_and_launch ); init_hdfs_and_launch"
}

Install_Soft()
{
for index in ${array[@]}; do
specify_host=$host$index
ssh -i ${key_location} root@$specify_host "apt-get install $* -y"
done
}
Install_Process ()
{
for index in ${array[@]}; do
specify_host=$host$index
echo $specify_host
ssh -i ${key_location} root@$specify_host "python -m pip install $*"
done
}
Run_Dispy_Daemon ()
{
    echo $*
}

if [ "$1" = "Setup" ]; then
    Setup
elif [ "$1" = "LVM" ]; then
    Switch_Local_to_LVM
elif [ "$1" = "Local" ]; then
    Switch_LVM_to_Local
elif [ "$1" = "Pip" ]; then
    Install_Process ${@:2}
elif [ "$1" = "APT-GET" ]; then
    Install_Soft ${@:2}
elif [ "$1" = "Run_Dispy_Daemon" ]; then
    Run_Dispy_Daemon ${@:2}
else
    echo "Usage: $0 Setup/LVM/Local/Pip python_package/APT-GET soft/Run_Dispy_Daemon"
fi

