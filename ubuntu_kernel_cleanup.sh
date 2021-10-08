#!/bin/bash +x

# ubuntu_kernel_cleanup.sh
#
# developer: Josh Westmoreland
# date     : 2021-10-06
# email    : pac78275@gmail.com

LSB_REL='/etc/lsb-release'

if [ -f $LSB_REL ] && [ $(cat $LSB_REL | grep DISTRIB_ID=Ubuntu) ]
then
  CURRENT_KERNEL="$(uname -r)"
  NUM_PRESENT=$(dpkg --get-selections | egrep -i 'linux-image|linux-headers' | wc -l)
  NUM_TO_KEEP=2 # header and kernel packages (respectively)
  KERNEL_DIR_BASE='/var/lib/initramfs-tools'
  GET_UBUNTU_VERSION="$(cat /etc/lsb-release  | grep DISTRIB_RELEASE | cut -d '=' -f 2 | cut -d '.' -f 1)"
  TARGET_UBUNTU_VERSION=18

  # this makes the interactive grub dialog leave you alone
  DEBIAN_FRONTEND=noninteractive
  export DEBIAN_FRONTEND

  function removeOldKernelsAndHeaders() {
    for i in $(dpkg --get-selections | egrep -i 'linux-image|linux-headers' | cut -f1)
    do
      echo
      if [[ "$i" =~ "$CURRENT_KERNEL" ]]
      then
        echo "Skipping $i as this is part of the current kernel"
      else
        apt-get autoremove --purge -y

        echo "Removing $i, its extraneous files, and cleaning up grub..."
        apt-get remove --purge -y $i

        if [ "$i" != "linux-image-azure " ] && [ "$i" != "linux-headers-azure" ]
        then
          DIR_TO_RMRF="$KERNEL_DIR_BASE/$(echo $i | cut -d '-' -f 3,4,5)"
          if [ -f "$DIR_TO_RMRF" ]
          then 
            rm -rf $DIR_TO_RMRF
          fi

          ANOTHER_DIR_TO_RMRF="/lib/modules/$(echo $i | cut -d '-' -f 3,4,5)"
          if [ -d "$ANOTHER_DIR_TO_RMRF" ]
          then 
            rm -rf "$ANOTHER_DIR_TO_RMRF"
          fi
        fi
      fi
    done

    apt-get autoremove --purge -y
  }

  echo "Your Ubuntu version                           -> $(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d '=' -f 2)"
  echo "Current Linux kernel in use                   -> $(uname -r)"
  echo "Linux kernals and headers present on this box -> $(dpkg --get-selections | egrep -i 'linux-image|linux-headers' | wc -l)"
  dpkg --get-selections | egrep -i 'linux-image|linux-headers'

  if [ $GET_UBUNTU_VERSION -ge $TARGET_UBUNTU_VERSION ]
  then
    while [ $NUM_PRESENT -gt $NUM_TO_KEEP ]
    do
      removeOldKernelsAndHeaders
      NUM_PRESENT=$(dpkg --get-selections | egrep -i 'linux-image|linux-headers' | wc -l)
    done
    
    echo "Linux kernals and headers present on this box after cleanup -> $(dpkg --get-selections | egrep -i 'linux-image|linux-headers' | wc -l)"
    dpkg --get-selections | egrep -i 'linux-image|linux-headers'
  else
    echo "Your distro is older than 18.04.x. What's happening here is too convoluted for your needs."
    echo "Something like 'purge-old-kernels --keep 1 -qy' from the byobu package should work just fine for you."
    echo "Lets go ahead and run that for you..."
    apt-get install -y byobu       # installing or updating the package as is appropriate
    purge-old-kernels --keep 1 -qy # running it and keeping only the newest kernel
  fi
else
  echo 'This is not Ubuntu, so doing nothing and moving on...'
fi
