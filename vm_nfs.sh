#!/bin/bash

  #############################################
  ## filename: vm_nfs.sh                    ##
  ## path:     ~/src/deploy/localhost/docker/                        ##
  ## date:     12/10/2015                    ##
  ## purpose:  persistant nfs on boot2docker ##
  ## repo:     https://github.com/DevOpsEtc ##
  #############################################

# vim: set fdm=marker:                      # treat triple braces as folds

# set -e

# nfs_notes # {{{
# _________________________________________________
# description:
#   - creates a nfs export share on the osx host
#   - creates a boot-time script on boot2dockers's persistant disk that
#       - removes the default /Users share
#       - mounts the osx host share to /data
# _________________________________________________
# usage:
#   - called from bud_bootstrap.sh
#   - source as standalone
#       $ cd ~/bud
#       $ chmod +x ~/bud/bud_nfs.sh
#       $ ./bud_nfs.sh
# _________________________________________________
# troubleshooting:
#   # list machine names
#   $ docker-machine ls -q
#   # set temporary shell variable using a valid machine name
#   $ mach_name=[machine name]
#

# list active machine
# echo machine env
# reset vars

#   # check boot log for any errors
#   $ docker-machine ssh $mach_name cat /var/log/bootlocal.log
#
#   # check OSX share(s)
#   $ showmount -e
#
#   # check NFS ports on OSX
#   $ rpcinfo -p | grep nfs
#
#   # check bootlocal.sh content for echo output
#   $ docker-machine ssh $mach_name cat /var/lib/boot2docker/bootlocal.sh
#
#   # check if bootlocal.sh is executable
#   $ docker-machine ssh $mach_name 'ls -l /var/lib/boot2docker/bootlocal.sh'
#
#   # check ping results from machine to osx host
#   $ docker-machine ssh $mach_name 'ping 192.168.99.1 -c3'
#
#   # check osx app firewall log for block nfsd and/or rpc events
#   $ grep -a 'nfsd\|rpc' /var/log/appfirewall.log | tail
#
#   # check osx app firewall whitelisted apps
#   $ sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
#
#   # should see "Allow incoming connections" for...
#   # nfsd, netbiosd, rpc.lockd, rpc.statd, rpcbind & rpc.rquotad, if not add...
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /sbin/nfsd
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/netbiosd
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/rpc.lockd
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/rpc.statd
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/rpcbind
#   # sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/libexec/rpc.rquotad
#
#   # restart firewall
#   $ launchctl unload /System/Library/LaunchAgents/com.apple.alf.useragent.plist
#   $ sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist
#   $ sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
#   $ launchctl load /System/Library/LaunchAgents/com.apple.alf.useragent.plist
#
#   # run mount command in one tab & tail log in another to see errors on fly
#   $ tail -f /var/log/appfirewall.log
#   $ docker-machine ssh $mach_name 'sudo mount -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp,nfsvers=3 192.168.99.1:$HOME/bud/projects/$proj_name/data /data'

#   # check app firewall settings
#   $ osascript -e "tell app \"System Preferences\"" -e "reveal anchor \"Firewall\" of pane id \"com.apple.preference.security\"" -e "activate" -e "end tell"
#
#   # for nfsd checkexports ambiguity error, kill corresponding entry
#   $ sudo vim /var/db/mountdexptab
#
#   # shotgun fix
#   $ docker-machine rm $(docker-machine ls -q)
#   $ rm -rf ~/.docker
#   $ rm -f /usr/local/bin/{docker,docker-machine}
# _________________________________________________
# nfs mount options:
#   rw: read/write filesystem
#   ro: read-only filesystem
#   nolock: disable file locks
#   noexec: disable execution of binaries or scripts
#   nosuid: prevents users from gaining ownership of files
#   rsize=[num]: read block data size: defaults 8192 (NFSv3) 32768 (NFSv4)
#   wsize=[num]: write block data size: defaults 8192 (NFSv3) 32768 (NFSv4)
#   for apps using files under nfs server that becomes unavailable...
#     hard:  wait till NFS comes back; can terminate w/ option: intr
#     soft:  wait till specified timeout, before error w/ option: timeo
#     intr:  allows user to terminate processes waiting on a NFS request
#     timeo=[num]: specify the timeout (seconds) for an NFS request
# }}}
# nfs_variables # {{{
  rs=$(tput sgr0)                            # reset text attributes
  blue=$(tput bold)$(tput setaf 33)          # set text bold & blue
  red=$(tput bold)$(tput setaf 160)          # set text bold & red
  yellow=$(tput bold)$(tput setaf 136)       # set text bold & yellow
  green=$(tput bold)$(tput setaf 64)         # set text bold & green

  # do if sourced with parameter
  if [ ! -z $1 ]; then
    # assign machine name variable to given parameter
    mach_name="$1"
  # do if not sourced with parameter
  else
    # prompt for machine name and assign to variable
    read -p "$(echo -e "$green\n \benter machine name $rs")" mach_name
  fi

  # strip off tld from machine name
  proj_name=$(printf %s\\n "${mach_name%.*}")

  # host sharepoint
  osx_share=$HOME/bud/projects/$proj_name/data
  # docker host mountpoint
  m_mount=/data
  # docker-machine host ip
  m_ip=$(docker-machine ip $mach_name)
  # docker-machine host ip (mac)
  osx_ip=$(VBoxManage list hostonlyifs | awk '/IPAddress/ {print $2}')
  # default virtualbox share created by boot2docker
  v_mount=$(VBoxManage showvminfo $mach_name | awk '/Name: '\''Users'\''/ { gsub( "['\',']","" ); print $2}')
  # persistant boot script
  m_boot=/var/lib/boot2docker/bootlocal.sh
  m_opt=rw,async,noatime,rsize=32768,wsize=32768,proto=tcp,nfsvers=3
  # m_opt=noacl,async
  # m_opt=noatime,soft,nolock,vers=3,udp,proto=udp,rsize=8192,wsize=8192,namlen=255,timeo=10,retrans=3,nfsvers=3
# }}}
nfs_pre() { # {{{
  # do if machine is not running
  if ! docker-machine ls -q --filter state=Running | grep -q "$mach_name"; then
    echo -e "$red\n \b**** machine not running: $mach_name **** $rs"
    # start machine
    docker-machine start $mach_name

    # do not continue until machine is running
    # while ! docker-machine ls -q --filter state=Running | grep -q "$mach_name"; do
    while [ ! $(docker-machine status "$mach_name") == "Running" ]; do
      printf '.'
      sleep 1
    done
    echo -e "$blue\n \b**** machine running: $mach_name **** $rs"
  fi

  # wait for sshd to load before continuing
  echo -e "$green\n \bwaiting on $mach_name's SSHD..."
  until nc -zw 2 $(docker-machine ip $mach_name) 22 &>/dev/null; do
    printf '.'
    sleep 1
  done

  # do if machine already has NFS share mounted
  if docker-machine ssh $mach_name mount | grep -q nfs; then
    echo -e "$blue\n \b**** machine already has NFS: $mach_name **** $rs"
    exit 0
  fi
} # }}}
nfs_exports() { # {{{
  # add NFS export entry
  echo -e "$green\n \bcreate export entry for OSX host share in /etc/exports... $rs"

  # comment any existing lines containing new docker machine name or ip address
  sudo sed -i '' -e "/$mach_name/ s/^#*\ */#\ /" -e "/^$m_ip/ s/^#*\ */#\ /" /etc/exports

  # append exports entry for new docker machine
  echo -e "\n$osx_share $m_ip -alldirs -mapall=$(id -u):$(id -g)" | sudo tee -a /etc/exports

  # syntax check; restart nfsd
  echo -e "$green\n \bcheck /etc/export syntax & restart nfsd daemon if passes... $rs"
  if ! nfsd checkexports 2>&1 >/dev/null | grep -q '.'; then
    echo -e "$blue\n \bnfs exports syntax ok\n\n$green \brestarting nfsd daemon on OSX... $rs"
    sudo nfsd restart
  else
    echo -e >&2 "$red\n \b**** syntax issue with /etc/exports **** $rs"
    echo -e >&2 "$red\n \b$(nfsd checkexports) $rs"
    exit 1
  fi
} # }}}
nfs_bootlocal() { # {{{
  # create boot script on boot2docker
  echo -e "$green\n \bbuild out bootlocal.sh script on $mach_name's persistent disk...\n $rs"

  # add shebang
  docker-machine ssh $mach_name "echo '#!/bin/sh' | sudo tee $m_boot"

  # unmount default vboxsf share; eat error if does not exist
  docker-machine ssh $mach_name "echo -e '\nsudo umount /Users &>/dev/null' | sudo tee -a $m_boot"

  # restart nfs client
  docker-machine ssh $mach_name "echo 'sudo /usr/local/etc/init.d/nfs-client restart &>/dev/null' | sudo tee -a $m_boot"

  # wait on nfs
  # docker-machine ssh $mach_name "echo 'sleep 10' | sudo tee -a $m_boot"
  # docker-machine ssh $mach_name "echo 'while ! ping -c1 $osx_ip &>/dev/null; do sleep 5; done' | sudo tee -a $m_boot"

  # create mount point
  docker-machine ssh $mach_name "echo 'sudo mkdir $m_mount' | sudo tee -a $m_boot"

  # bind-mount nfs share from mac host; adjust mount options as needed
  docker-machine ssh $mach_name "echo 'sudo mount -o $m_opt $osx_ip:$osx_share $m_mount' | sudo tee -a $m_boot"

  # set bootlocal.sh to executable
  echo -e "$green\n \bset script to executable... $rs"
  docker-machine ssh $mach_name sudo chmod +x $m_boot
} # }}}
nfs_post () { # {{{
  # stop machine
  echo -e "$green\n \bstopping machine: $mach_name... $rs"
  docker-machine stop $mach_name

  # kill default vboxsf share if exists
  if [ "$v_mount" == "Users" ]; then
    echo -e "$green\n \bkilling $mach_name's default vboxsf share... $rs"
    VBoxManage sharedfolder remove $mach_name --name $v_mount
  fi;

             # source bashrc to pickup up changes in bud.bash; eat output
             # . $HOME/bud/bud.bash "$mach_name"
             # echo "$red mach_name: $mach_name"

  # starting machine
  echo -e "$green\n \bstarting machine: $mach_name... \n$rs"
  docker-machine start $mach_name

  # wait for nfs mount to connect
  echo -e "$green\n \bwaiting for nfs mount on $mach_name to connect... $rs"
  while ! docker-machine ssh $mach_name mount | grep -q nfs; do
    printf '.'
    sleep 1
  done
  # sleep 10

  # list nfs mount
  echo -e "$green\n \bnew nfs mount: $rs"
  echo -e "$blue\n \b$(docker-machine ssh $mach_name mount | awk '/nfs/ {$6=""; print $0}')$rs"
} # }}}
nfs_init() { # {{{
  nfs_pre       # check machine readiness
  nfs_exports   # create nfs export share on osx
  nfs_bootlocal # create persistant boot script on machine
  nfs_post      # cleanup & check results
  exit 0        # exit subshell with success code
} # }}}

nfs_init "$@"
