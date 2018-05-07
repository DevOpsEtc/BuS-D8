#!/bin/bash

  ###################################################
  ## filename: bus_app.sh                          ##
  ## path:     ~/src/deploy/localhost/docker/                              ##
  ## date:     12/20/2015                          ##
  ## purpose:  BuS app audit/install/update/remove ##
  ## repo:     https://github.com/DevOpsEtc       ##
  ###################################################

# vim: set fdm=marker:                         # treat triple braces as folds

# notes {{{
# source:     via parent script:          $ cd ~/bus && ./bus_bootstrap.sh
# source:     via function & parameter:   $ bus app
# source:     directly:                   $ cd ~/bus && ./bus_app.sh
# uninstall:  via function & parameter:   $ bus uninstall
# uninstall:  directly:                   $ cd ~/bus && ./bus_app.sh uninstall
# }}}
# variables {{{
rs=$(tput sgr0)                                # reset text attributes
blue=$(tput bold)$(tput setaf 33)              # set text bold & blue
red=$(tput bold)$(tput setaf 160)              # set text bold & red
yellow=$(tput bold)$(tput setaf 136)           # set text bold & yellow
green=$(tput bold)$(tput setaf 64)             # set text bold & green
PS3=$(echo -e "$green\nenter number: $rs")     # select menu: default prompt
app_dir=/usr/local/bin                         # path to local app directory
apps=(git VirtualBox)                          # array: prerequisite apps
d_apps=(docker docker-compose docker-machine)  # array: prerequisite docker apps
d_apps_n=()                                    # array: missing docker apps
d_apps_y=()                                    # array: installed docker apps
# }}}
audit() { # {{{
  # purpose: check binary for existance, permissions & versions
  # loop though array of app names
  for a in "${apps[@]}"; do
    # do if app not found
    if [ ! -x $app_dir/${a} ]; then
      case $a in
        git )
          app_link=https://git-scm.com/downloads
          brew_link='$ brew install git';;
        VirtualBox )
          app_link=https://www.virtualbox.org/wiki/Downloads
          brew_link='$ brew install VirtualBox';;
      esac
      echo -e "$yellow\n \b- $a $green \t$app_link OR $brew_link $rs"
      app_missing=1
    fi
  done
  if [ "$app_missing" == "1" ]; then
    echo -e "\n \brun script again after installing missing apps! \n\nbye, bye"
    exit 1
  fi

  # loop though array of docker app names
  for a in "${d_apps[@]}"; do
    # do if app not found
    if [ ! -x $app_dir/"$a" ]; then
      # append missing app name to array
      d_apps_n+=("$a")
    # do if app found
    else
      # append installed app name to array
      d_apps_y+=("$a")
    fi
  done

  # do if docker app is missing
  if [ ${#d_apps_n[@]} -gt 0 ]; then
    echo -e "$green\n \bmissing docker apps: $rs"
    # print missing docker apps; 055 is octal code for dash
    echo -e "$yellow\n \b$(printf '\055 %s\n' "${d_apps_n[@]}") $rs"
    echo -e "$green\n \binstall manually via script or Docker Toolbox? \n$rs"
    # start looping menu
    select choice in "Script" "Toolbox" "QUIT"; do
      case $choice in
        Script ) break;;
        Toolbox )
          app_link=https://www.docker.com/docker-toolbox
          echo -e "\ndownload installer from: $app_link"
          echo -e "\nre-run script when done"
          sleep 2
          open $app_link
          exit 1;;
        QUIT ) exit 1;;
      esac
    done
  fi
} # }}}
app_rename() { # {{{
  # purpose: temporarily rename app name element for proper github api repo path
  # do if parameter yes is passed
  if [ "$1" == "yes" ]; then
    case $a in
      docker-compose ) a=compose;;
      docker-machine ) a=machine;;
    esac
  else
    case $a in
      compose ) a=docker-compose;;
      machine ) a=docker-machine;;
    esac
  fi
} # }}}
version_get() { # {{{
  # purpose: get latest version numbers of docker apps
  # temporarily rename app names
  app_rename yes

  # get latest version number; reformat as needed
  ver2=$(curl -sl https://api.github.com/repos/docker/$a/releases/latest | awk '/tag_name/ {gsub(/"/, ""); gsub(/v/, ""); gsub(/,/, ""); print $2}')

  # get latest version release date; reformat as needed
  ver_date=$(curl -sl https://api.github.com/repos/docker/$a/releases/latest | awk '/created_at/ {gsub(/"/, ""); print $2; exit}' | cut -c1-10)

  # reset app names
  app_rename
} # }}}
version_compare() { # {{{
  # purpose: compare installed version number with latest version number
  # clear out outdated value
  unset outdated

  # get current version number; reformat as needed
  ver1=$($a -v | awk '{gsub(/,/, ""); print $3}')

  # do if two versions are not equal
  if php -r "var_dump(version_compare('$ver1', '$ver2', '!='));" | grep -q "bool(true)"; then
    outdated=1
  fi
} # }}}
install() { # {{{
  # purpose: install any missing docker apps
  # do if app parameter given
  if [ ! -z "$1" ]; then
    # use passed parameter
    d_apps_list=$1
  else
    # use array of missing apps
    d_apps_list=${d_apps_n[@]}
  fi

  # loop app list to set links
  for a in $d_apps_list; do
    case $a in
      docker )
        d_app_url=https://get.docker.com/builds/Darwin/x86_64/docker-latest;;
      docker-compose )
        d_app_url=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest | awk "/browser/ && /$(uname -s)/ {gsub(/\"/, \"\"); print \$2}");;
      docker-machine )
        d_app_url=$(curl -sL https://api.github.com/repos/docker/machine/releases/latest | awk "/browser/ && /$(uname -s | tr '[A-Z]' '[a-z]')/ && /$(uname -m | cut -c 5-6)/ {gsub(/\"/, \"\"); print \$2}");;
    esac

    # call func: get versions
    version_get

    # download to /usr/local/bin/
    echo -e "$green\n \bdownloading $a v.$ver2... \n$rs"
    $sudo_cmd curl -L $d_app_url -o $app_dir/$a

    # set binary executable
    $sudo_cmd chmod +x $app_dir/$a

    # call func: compare versions
    version_compare

    # do if version #s match
    if [ "$outdated" != "1" ]; then
      echo -e "$green\n \b$a: v.$($a -v | awk '{gsub(/,/, ""); print $3}') | $blue \bsucessfully installed $rs"
    # do if version #s diverge
    else
      echo -e "$yellow \b$a: v.$ver2 not installed! \n$rs"
      # remove app w/ issue
      $sudo_cmd rm -f $app_dir/$a
      exit 1
    fi
  done
} # }}}
update() { # {{{
  # purpose: check for docker app update
  echo -e "$green\n \bchecking for updates $rs"

  # loop through list of installed apps
  for a in ${d_apps_y[@]}; do
    echo
    # call func: get versions
    version_get

    # call func: compare versions
    version_compare

    # do if version #s diverge
    if [ "$outdated" == "1" ]; then
      echo -e "$blue \b$a: v.$ver1 | $yellow \bnew version: v.$ver2 ($ver_date) \n$rs"
      echo -e "$green \bupdate $a to latest v.$ver2? \n$rs"

      # start looping menu
      select choice in "Yes" "No" "Changes"; do
        case $choice in
          Yes )
            # remove any app archives
            [ -f $app_dir/$a*tar* ] || $sudo_cmd rm -f

            # set pwd to local app dir
            cd $app_dir

            # matching pattern exclusion
            GLOBIGNORE=*tar*

            # archive old app
            echo -e "$green\n \barchiving $a v.$ver1... \n$rs"
            $sudo_cmd tar czvf $a.$ver1.tar.gz $a

            # remove old app
            $sudo_cmd rm -f $a

            # clear out pattern exclusion
            unset GLOBIGNORE

            # set pwd back to prior pwd; eat stdout
            cd - &>/dev/null

            echo -e "$green\n \b$a v.$ver1 backed up to: $rs"
            echo -e "$blue \b$(ls -lh $app_dir/$a.$ver1.tar.gz) $rs"

            # install app
            install $a
            break;;
          No ) break;;
          Changes )
            echo -e "$blue \nopening $a releases page: $rs"
            # pause 2 sec to read echo
            sleep 2

            # temporarily set app names
            app_rename yes

            # open change log in browser
            open https://github.com/docker/$a/releases

            # reset app names
            app_rename;;
        esac
      done
    # do if version #s match
    else
      echo -e "$green \b$a: v.$ver1 ($ver_date) $blue| up to date $rs"
    fi
  done
} # }}}
uninstall() { # {{{
  # purpose: remove binaries & any backups
  echo -e "$green removing docker apps... $rs"
  # remove app using elevated privledges
  $sudo_cmd rm -f $app_dir/docker*
} #}}}
init() { # {{{
  unset sudo_cmd                        # clear out command prefix
  [ $(id -g) == 80 ] || sudo_cmd='sudo' # set command prefix for non-admins
  case $1 in                            # start conditionals
    uninstall )                         # do if uninstall parameter given
      uninstall;;                       # uninstall binaries & backups
    * )                                 # do if no known parameters given
      audit                             # check existence of required apps
      install                           # install missing docker apps
      update;;                          # check docker app versions for updates
  esac                                  # end conditionals
  exit 0                                # exit script with success code
} #}}}

init "$@"
