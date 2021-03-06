[ "$(grep LC_ALL /etc/bash.bashrc)" ] || echo -e '
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LANGUAGE="en_US:en"
export LANG="en_US.UTF-8"
export LC_ALL="C"
' >> /etc/bash.bashrc

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LANGUAGE=en_US:en
export LANG=en_US.UTF-8
export LC_ALL=C
locale-gen en_US.UTF-8

apt install -y lsb-release

curl -fsSL https://download.docker.com/linux/$(lsb_release -is)/gpg | \
  apt-key add -

echo "deb https://download.docker.com/linux/$(lsb_release -is) $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list

apt update

apt-get purge -y \
  containerd \
  docker docker-engine docker.io \
  runc

apt-get install -y \
  apt-transport-https \
  ca-certificates curl \
  gnupg2 \
  software-properties-common \
  wget

apt-get install -y \
  containerd.io \
  docker-ce docker-ce-cli

apt purge -y \
  aufs*
