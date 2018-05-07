#!/bin/bash

  ###########################################################
  ## filename: bus_bootstrap.sh                            ##
  ## path:     ~/src/deploy/localhost/docker/                                      ##
  ## date:     12/22/2015                                  ##
  ## purpose:  BuS:D8 (Boxed up Stack: Drupal 8) bootstrap ##
  ## repo:     https://github.com/DevOpsEtc               ##
  ###########################################################

# vim: set fdm=marker:                      # treat triple braces as folds
# set -e

# notes {{{
# install:
#   1. change directory to BuS scripts
#     $ cd ~/src/deploy/localhost/docker/scripts
#   2. set scripts to executable
#     $ chmod +x {bus_app.sh,bus_bootstrap.sh,cloud_bootstrap.sh,vm_nfs.sh}
#   3 source script
#     $ ./bus_bootstrap.sh
#     or
#     $ bus
# uninstall:
#   $ bus uninstall
# }}}
# variables {{{
rs=$(tput sgr0)                                 # reset text attributes
blue=$(tput bold)$(tput setaf 33)               # set text bold & blue
red=$(tput bold)$(tput setaf 160)               # set text bold & red
yellow=$(tput bold)$(tput setaf 136)            # set text bold & yellow
green=$(tput bold)$(tput setaf 64)              # set text bold & green
b_projects="$HOME/docker/projects"                 # path to bus projects
b_build_src="$HOME/docker/build"                   # path to build source
b_archive="$b_projects/archive"                 # path to bus projects
timestamp=$(date +_%Y.%m.%d_%H.%M)              # append data & time to files
d_base="/var/www/public"                        # path to drupal base install
d_settings="$d_base/sites/default/settings.php" # path to drupal settings.php
d_files="$d_base/sites/default/files/*"         # path to drupal files folder
d_db_path="/var/lib/MYSQL"                      # path to drupal database
d_db_name=bus                                   # name of drupal database
app_err=0                                       # app audit
env_file=0                                      # env_file
COLUMNS=20                                      # select menu: vertical layout
PS3=$(echo -e "$green \nenter number: $rs")     # select menu: default prompt
mach_env=0                                      # push env var to bashrc
step=0                                          # starting step number
step_last=                                      # store current step
step_tot=6                                      # total steps
# }}}
logo() { # {{{
  # purpose: display pre-rendered figlet output
  # only display if screen is wide enough
  if (( $(tput cols) >= 40 )); then
    echo -e "$blue
  ┏━━━━━━━━━━━━━━━━━━━━━┓
  ┃     ___      ___    ┃
  ┃    | _ )_  _/ __|   ┃
  ┃    | _ \ || \__ \   ┃
  ┃    |___/\_,_|___/   ┃
  ┃                     ┃
  ┗━ Boxed up Stack: D8━┛ $rs"
  fi
} # }}}
step_count(){ # {{{
  # do not increment counter if step_stop set
  if [ ! "$step_stop" == "1" ]; then
    ((step++)) # advance step count
    step_last=$step
  else
    step=$step_last
  fi
  echo -e "$yellow\n===================================="
  echo -e "$yellow#### step $step of $step_tot: $step_name ####"
  echo -e "$yellow==================================== $rs"
  sleep 1
  step_stop=0
} # }}}
audit() { # {{{

# also audit bus_version # to see if latest @ gitHub

  # step counter & title display
  step_name="audit setup" # name of current step
  step_count              # call function to dislay current/total step numbers

  ./bus_app.sh            # check existence of required apps & version updates

  # do if bus_func is not already being sourced
  echo -e "$green\n \bchecking for BuS functions & aliases... $rs"
  # do if file not exist
  if [ ! -e $HOME/.bash_extra/bus_func ]; then
    echo -e "$blue\n \bno BuS functions & aliases found $rs"

    # inject sourcing loop into bashrc
    echo -e 'for f in ~/.bash_extra/*; do . "$f"; done # source additional directives' >> $HOME/.bashrc
    # echo -e '\n# source extra directives' >> $HOME/.bashrc
    # echo -e 'for f in $HOME/.bash_extra/bash*; do . "$f"; done' >> $HOME/.bashrc

    # create hidden directory, if not already there
    if [ ! -d $HOME/.bash_extra ]; then mkdir $HOME/.bash_extra; fi
    # [ ! -d $HOME/.bash_extra ] && mkdir $HOME/.bash_extra

    # create symlink to BuS directives
    ln -s $HOME/docker/bus_func $HOME/.bash_extra/bus_func
    ln -s $HOME/docker/bus_alias $HOME/.bash_extra/bus_alias

    # call function to source bashrc to pickup bus.bash changes
    echo -e "$green\n \bloading BuS functions & aliases... $rs"
    source_bash
  else
    echo -e "$blue\n \bBuS functions & aliases already loaded... $rs"
  fi

  # docker machine check
  if docker-machine ls -q | grep -q '^.'; then # do if there is a docker machine
    # list machines
    echo -e "$green\n \bchecking docker machines... \n$rs"
    echo -e "$blue \b============================================================================ "
    docker-machine ls
    echo -e " \b============================================================================ $rs"

    # docker image check
    if ! docker images -q | grep -q ""; then # do if there is a docker image
      echo -e "$green\n \bchecking docker images... \n$rs"
      echo -e "$blue \b$(docker images) $rs"

      # check docker containers
      if ! docker ps -aq | grep -q ""; then # do if there is a docker container
        echo -e "$green\n \bchecking docker containers... \n$rs"
        echo -e "$blue \b$(docker ps -a --format "{{.Names}}\\t{{.Status}}") $rs"
      fi
    fi
  fi
  echo -e "$yellow\n \b#### auditing complete #### $rs"
} # }}}
mach_task_menu() { # {{{
  # only show task menu if a machine exists
  if docker-machine ls -q | grep -q '^.'; then
    echo -e "$green \b_________________________________ $rs"
    echo -e "$green \bmachine tasks | choose task ⬇ \n$rs"
    # start looping menu
    select choice in "remove machine" "create machine" "QUIT"; do
      case $choice in
        "remove machine" ) mach_rm_menu; break;;
        "create machine" ) mach_create; break;;
        "QUIT" ) clear; logo; exit 0;;
      esac
    done # end menu
  fi
} # }}}
mach_create() { # {{{
  # step counter & title display
  step_name="create machine" # name of current step
  step_count                 # call function to dislay current/total step numbers

  # reset variables
  unset mach_name
  mach_rm=0
  proj_rm=0

  # enter machine name
  while [ -z "$mach_name" ]; do # loop display of read prompt if input blank
    echo -e "$green\n \b________________________________________________ $rs"
    read -p "$(echo -e "$green \bmachine tasks | create | enter machine name: $rs")" mach_name
    mach_name=${mach_name// /-}             # replace input spaces with dashes
    mach_name=${mach_name//[^a-zA-Z0-9-]/}  # alphanumeric & dash validation
  done

  echo -e "$green\n \b______________________________________________ $rs"
  echo -e "$green \bmachine tasks | create | choose machine type ⬇ \n$rs"
  # start looping menu
  select choice in "VirtualBox" "DigitalOcean"; do
    case $choice in
      VirtualBox )
        mach_tld=".dev"   # appended to $mach_name
        mach_type="local" # destination type
        # set variable to virtualbox driver parameters
        mach_driver="
        --driver virtualbox
        --virtualbox-cpu-count "1"
        --virtualbox-disk-size "20000"
        --virtualbox-hostonly-cidr "192.168.99.1/24"
        --virtualbox-memory "1024""
        break;;
        # --virtualbox-no-share "true""
      DigitalOcean )
        while [ -z "$dat" ]; do # loop prompt for digital access token if blank
          echo -e "$green\n \b______________________________________________ $rs"
          read -sp "$(echo -e "$green \bmachine tasks | create | enter access token: $rs")" dat
        done
        mach_tld=".com"
        mach_type="cloud"
        mach_driver="
        --driver digitalocean
        --digitalocean-access-token=$dat
        --digitalocean-region="sfo1"
        --digitalocean-size="512mb""
        break;;
    esac
  done # end menu

  # create project name
  proj_name=$mach_name

  # concatenate name + tld variables
  mach_name=$mach_name$mach_tld

  # call function to check for existing machines & project folders
  mach_exist

  # do if an existing machine was not removed
  if [ ! "$mach_rm" == "1" ]; then
    echo -e "$yellow\n \bcreate $choice machine ($mach_type): $mach_name? \n$rs"
    select choice in "Yes" "No"; do # start looping menu
      case $choice in
        Yes ) echo; docker-machine create $mach_driver $mach_name; break;;
         No ) create;;
      esac
    done # end menu

    # wait till machine is running before continuing
    while ! docker-machine ls -q --filter state=Running | grep -q "$mach_name"; do
      printf '.'
      sleep 1
    done

    # set machine active for current shell
    echo -e "$green\n \bsetting machine active: $mach_name... $rs"
    eval "$(docker-machine env $mach_name)"

    # show listing for new machine
    echo -e "$blue\n \b==================================================================== $rs"
    echo -e "$blue \b$(docker-machine ls | grep "$mach_name")$rs"
    echo -e "$blue \b==================================================================== $rs"
  fi
  # do if machine is local
  if [ "$mach_tld" == ".dev" ]; then
    mach_active # set a default active machine for new shells
    data        # create and populate file structure
  fi
  echo -e "$yellow\n \b#### create machine complete ####"
} # }}}
mach_exist() { # {{{
  # do if machine name matches existing machine
  if $(docker-machine ls -q | grep -q -w $mach_name); then
    echo -e "$blue\n \bdocker machine already exists: $rs"
    echo -e "$blue \b==================================================================== $rs"
    echo -e "$blue \b$(docker-machine ls | grep -w $mach_name) $rs"
    echo -e "$blue \b==================================================================== $rs"
    echo -e "$green\n \breplace machine: $mach_name? \n$rs"
    select choice in "Yes" "No"; do # start looping menu
      case $choice in
        Yes) mach_rm=2; break;;
         No) mach_rm=1; break;;
      esac
    done # end menu
  fi

  # do if project name matches existing project folder
  if [ -d "$b_projects/$proj_name" ]; then
    echo -e "$blue\n \bproject folder exists for: $proj_name \n$rs"
    echo -e "$blue ==================================================================== $rs"
    echo -e "$blue \b$(ls -d $b_projects/$proj_name) $rs"
    echo -e "$blue \b$(ls -Ahl $b_projects/$proj_name) $rs"
    echo -e "$blue \b==================================================================== $rs"
    echo -e "$green\n \barchive & remove project folder: $proj_name? \n$rs"
    select choice in "Yes" "No"; do # start looping menu
      case $choice in
        Yes) proj_rm=2; break;;
         No) proj_rm=1; break;;
      esac
    done # end menu
  fi
  # call function to remove machines & project folders
  mach_rm
} # }}}
mach_active() { # {{{
  # do if machine is not the default active machine
  if ! grep -q "mach_name=$mach_name" ~/src/deploy/localhost/docker/bus.bash; then

    # display prompt asking to set default active machine for new shells
    echo -e "$green\n \bset default active machine (new shells): $mach_name? \n$rs"
    select choice in "Yes" "No"; do # start looping menu
      case $choice in
        Yes) # update default active machine assignment
             sed -i '' "s/mach_name=.*/mach_name=$mach_name/" ~/src/deploy/localhost/docker/bus.bash
             source_bash # call function: source bashrc to grab bus.bash update
             echo -e "$blue\n \bdefault active machine set: $(docker-machine active) $rs"
             break;;
         No) break;;
      esac
    done # end menu
  else
    echo -e "$blue\n \bdefault active machine already set: $(docker-machine active) $rs"
  fi
} # }}}
data() { # {{{
  # create project folder structure
  # do if machine is local; do if existing project folder was removed
  # if [ "$mach_tld" == ".dev" ] && [ ! "$proj_rm" == "1" ]; then
  if [ ! "$proj_rm" == "1" ]; then
    # copy build templates
    echo -e "$green\n \bgit clone build repo... $rs"
    echo -e "\n$blue \b$(git clone $b_build_src $b_projects/$proj_name/build 2>&1) $rs"

    # create data directories
    echo -e "$green\n \bcreating data directory... $rs"
    mkdir -p $b_projects/$proj_name/data/{www/private/{aux,files,tmp},db/{lib,log}}
    echo -e "\n$blue \b$(ls -d $b_projects/$proj_name/data/*/*)$rs"

    # create empty git repo
    git_path="-C $b_projects/$proj_name/data"
    echo -e "$green\n \bcreate $mach_type git repo... \n$rs"
    echo -e "$blue \b$(git $git_path init)"

    # create local .gitignore file
    echo -e "$green\n \bpopulating local .gitignore... \n$rs"
    git_ignore # call function to build out local .gitignore

    # add file contents to index
    echo -e "$green \badding all project data files to repo index... $rs"
    git $git_path add .

    # record changes to repo
    echo -e "$green\n \binitial commit... \n$rs"
    echo -e "$blue \b$(git $git_path commit -m "Initial Commit BuS: $proj_name")"

    # show working tree status
    echo -e "$green\n \brepo status... \n$rs"
    echo -e "$blue \b$(git $git_path status)"

    # swap out default vboxsf share with nfs
    echo -e "$yellow\n============================================== $rs"
    echo -e "$yellow \bcreate persistant nfs mount on machine: $mach_name $rs"
    echo -e "$yellow \b============================================== $rs"

    # pass machine name parameter to nfs setup script
    ./vm_nfs.sh "$mach_name"
  fi
} # }}}
git_ignore() { # {{{
  file_names=(
    '\n### OSX ################################'
    .DS_Store
    .Spotlight-V100
    .Trashes
    '\n### Docker #############################'
    '\n# env_files'
    env.*
    '\n### Composer #############################'
    core
    vendor
    '\n### Drupal #############################'
    '\n# Ignore configuration files that may contain sensitive information.'
    sites/*/*settings*.php
    sites/*/*services*.yml
    '\n# Ignore paths that contain generated content.'
    sites/*/files
    sites/*/private
    '\n# Ignore default text files'
    robots.txt
    /CHANGELOG.txt
    /COPYRIGHT.txt
    /INSTALL*.txt
    /LICENSE.txt
    /MAINTAINERS.txt
    /UPGRADE.txt
    /README.txt
    sites/all/README.txt
    sites/all/modules/README.txt
    sites/all/themes/README.txt
    '\n# Ignore everything but the "sites" folder ( for non core developer )'
    .htaccess
    web.config
    authorize.php
    cron.php
    index.php
    install.php
    update.php
    xmlrpc.php
    /includes
    /misc
    /modules
    /profiles
    /scripts
    /themes
  )
  for name in "${file_names[@]}"; do
    echo -e "$name" >> $b_projects/$proj_name/data/.gitignore
  done
} # }}}
mach_rm_menu() { # {{{
  # loop display of menu until choice is "DONE"
  while true; do
    # only do if there is something to remove
    if docker-machine ls -q | grep -q '^.'; then
      echo -e "$green\n \b______________________________________________ $rs"
      echo -e "$green \bmachine tasks | remove | choose machine(s) ⬇ \n $rs"
      # array of current machine names + ALL & DONE
      mach_list=($(docker-machine ls -q))
      # enables pattern lists
      shopt -s extglob
      pat_mat="@($(IFS="|$IFS"; printf "${mach_list[*]}"))"
      shopt -u extglob

      # generate & display menu using array elements from mach_list
      select mach_name in "${mach_list[@]}" "ALL" "DONE"; do
        case $mach_name in
          $pat_mat )
            cmd_1='mach_rm=2; proj_rm=2; mach_rm; mach_rm_menu'
            cmd_2='break'
            mach_rm_confirm;;
          "ALL" )
            cmd_1='for mach_name in ${mach_list[@]}; do mach_rm=2; proj_rm=2; remove; done'
            cmd_2='create'
            mach_rm_confirm;;
          "DONE" ) create;;
        esac
      done # end menu
    else # only do if there is nothing to remove
      break 2 # return to machine task menu
    fi
  done
} # }}}
mach_rm() { # {{{
  # action_confirm() {
  #}
  if [ "$mach_rm" == "2" ]; then
    echo
    # remove machine
    echo -e "$green \bremoving machine: $mach_name... \n$rs"
    echo -e "$blue \b$(docker-machine rm -f $mach_name) $rs"

    # remove machine name variable for default active machine
    echo -e "$green\n \bremoving shell variables for: $mach_name... \n$rs"
    sed -i '' 's/mach_name=.*/mach_name=/' ~/src/deploy/localhost/docker/bus.bash

    # remove docker-machine shell variables
    echo -e "$blue \beval $(docker-machine env -u) $rs"

    # call function to source bashrc to pickup bus.bash changes
    source_bash

    # remove nfs export entry
    echo -e "$blue\n \bremoving NFS export entries on OSX for $mach_name... $rs"
    # comment any line containing new docker machine name; prepend "# "
    sudo sed -i '' "/$mach_name/ s/^#*\ */#\ /" /etc/exports

    # remove host entry
    echo -e "$blue\n \bremoving hosts entry on OSX for $mach_name... $rs"
    # comment any line containing new docker machine name; prepend "# "
    sudo sed -i '' "/$mach_name/ s/^#*\ */#\ /" /etc/hosts

    # reset machine removal variable
    mach_rm=0
  fi

  if [ "$proj_rm" == "2" ] && [ -d "$b_projects/$proj_name" ]; then
    echo
    # make directory
    mkdir -p $b_archive

    # compress project folder and move to project archive
    echo -e "$blue \barchiving project folder: $proj_name... \n$rs"
    tar -cvzf $b_archive/$proj_name$timestamp.tar.gz -C $b_projects $proj_name

    # show archived project folder location
    echo -e "$green\n \barchive was created here: $blue\n"
    ls -d $b_archive/$proj_name*

    # remove old project folder
    rm -rf $b_projects/$proj_name

    # reset project removal variable
    proj_rm=0
  fi
} # }}}
mach_rm_confirm() { # {{{
  # confirm machine removal
  echo -e "$yellow\n \bconfirm machine removal: $mach_name? \n$rs"
  select choice in "Yes" "No"; do # start looping menu
    case $choice in
      Yes) eval $cmd_1; eval $cmd_2;;
       No) mach_rm_menu;;
    esac
  done # end menu
} # }}}
source_bash(){ # {{{
  # source bash to pickup up changes in bus.bash; eat output
  echo -e "$green\n \bsourcing bash... $rs"
  . $HOME/.bashrc &>/dev/null
} # }}}
prep() { # {{{
  # step counter & title display
  step_name="prep setup" # name of current step
  step_count             # call function to dislay current/total step numbers

  echo -e "$green \bcheck for existing BuS... $rs"
  # only do if bus exists
  if [ -f $d_settings ]; then
    echo -e "$blue\n \bBuS was found \n$rs"
    echo -e "$green\n \b============================"
    echo -e "Drupal install methods ⬇ \n$rs"
    # array of drupal install methods
    drup_inst=("Fresh Install" "Reinstall" "DONE")
    # generate & display menu using array elements from drup_inst
    select inst in "${drup_inst[@]}"; do
      # only do if valid choice
      if [ -n "$inst" ]; then
        # only do if choice is not "DONE"
        if [ ! "$inst" == "DONE" ]; then
          echo -e "$blue\n \b$REPLY ➙ $inst \n$rs"
          # only do if choice is "Fresh Install"
          if [ "$inst" == "Fresh Install" ]; then
            echo -e "$blue\n \bremoving Drupal installation files $rs"
            docker exec -it web rm -rf $d_base

            # only do if Drupal database exists
            if [ -d $d_db_path/$d_db_name ]; then
              echo -e "$blue\n \bremoving Drupal database & logs $rs"
              docker exec -it db rm -rf $d_db_path/{$d_db_name,logs}
            fi

            # only do if Docker db service exists
            if docker ps -a | grep -q db; then
              echo -e "$blue\n \bremoving Docker db container & image $rs"
              docker kill $(docker ps -aq --filter="name=db") 2> /dev/null
              docker rm $(docker ps -aq --filter="name=db") 2> /dev/null
              docker rmi $(docker images | grep db) 2> /dev/null
            fi

          # only do if choice is "Reinstall"
          elif [ "$inst" == "Reinstall" ]; then
            echo -e "$blue\n \bremoving Drupal settings.php & files/* $rs"
            docker exec -it tools drush -yv sql-drop
            docker exec -it web rm -rf $d_settings
            docker exec -it web rm -rf $d_files
          fi

          # only do if Docker tools service exists
          if docker ps -a | grep -q "tools"; then
            echo -e "$blue\n \bremoved Docker tools container & image $rs"
            docker kill $(docker ps -aq --filter="name=tools") 2> /dev/null
            docker rm $(docker ps -aq --filter="name=tools") 2> /dev/null
            docker rmi $(docker images | grep tools) 2> /dev/null
          fi

          # do if orphaned images exist
          if ! docker images -f "dangling=true" | grep -q ""; then
            docker images -f "dangling=true" -q 2> /dev/null
          fi
        # only do if choice is "DONE"
        else
          break
        fi
      # only do if choice is invalid
      else
        echo -e "$red\n \b$REPLY ➙ Try Again! $rs"
      fi
    done
  # only do if bus doesn't exist
  else
    echo -e "$blue\n \bno BuS yet $rs"
    sleep 1
  fi
  echo -e "$yellow\n \b#### prepping complete #### $rs"
} # }}}
env_file_menu() { # {{{
  # step counter & title display
  step_name="set env_file" # name of current step
  step_count               # call function to dislay current/total step numbers

  echo -e "$green \b_________________________________ $rs"
  echo -e "$green \bchoose input method for env_file ⬇ \n$rs"
  #
  select choice in "Manually Edit" "Input Injection" "Help"; do # start looping menu
    echo -e "$blue\n \b$REPLY ➙ $choice \n$rs"
    case $choice in
      "Manually Edit" )
        read -n 1 -p "$(echo -e "$yellow \bedit env_files, then press any key to continue: $rs")";;
      "Input Injection" )
        env_file;;
      "Help" )
        echo -e "\n$yellow \b explain differences between manually edit & input injection$rs";;
    esac
  done # end menu
  echo -e "$yellow\n \b#### set env_file complete #### $rs"
} # }}}
env_file() { # {{{

# if tld == ".com"; then
#
# loop through injection twice & 2nd pass alter name of vars

  # array of env var arrays
  var_names=("var_mysql" "var_ssmtp" "var_drup")

  # array of env vars (db service)
  var_mysql=(
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_PASSWORD"
    # "MYSQL_USER"
    # "MYSQL_DATABASE"
    # "MYSQL_DATABASE_HOST"
    )

  # array of env vars (php service)
  var_ssmtp=(
    "SMTP_NAME"
    "SMTP_PASS"
    # "SMTP_ROOT"
    # "SMTP_REWRITE_DOMAIN"
    # "SMTP_MAILHUB"
    )

  # array of env vars (tool service)
  var_drup=(
    "DRUP_ADMIN_PASS"
    "MYSQL_ROOT_PASSWORD"
    # "BUILD"
    # "DRUP_DB"
    # "DRUP_ADMIN"
    # "DRUP_ADMIN_MAIL"
    )

  # loop through array of env_file path names
  for n in "${var_names[@]}"; do

    # do if wipe vars was chosen
    if [ $clean == "1" ]; then
      echo -e "$green\n \berasing $blue${n}$green variables in $blue \b$m_var_path $rs"
      # loop through array of varible names
      for v in $(eval echo \$\{$n[@]}); do
        # clear recently added variables from env_file
        sed -i '' "s/${v}=.*/${v}= /" $b_build$m_var_path
      done
      clean=0
    else
      # initial counter to track input step
      count=0
      # loop through array of env_file variables
      for v in $(eval echo \$\{$n[@]}); do
        # increment counter
        ((count++))

        # spit out current count/total count
        echo -e "$green \n  ${n} input: $count/$(eval echo \$\{#$n[@]}): $rs"

        # do following while each shell variable is unset
        while [ -z "$(eval echo '$'${v})" ]; do
          echo
          # display prompt asking for shell variable input
          read -spr "$(echo -e "$blue \b enter ${v}: $rs")" ${v}
        done
        echo
      done

      # set which env_file to use
      case $n in
        var_mysql ) m_var_path=mariadb/env$mach_tld;;
        var_ssmtp ) m_var_path=php-fpm/env$mach_tld;;
        var_drup ) m_var_path=tools/env$mach_tld;;
      esac

      # push new shell variables to respective docker compose env_file
      echo -e "$blue\n \bpushing ${n} variables to $m_var_path $rs"
      # loop through array of varible names
      for v in $(eval echo \$\{$n[@]}); do
        # inject variables to env_file
        sed -i '' "s/${v}=.*/${v}=$(eval echo '$'${v}) /" $b_projects/$mach_name/$m_var_path
      done

      # clear shell variables
      for v in "$(eval echo '$'{${n}[@]})"; do
        echo -e "$green\n \bunset shell variables: $rs$blue${v}$rs"
        unset ${v}
      done
    fi
  done
} # }}}
compose() { # {{{
  # step counter & title display
  step_name="docker compose build" # name of current step
  step_count                       # fuction: dislay current/total step numbers

  # build docker images and run containers
  docker-compose -f $b_build/docker-compose.yml up -d

  # run docker-compose logs in tmux pane if exists, otherwise use terminal
  osascript -e 'tell app "Terminal" to do script "docker-compose -f $b_build/docker-compose.yml logs" activate'

  # show new Docker images & containers
  echo -e "$blue \b$(docker ps -a --format "{{.Names}} | {{.Status}} | {{.Ports}}") $rs"
  echo -e "$yellow\n \b#### docker compose build complete #### $rs"
} # }}}
post () { # {{{
  step_name="post build" # name of current step
  step_count             # call function to dislay current/total step numbers

  # display prompt asking to wipe vars in env_files
  read -p "$(echo -e "$green \bwipe inputed vars in env_files (y/n)? $rs")" choice
  case "$choice" in
    y) clean=1; env_file;;
    n) echo -e "$blue\nenv_files not wiped, but in .gitignore! $rs";;
    *) echo -e "$red\ninvalid! $rs"; continue;;
  esac

  # if not already there, append host entry for new drupal site
  echo -e "$green \nchecking for host entry...$rs"
  if ! grep -q $(docker-machine ip $mach_name)'  $mach_name' /etc/hosts; then
    echo "$(docker-machine ip $mach_name)  $mach_name" | sudo tee -a /etc/hosts
    echo -e "$blue \nhost entry added for: $mach_name $rs"
  else
    echo -e "$blue \nhost entry already exists for: $mach_name $rs"
  fi;
  sleep 1

  # open new drupal site after drush site-install completes
  echo -e "$green \nWaiting on Drupal website installation..."
  docker exec -it web /bin/bash -c 'while [ ! -d /var/www/$mach_name/public/sites/default/files/styles ]; do printf '.'; sleep 1; done'

  # open new site in browser
  echo -e "$blue \nOpening new Drupal site: $rs"
  open http://$mach_name

  echo -e "$yellow\n \b#### post build complete #### $rs"
  echo -e "$blue \nBuS installed successfully! $rs"
} # }}}
init() { # {{{
  clear             # clear screen
  logo              # display bus logo
  sleep 1           # wait # seconds before continuing
  clear             # clear screen
  if [ "$1" == "remove" ]; then
    bus_rm          # function to remove directories, bus_aliases, if apps installed via script, prompt to remove (./bus_app remove), otherwise remind to manually remove, hosts, exports, thanks for trying BuS: Drupal 8
  fi
  audit             # audit required apps, and list docker images/containers
  while true; do    # loop display of menu
    mach_task_menu  # docker-machine tasks
    prep            # check existing BuS
    env_file_menu   # docker-compose env_file population
    # compose         # docker-compose build
    # post            # one-off tasks
    source_bash     # call function to source bashrc to pickup bus.bash changes
    echo -e "$green\n \bgo back to machine tasks? \n$rs"
    select choice in "Yes" "No"; do # start looping menu
      case $choice in
        Yes ) step_stop=1; break;;
         No ) break 2;;
      esac
    done            # end menu
  done              # end of project tasks loop
  clear             # clear screen
  logo              # display bus logo
  exit 0            # successful exit code
} #}}}

init "$@"
