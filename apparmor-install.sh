apt update
apt install -y apparmor apparmor-profiles apparmor-utils

sed 's|^\(GRUB_CMDLINE_LINUX_DEFAULT="quiet\)"$|\1 apparmor=1 security=apparmor cgroup_enable=memory swapaccount=1 panic_on_oops=1 panic=5"|' -i /etc/default/grub
update-grub
