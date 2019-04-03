#!/usr/bin/env bash

yocto_sync()
{
  sudo mkdir -p "${DATADIR}/yocto/"
  sudo chown docker:docker "${DATADIR}/yocto/"
  cd "${DATADIR}/yocto"

  echo "N" | repo init -u https://github.com/bmand/weather-fmu-manifest

  repo sync --force-sync
}

main()
{
  if [ $# -lt 1 ]; then
    echo "Not enough argument"
    exit 1
  fi

  if [ ! -d "${DATADIR}/yocto/sources" ] && [ "$1" != "sync" ]; then
    echo "yocto/sources does not exists: use the command 'sync', Bye!"
    exit 1
  fi


  case "$1" in
    all)
      cd "${DATADIR}/yocto"
      TEMPLATECONF=$PWD/sources/meta-weather-fmu/conf/beaglebone
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;

    sync)
      shift;

      yocto_sync

      cd "${DATADIR}/yocto"
      export TEMPLATECONF=$PWD/sources/meta-weather-fmu/conf/beaglebone
      cp -v $TEMPLATECONF/* $PWD/sources/meta-weather-fmu/conf/
      source sources/poky/oe-init-build-env build
      ;;

    fullmetalupdate-containers)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      ;;

    fullmetalupdate-os)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      if [ ! -d "${DATADIR}/yocto/build/tmp/fullmetalupdate-containers/deploy/containers" ]; then
        DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      fi
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;
    
    build-container)
      shift; set -- "$@"
      if [ $# -ne 1 ]; then
        echo "build-container command accepts only 1 argument"
        exit 1
      fi
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake $1 -k
      ;;

    package-wic)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -c image_wic -f
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;

    bash)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      bash
      ;;
    *)
      echo "Command not supported: $1, bye!"
      exit 1
  esac

}

main $@
