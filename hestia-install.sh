#!/bin/bash -eu

echo -e "[user]
        name = $(hostname -s)
        email = hostmaster@$(hostname -d)" > /root/.gitconfig
apt install -y etckeeper

PASSWORD=$(< /dev/urandom tr -dc @.,/=_A-Z-a-z-0-9 | head -c24)
REDISPWD=$(< /dev/urandom tr -dc @.,/=_A-Z-a-z-0-9 | head -c24)

export LANGUAGE=en_US:en
export LANG=en_US.UTF-8
export LC_ALL=C
locale-gen en_US.UTF-8

REMOVE="apport* autofs avahi* beep btrfs-* cryptsetup cryptsetup-bin dmsetup eatmydata lxcfs lxd lxd-client lvm2 mdadm ntfs-3g open-iscsi pastebinit popularity-contest postfix prelink rsh* rsync snapd talk* telnet* tftp* ubuntu-report ufw xfsprogs whoopsie xinetd yp-tools ypbind"
## REMOVE PACKAGES
for package in $REMOVE; do
  apt purge -y $package
done

## TWEAK FOR Postgres and Redis
echo -e "## http://www.brendangregg.com/blog/2015-03-03/performance-tuning-linux-instances-on-ec2.html
vm.overcommit_memory=1
vm.dirty_ratio=80
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=12000" > /etc/sysctl.d/vm.conf
systemctl restart systemd-sysctl

## CONFIG SSHD
sed -E -i 's|^#?Port .*|Port 22|
  s|^#?UseDNS .*|UseDNS no|
  s|^#?MaxSessions .*|MaxSessions 2|
  s|^#?LogLevel .*|LogLevel VERBOSE|
  s|^#?Compression .*|Compression no|
  s|^#?MaxAuthTries .*|MaxAuthTries 3|
  s|^#?StrictModes .*|StrictModes yes|
  s|^#?Banner .*|Banner /etc/issue.net|
  s|^#?TCPKeepAlive .*|TCPKeepAlive no|
  s|^#?PrintLastLog .*|PrintLastLog yes|
  s|^#?X11Forwarding .*|X11Forwarding no|
  s|^#?LoginGraceTime .*|LoginGraceTime 20|
  s|^#?MaxStartups .*|MaxStartups 10:30:60|
  s|^#?AllowGroups .*|AllowGroups root sudo|
  s|^#?AllowTcpForwarding .*|AllowTcpForwarding no|
  s|^#?ClientAliveCountMax .*|ClientAliveCountMax 2|
  s|^#?ClientAliveInterval .*|ClientAliveInterval 300|
  s|^#?AllowAgentForwarding .*|AllowAgentForwarding no|
  s|^#?Subsystem .*sftp.*|Subsystem sftp internal-sftp|
  s|^#?IgnoreUserKnownHosts .*|IgnoreUserKnownHosts yes|
  s|^#?PermitUserEnvironment .*|PermitUserEnvironment no|
  s|^#?PasswordAuthentication .*|PasswordAuthentication no|
  s|^#?PermitRootLogin .*|PermitRootLogin without-password|
  s|^#?HostbasedAuthentication .*|HostbasedAuthentication no|
  s|^#?UsePrivilegeSeparation .*|UsePrivilegeSeparation sandbox|
  s|^#?Ciphers .*|Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr|
  s|^#?Macs .*|Macs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256|
  s|^#?KexAlgorithms .*|KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256|
  /^HostKey.*ssh_host_dsa_key .*/d
  /^KeyRegenerationInterval .*/d
  /^ServerKeyBits .*/d
  /^UseLogin .*/d' /etc/ssh/sshd_config
chmod 0600 /etc/ssh/sshd_config
systemctl restart sshd.service

## REMOVE USERS
for user in games gnats irc list news sync uucp; do
  userdel -r $user 2> /dev/null
done

wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh \
-a no \
-f -y no \
-g yes \
-k no \
-v no \
-w yes -o yes \
-x no -z no \
-c no -t no \
-s $(hostname -s).$(hostname -d) \
-e hostmaster@$(hostname -d) \
-p $PASSWORD

apt install -y curl php7.2-gmp php-imagick php-smbclient php-redis redis-server wget

sed 's|^port.*|port 0|' -i /etc/redis/redis.conf
sed 's|^# unixsocket .*|unixsocket /var/run/redis/redis.sock|' -i /etc/redis/redis.conf
sed 's|^# unixsocketperm .*|unixsocketperm 770|' -i /etc/redis/redis.conf
#sed "s|^# requirepass .*|requirepass $REDISPWD|" -i /etc/redis/redis.conf

for hUSER in $(grep hestia /etc/group|cut -d: -f4|sed 's/,/ /g'); do
usermod -aG redis $hUSER; done
systemctl restart redis
