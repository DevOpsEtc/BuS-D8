  ###############################################
  ##  filename: bus_func                       ##
  ##  path:     ~/src/deploy/localhost/docker/                         ##
  ##  purpose:  BuS functions                  ##
  ##  date:     02/10/2016                     ##
  ##  repo:     https://github.com/DevOpsEtc  ##
  ###############################################

# vim: set fdm=marker:                        # treat triple braces as folds

# variables {{{
# default machine
def_mach=dev
# text attributes
rs=$(tput sgr0)                               # reset
blue=$(tput bold)$(tput setaf 33)             # bold & blue
red=$(tput bold)$(tput setaf 160)             # bold & red
yellow=$(tput bold)$(tput setaf 136)          # bold & yellow
green=$(tput bold)$(tput setaf 64)            # bold & green
bus_func="$HOME/docker/bus_func"                 # path to bus_func (self)
bus_ver=1.0                                   # bus version
bus_repo="https://github.com/DevOpsEtc/BuS"  # bus repository url
PS3=$(echo -e "$green\nenter number: $rs")    # select menu prompt
proj="$HOME/docker/projects"                     # default project folder
# p_m="$HOME/docker/projects/$mach_name"
shopt -s extglob                              # enable pattern lists
# }}}
source_bash(){ # {{{
  # source bash to pickup up changes in bus_func; eat output
  echo -e "$green\n \bsourcing shell to pick up changes... $rs"
  . $HOME/.bashrc &>/dev/null
} # }}}
pattern_match() { # {{{
  # purpose: properly format mach_list for case pattern match
  pat_mat="@($(IFS="|$IFS"; printf "${mach_list[*]}"))"
} # }}}
picker_boolean() { # {{{
  # purpose: display boolean picker & assign choice to variable
  echo -e "$green\n \b_______________________________________________ $rs"
  # print title (pulled from calling function)
  echo -e "$green \b$title ⬇ \n $rs"
  select choice in "Yes" "No"; do # start looping menu
    case $choice in
      Yes ) break;;
       No ) break;;
        * ) continue;;
    esac
  done # end menu
} # }}}
picker_machine() { # {{{
  # purpose: display docker machine picker & assign chosen name to variable
  echo -e "$green\n \b_______________________________________ $rs"
  # print title (pulled from calling function)
  echo -e "$green \b$title ⬇ \n $rs"
  select name in "${mach_list[@]}" "QUIT"; do # start looping menu
    case $name in
      $pat_mat ) break;;        # return to calling function
          QUIT ) kill -INT $$;; # terminate calling function
             * ) continue;;     # loop menu
    esac
  done # end menu
} # }}}
hush() {
  "$@" &>/dev/null & disown
}

send_background() { # {{{
  # purpose: show activity indicator for longer running commands
  # push command parameter to background; eat stdout & stderr
  { "$@" & disown; } > /dev/null 2>&1

  # grab last process id
  local pid=$!

  # set delay between spin frames
  local delay=0.05

  # starting spin frame
  frame_start=0

  # define spin cycle frames
  # spin_frames='/-\|'
  spin_frames="◓◑◒◐"

  # number of spin frames
  frame_count=${#spin_frames}

  # print command message to screen
  printf "$msg_1 "

  # hide cursor during spin cycle
  tput civis

  # loop while process id is alive
  while [ $(ps -eo pid | grep $pid) ]; do
    # print spin cycle to screen
    printf '\b%s' "${green}${spin_frames:frame_start++%frame_count:1}"
    # delay between each frame print
    sleep $delay
  done

  # show cursor after spin cycle
  tput cnorm

  echo
} # }}}
machine_check() { # {{{
  # purpose: check for existance of docker machines
  case $1 in
    # do if passed parameter is "preexist"
    preexist )
      # do if name parameter matches existing machine
      if [ docker-machine ls -q | grep -q "$2" ]; then
        echo -e "$yellow\n \bBuS: $2 already exists! $rs"
        # terminate parent function
        kill -INT $$
      else
        if [ -d "$proj/$2" ]; then
          echo -e "$yellow\n \bBuS project folder: $2 already exists! $rs"
          # terminate parent function
          kill -INT $$
        fi
      fi;;
    # do if parameter empty/non-matching
    * )
      # do if default active BuS machine exists
      if docker-machine ls -q | grep -q "^$def_mach"; then
        # do if default active BuS machine not running
        if [ $(docker-machine status $def_mach) != "Running" ]; then
          echo -e "$yellow\n \bdefault BuS not running! $rs"
          echo -e "$green\n \b________________________ $rs"
          echo -e "$green \bstart or pick another? ⬇ \n $rs"
          # start looping menu
          select choice in "Start BuS" "Pick Another" "QUIT"; do
            case $choice in
              Start\ BuS )
                # call function: start machine
                machine_on $def_mach
                # do if active BuS unset; call function: set active BuS
                [ -z $act_mach ] && machine_set_act $def_mach q
                break;;
              Pick\ Another )
                # call function: set default BuS
                machine_set_def
                if [ $(docker-machine status $def_mach) != "Running" ]; then
                  # call function: start machine
                  machine_on $def_mach
                fi
                # call function: set active BuS
                machine_set_act $def_mach q
                break;;
              QUIT )
                # terminate parent function
                kill -INT $$;;
            esac
          done # end menu
        else
          # do if active BuS unset; call function: set active BuS
          [ -z $act_mach ] && machine_set_act $def_mach q
        fi
      else
        echo -e "$yellow\n \bdefault BuS missing! $rs"
        # array of machines; exclude default BuS
        mach_list=($(docker-machine ls -q | grep -v "$def_mach"))
        # do if mach_list is empty
        if [ ${#mach_list[@]} -eq 0 ]; then
          title="create new BuS machine?"
          # call function: display boolean picker
          picker_boolean
          case $choice in
            Yes )
              # call function: create new machine
              machine_new
              break;;
            No )
              # terminate parent function
              kill -INT $$;;
          esac
        else
          echo -e "$green\n \b__________________________________ $rs"
          echo -e "$green \bcreate new BuS or pick another? ⬇ \n $rs"
          # start looping menu
          select choice in "Create New" "Pick Another" "QUIT"; do
            case $choice in
              Create\ New )
                # call function: create new machine
                machine_new
                break;;
              Pick\ Another )
                # call function: set default BuS
                machine_set_def
                if [ $(docker-machine status $def_mach) != "Running" ]; then
                  # call function: start machine
                  machine_on $def_mach
                fi
                # call function: set active BuS
                machine_set_act $def_mach q
                break;;
              QUIT )
                # terminate parent function
                kill -INT $$;;
            esac
          done
        fi
      fi;;
  esac
} # }}}
machine_env() { # {{{
  # purpose: list active BuS machines
  echo -e "$blue\n \bBuS State: $bus_state $rs"
  echo -e "$blue \bBuS default active: $def_mach $rs"
  echo -e "$blue \bBuS current active: $act_mach $rs"
} # }}}
machine_ssh() { # {{{
  # purpose: ssh to docker host, docker exec to docker container
  # array of running machines
  mach_list=($(docker-machine ls -q --filter state=Running))

  # call function: format mach_list for case match
  pattern_match

  # parameter conditionals
  case $1 in
    # do if passed parameter exists in mach_list
    $pat_mat )
      mach_name=$1;;
    # do if passed parameter is "menu"
    m|menu )
      title='choose machine to connect to'
      # call function: display machine picker
      picker_machine
      mach_name=$name;;
    # do if passed parameter non-match/empty
    * )
      mach_name=$act_mach;;
  esac
  echo -e "$blue\n \bconnecting to $mach_name... $rs"
  docker-machine ssh $mach_name
} # }}}
machine_ip() { # {{{
  # purpose: get docker machine ip address
  # array of machine names
  mach_list=($(docker-machine ls -q --filter state=Running))

  # call function: format mach_list for case match
  pattern_match

  # parameter conditionals
  case $1 in
    # do if passed parameter exists in mach_list
    $pat_mat )
      mach_list2=($1);;
    # do if passed parameter is "all"
    a|all )
      mach_list2=("${mach_list[@]}");;
    # do if passed parameter empty/non-match
    * )
      mach_list2=($act_mach);;
  esac
  echo
  for i in "${mach_list2[@]}"; do
    echo -e "$blue \b$i\tIP address: $(docker-machine ip $i)"
  done
} # }}}
machine_list() { # {{{
  # purpose: list docker machines & respective info
  echo $blue
  # parameter conditionals
  case $1 in
    q ) docker-machine ls -q;;
    f ) docker-machine ls;;
    * ) docker-machine ls --format "{{.Name}} {{.Active}} {{.State}} {{.URL}}" \
      | column -t;;
  esac
} # }}}
machine_new() { # {{{
  # purpose: create new docker machine
  # enter machine name
  try_cnt=0
  unset mach_name

  # loop display of read prompt if input blank
  while [ -z "$mach_name" ] && [ $try_cnt -lt 2 ]; do
    # increment try counter
    ((try_cnt++))
    echo -e "$green\n \b___________________________ $rs"
    read -p "$(echo -e "$green \benter new BuS name: $rs")" mach_name
    mach_name=${mach_name//[^a-zA-Z-0-9-]/}  # alphanumeric & dash validation
  done

  if [ -z "$mach_name" ]; then
    echo -e "$yellow\n \bno name supplied! $rs"
    return
  fi

  echo -e "$green\n \b________________________ $rs"
  echo -e "$green \bchoose BuS type ⬇ \n$rs"

  select choice in "local" "cloud" "QUIT"; do # start looping menu
    case $choice in
      local )
        # set machine type
        mach_type=local
        # call function: check if machine already exists
        machine_check preexist $mach_name.$mach_type
        # set driver parameters
        mach_driver="
        --driver virtualbox
        --virtualbox-cpu-count "1"
        --virtualbox-disk-size "20000"
        --virtualbox-hostonly-cidr "192.168.99.1/24"
        --virtualbox-memory "1024""
        break;;
        # --virtualbox-no-share "true""
      AWS )
        mach_type=cloud
        # call function: check if machine already exists
        machine_check existing $mach_name.$mach_type
        title="ready to enter AWS Access Key, Secret Key & VPC ID?"
        # call function: display boolean picker
        picker_boolean
        case $choice in
          Yes ) break;;
          No )
            echo -e "$blue \nOpening AWS: $rs"
            echo -e "$blue \n1. Copy VPC ID: Services -> VPC -> Your VPCs $rs"
            echo -e "$blue \n2. Copy Access Key: Services-> IAM -> Dashboard: \
              Users -> Users -> Security Credentials -> Create Access Key ->  \
              Show Keys to copy and/or download $rs"
            # pause 2 sec to read echo
            sleep 2
            # open aws site in browser
            open https://aws.amazon.com
            break 2;;
        esac
        echo -e "$green\n \b___________________________ $rs"
        read -p "$(echo -e "$green \bpaste AWS Access Key: $rs")" AWS_ACCESS_KEY_ID
        echo -e "$green\n \b___________________________ $rs"
        read -p "$(echo -e "$green \bpaste AWS Secret Key: $rs")" AWS_SECRET_ACCESS_KEY
        echo -e "$green\n \b___________________________ $rs"
        read -p "$(echo -e "$green \bpaste AWS VPC ID: $rs")" AWS_VPC_ID
        # set driver parameters
        mach_driver="
        --driver amazonec2
        --amazonec2-access-key=$AWS_ACCESS_KEY_ID
        --amazonec2-secret-key=$AWS_SECRET_ACCESS_KEY
        --amazonec2-vpc-id=$AWS_VPC_ID"
        # --amazonec2-session-token=$AWS_SESSION_TOKEN
        # --amazonec2-ami=$AWS_AMI
        # --amazonec2-region=$AWS_DEFAULT_REGION
        # --amazonec2-zone=$AWS_ZONE
        # --amazonec2-subnet-id=$AWS_SUBNET_ID
        # --amazonec2-security-group=$AWS_SECURITY_GROUP
        # --amazonec2-instance-type=$AWS_INSTANCE_TYPE
        # --amazonec2-root-size=$AWS_ROOT_SIZE
        # --amazonec2-iam-instance-profile=$AWS_INSTANCE_PROFILE
        # --amazonec2-ssh-user=$AWS_SSH_USER
        break;;
      QUIT ) break;;
    esac
  done # end menu

  # concatenate name & type
  mach_name_combo=$mach_name.$mach_type

  title="create $mach_type BuS machine: $mach_name_combo?"
  # call function: display boolean picker
  picker_boolean
  # do if choice is yes
  if [ $choice == "Yes" ]; then
    msg_1="$green\n \bcreating $mach_type BuS: $mach_name_combo (could \
      take several minutes)... $rs"
    # create new machine; send command to background; display activity spinner
    send_background docker-machine create $mach_driver $mach_name_combo
    # array of machine names
    mach_list=($(docker-machine ls -q))
    # do if this is 1st machine created
    if [ ${#mach_list[@]} -eq 1 ]; then
      echo -e "\n$yellow \bsetting $mach_name_combo as default active BuS...$rs"
      # call function: set default active machine quietly
      machine_env_set default $mach_name_combo q
    fi
    # display machine status
    machine_status $mach_name_combo

    # do if machine is local
    if [ "$mach_type" == "local" ]; then
      echo "call function: data"
      # set project name
        # proj_name=$mach_name
        # data        # create and populate file structure
      fi
    fi
  } #}}}
  machine_off() { # {{{
    # purpose: stop docker host(s)
    # list of all machines running + all
    mach_list=($(docker-machine ls -q --filter state=Running) "ALL")

    # call function: format mach_list for case match
    pattern_match

    # parameter conditionals
    case $1 in
      # do if passed parameter is "all"
      a|all )
        mach_list2=($(docker-machine ls -q --filter state=Running));;
      # do if passed parameter exists in mach_list
      $pat_mat )
        mach_list2=($1);;
      # do if passed parameter is "menu"
      m|menu )
        title="choose machine to stop"
        # call function: display machine picker
        picker_machine
        case $name in
          ALL )
            mach_list2=($(docker-machine ls -q --filter state=Running));;
          $pat_mat )
            mach_list2=($name);;
        esac;;
      # do if passed parameter empty/non-match
      * )
        # call function: check active machine
        # machine_check act
        # do if active machine is running
        if [ $(docker-machine status $act_mach) == "Running" ]; then
          mach_list2=($act_mach)
        else
          echo -e "$yellow\n \b$act_mach already stopped! $rs"
          return
        fi;;
    esac

    for i in "${mach_list2[@]}"; do
      msg_1="$green\n \bstopping $i... $rs"
      # stop machine; call function: send command to background
      send_background docker-machine stop $i
      # call function: display machine status
      machine_status $i
    done
  } # }}}
  machine_on() { # {{{
    # purpose: start docker machine(s)
    # array of machines not currently running + all
    mach_list=($(docker-machine ls -q --filter state=Paused --filter state=Saved \
      --filter state=Stopped --filter state=Error --filter state=Timeout) "ALL")

    # call function: format mach_list for case match
    pattern_match

    # parameter conditionals
    case $1 in
      # do if passed parameter is "all"
      a|all )
        mach_list=($(docker-machine ls -q --filter state=Paused \
          --filter state=Saved --filter state=Stopped \
          --filter state=Error --filter state=Timeout));;
      # do if passed parameter exists in mach_list
      $pat_mat )
        mach_list2=($1);;
      # do if passed parameter is "menu"
      m|menu )
        title="choose machine to start"
        # call function: display machine picker
        picker_machine
        case $name in
          ALL )
            mach_list=($(docker-machine ls -q --filter state=Paused \
              --filter state=Saved --filter state=Stopped \
              --filter state=Error --filter state=Timeout));;
          $pat_mat )
            mach_list2=($name);;
        esac;;
      # do if passed parameter empty/non-match
      * )
        if [ -z $act_mach ]; then
          machine_check
          return
        else
          # do if active machine is not running
          if [ $(docker-machine status $act_mach) != "Running" ]; then
            mach_list2=($act_mach)
          else
            echo -e "$yellow\n \b$act_mach already running! $rs"
            return
          fi
        fi;;
    esac

    for i in "${mach_list2[@]}"; do
      msg_1="$green\n \bstarting $i (could take several minutes)... $rs"
      # stop machine; call function: send command to background
      send_background docker-machine start $i
      # call function: display machine status
      machine_status $i
    done
  } # }}}
  machine_recert() { # {{{
    # purpose: regenerate machine TLS certificates
    # list of all machines running + all
    mach_list=($(docker-machine ls -q --filter state=Running) "ALL")

    # call function: format mach_list for case match
    pattern_match

    # parameter conditionals
    case $1 in
      # do if passed parameter is "all"
      a|all )
        mach_list2=($(docker-machine ls -q --filter state=Running));;
      # do if passed parameter exists in mach_list
      $pat_mat )
        mach_list2=($1);;
      # show picker menu to stop machine if menu parameter passed/empty
      *|m|menu )
        title='choose machine for new TLS certificates'
        # call function: display machine picker
        picker_machine
        case $name in
          ALL )      mach_list2=($(docker-machine ls -q --filter state=Running));;
          $pat_mat ) mach_list2=($name);;
        esac;;
    esac

    for i in "${mach_list2[@]}"; do
      msg_1="$green\n \bregenerating TLS certificates for $i... $rs"
      # machine restart; call function: send command to background
      send_background docker-machine regenerate-certs -f $i
      echo -e "$blue\n \bsuccess $rs"
    done
  } # }}}
  machine_reboot() { # {{{
    # purpose: restart docker machine(s)
    # list of all machines running + all
    mach_list=($(docker-machine ls -q --filter state=Running) "ALL")

    # call function: format mach_list for case match
    pattern_match

    # parameter conditionals
    case $1 in
      # do if passed parameter is "all"
      a|all )
        mach_list2=($(docker-machine ls -q --filter state=Running));;
      # do if passed parameter exists in mach_list
      $pat_mat )
        mach_list2=($1);;
      # do if passed parameter is "menu"
     *|m|menu )
        title='choose machine to restart'
        # call function: display machine picker
        picker_machine
        case $name in
          ALL )
            mach_list2=($(docker-machine ls -q --filter state=Running));;
          $pat_mat )
            mach_list2=($name);;
        esac;;
    esac

    for i in "${mach_list2[@]}"; do
      msg_1="$green\n \brestarting $i (could take several minutes)... $rs"
      # machine restart; call function: send command to background
      send_background docker-machine restart $i
      # call function: display machine status
      machine_status $i
    done
  } # }}}
  machine_remove() { # {{{
    # purpose: remove machine(s)
    # array of machine names + all
    mach_list=($(docker-machine ls -q) "ALL")

    # call function: format mach_list for case match
    pattern_match

    # parameter conditionals
    case $1 in
      # remove machine if passed parameter is "all"
      a|all )
        mach_list2=($(docker-machine ls -q));;
      # remove machine if passed parameter exists in mach_list
      $pat_mat )
        mach_list2=($1);;
      # show picker menu to stop machine if menu parameter passed/empty
      *|m|menu )
        title="choose machine(s) to remove"
        picker_machine
        case $name in
          ALL )
            mach_list2=($(docker-machine ls -q));;
          $pat_mat )
            mach_list2=($name);;
        esac;;
    esac

    for i in "${mach_list2[@]}"; do
      title="remove BuS machine: $i?"
      # call function: display boolean picker
      picker_boolean
      # do if choice is yes
      if [ $choice == "Yes" ]; then
        msg_1="$green\n \bremoving $i (could take several minutes)... $rs"
        send_background docker-machine rm -f $i
        machine_status $i
      else
        echo -e "$yellow\n \b$i not removed $rs"
      fi
    done
  } # }}}
  machine_set_def() { # {{{
    # purpose: assign default active BuS for new shells
    # array of machines; exclude default BuS
    mach_list=($(docker-machine ls -q | grep -v "$def_mach"))

    # do if mach_list is empty
    if [ ${#mach_list[@]} -eq 0 ]; then
    echo -e "\n$yellow \bno other BuS machines to set as default! $rs"
    return
  fi

  # call function: format mach_list for case match
  pattern_match

  # parameter conditionals
  case $1 in
    # do if passed parameter exists in mach_list
    $pat_mat )
      mach_name=$1;;
    * )
      title="pick default active BuS (new shells)"
      # call function: display machine picker
      picker_machine
      mach_name=$name;;
  esac

  # update variable in bus_func file
  echo -e "$green\n \bsetting $mach_name default active (new shells)... $rs"
  sed -i '' "s/^def_mach=.*/def_mach=$mach_name/" $bus_func

  # call function: source bashrc to force source of bus_func (self)
  source_bash

  # do if default active BuS changed
  [ "$mach_name" == "$def_mach" ] && echo -e "$blue\n \bsuccess!"
} # }}}
machine_set_act() { # {{{
  # purpose: set machine active in current shell
  # array of machines minus current active
  mach_list=($(docker-machine ls | grep -v "*" | awk 'NR >= 2 {print $1}'))

  # do if mach_list is empty
  if [ ${#mach_list[@]} -eq 0 ]; then
    echo -e "\n$yellow \bno other BuS machines to set active! $rs"
    return
  fi

  # call function: format mach_list for case match
  pattern_match

  # parameter conditionals
  case $1 in
    # do if passed parameter exists in mach_list
    $pat_mat )
      mach_name=$1;;
    # do if passed parameter empty/non-match
    * )
      title="pick active BuS (current shell only)"
      # call function: display machine picker
      picker_machine
      mach_name=$name;;
  esac

  # do if machine not running
  if [ ! $(docker-machine status $mach_name) == "Running" ]; then
    # call function: start machine
    machine_on $mach_name
  fi

  # grab stderr output
  act_error="$(docker-machine env $mach_name 2>&1 > /dev/null)"

  # do if stderr throws TLS error
  if echo $act_error | grep -q "Error checking TLS connection"; then
    # call function: regenerate TLS certificates
    machine_recert $mach_name
  fi

  # do if (q)uiet parameter wasn't passed
  if [ ! $2 == "q" ]; then
    echo -e "$green\n \bsetting $mach_name active (current shell)... $rs"
  fi

  # set env variables for machine
  eval "$(docker-machine env $mach_name)"

  # assign machine name to act_mach
  act_mach=$mach_name

  # do if (q)uiet parameter wasn't passed
  if [ ! $2 == "q" ]; then
  # do if active BuS changed
    if [ $(docker-machine active) == "$act_mach" ]; then
      echo -e "$blue\n \bsuccess! $rs"
    fi
  fi
} # }}}
machine_status() { # {{{
  # purpose: get status of docker machine

  # array of machine names
  mach_list=($(docker-machine ls -q))

  # call function: format mach_list for case match
  pattern_match

  # parameter conditionals
  case $1 in
    # do if passed parameter exists in mach_list
    $pat_mat )
      mach_list2=($1);;
    # do if passed parameter is "all"
    a|all )
      mach_list2=("${mach_list[@]}");;
    # do if passed parameter empty/non-match
    * )
      mach_list2=($act_mach);;
  esac
  echo

  for i in "${mach_list2[@]}"; do
    # get state & echo as lowercase
    status=$(docker-machine status $i)
    echo -e "$blue \b$i\tis $status" | tr '[A-Z]' '[a-z]'
  done
} # }}}
bus() { # {{{_
  # purpose: aliases to bus functions
  # parameter conditionals
  case $1 in
    act|active )        machine_set_act $2;;
    app )               $HOME/docker/bus_app.sh;;
    arc|archive )       machine_check; machine_archive $2;;
    build )             compose_build $2;;
    boot )              $HOME/docker/bus_bootstrap.sh;;
    cd )                project_cd $2;;
    env )               machine_env;;
    ip )                machine_check; machine_ip $2;;
    def|default )       machine_set_def $2;;
    ls|list )           machine_check; machine_list $2;;
    n|new|create )      machine_new;;
    on|up|start )       machine_on $2;;
    off|down|stop )     machine_check; machine_off $2;;
    rb|reboot|restart ) machine_check; machine_reboot $2;;
    recert )            machine_check; machine_recert $2;;
    rm|remove )         machine_check; machine_remove $2;;
    ssh )               machine_check; machine_ssh $2;;
    st|status )         machine_check; machine_status $2;;
    uninstall )         bus_remove;;
    up|upgrade )        machine_check; machine_upgrade $2;;
    v|ver|version )     bus_version;;
    *|h|help|\?|man )   bus_help | less -r;;
  esac
} # }}}
bus_help() { # {{{
  # purpose: display BuS hints
  echo -e "$green \bGeneral Troubleshooting: $yellow
    1. try BuS commands in new shell
    2. reboot BuS machine
    3. try docker commands directly
    4. restart terminal application
    5. reboot computer
  $rs"
  echo -e "$green \bBuS Commands: $yellow
    __________________________
    act|active:
      $ bus active [machine]  # set active BuS machine in current shell
      $ bus active            # pick BuS machine to set active
    __________________________
    app:
      $ bus app               # check docker apps for updates
    __________________________
    arc|archive:
      $ bus archive [machine] # remove machine & archive its project folder
      $ bus archive           # pick machine to remove & archive project folder
    __________________________
    build:
      $
    __________________________
    boot:
      $
    __________________________
    cd:
      $ bus cd [project]      # cd to project directory
      $ bus cd                # pick machine to cd to project directory
    __________________________
    env:
      $ bus env               # list BuS state, default active & current active
    __________________________
    h|help|?:
      $ bus help              # list BuS commands
    __________________________
    ip:
      $ bus ip [machine]      # list machine's ip address
      $ bus ip                # list active machine's ip address
      $ bus ip all            # list all machine ip addresses
    __________________________
    def|default:
      $ bus default [machine] # set default active BuS machine
      $ bus default           # pick machine for default active
    __________________________
    ls|list:
      $ bus list              # list BuS machines
    __________________________
    new|create:
      $ bus new [machine]     # create new BuS machine
    __________________________
    on|up|start:
      $ bus on [machine name] # start BuS machine: name
      $ bus on all            # start all BuS machines
      $ bus on                # start BuS active machine
      $ bus on menu           # pick BuS machines to start
    __________________________
    off|down|stop:
      $ bus off [machine]     # stop BuS machine: name
      $ bus off all           # stop all BuS machines
      $ bus off               # stop BuS active machine
      $ bus off menu          # pick BuS machines to stop
    __________________________
    recert:
      $ bus recert [machine]  # issue new TLS certs for BuS machine in parameter
      $ bus recert all        # issue new TLS certs for all BuS machines
      $ bus recert menu       # pick BuS machines to issue new TLS certs for
    __________________________
    rb|reboot|restart:
      $ bus reboot [machine]  # reboot BuS machine in parameter
      $ bus reboot all        # reboot all BuS machines
      $ bus reboot menu       # pick BuS machines to reboot
    __________________________
    rm|remove:
      $ bus remove [machine]  # remove BuS machine
      $ bus remove all        # remove all BuS machine
      $ bus remove            # pick BuS machine to remove
    __________________________
    ssh:
      $ bus ssh [machine]     # ssh into BuS machine (docker host)
      $ bus ssh               # ssh into active BuS machine (docker host)
      $ bus ssh menu          # pick BuS machine to ssh into (docker host)
    __________________________
    st|status:
      $ bus status [machine]  # status of BuS machine in parameter
      $ bus status all        # status of all BuS machines
      $ bus status            # status of BuS active machine
    __________________________
    up|upgrade:
      $ bus upgrade [machine] # upgrade to the latest version of Docker
    __________________________
    uninstall
      $ bus uninstall         # uninstall BuS functions, aliases & machines
    __________________________
    v|ver|version:
      $ bus verion            # display BuS version information $rs"
} # }}}
bus_version() { # {{{
  # purpose: display pre-rendered figlet output
  # only display if screen is wide enough
  if (( $(tput cols) >= 40 )); then
    echo -e "$blue
  ┏━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃      ___      ___     ┃
  ┃     | _ )_  _/ __|    ┃
  ┃     | _ \ || \__ \    ┃
  ┃     |___/\_,_|___/    ┃
  ┃                       ┃
  ┗━ Boxed up Stack: MEAN━┛ $rs"
  fi
  echo -e "$blue\n \bBuS version: $bus_ver $rs"
  echo -e "$blue \bBuS repo: $bus_repo $rs"
} # }}}
bus_remove() { # {{{
  # purpose:
  title="remove all BuS machines, data and apps?"
  # call function: display boolean picker
  picker_boolean
  # do if choice is yes
  if [ $choice == "Yes" ]; then
    # call function: remove all docker machines
    machine_remove all
    # call script: uninstall docker binaries & any prior version backups
    $HOME/docker/bus_app.sh uninstall
  fi
} # }}}

compose_build() { # {{{
  # purpose:
  echo "compose build"
  # prompt to build & present stack menu: choose stack
} # }}}
project_cd() { # {{{
  # cd into project folders
  # do if folder parameter exists
	if [ ! -z "$1" ]; then
    # if no [machine_name] parameter, use active machine paths
    if [ -z "$2" ]; then
      tmp_mach_name=$def_mach
    else
      tmp_mach_name=$2
    fi
    # build path
    p_m=$HOME/docker/projects/$tmp_mach_name

    # parameter conditionals
    if [ "$1" == "b" ]; then
      # goto build folder
      cd $p_m/build
    elif [ "$1" == "d" ]; then
      # goto data folder
      cd $p_m/data
    fi
  else
		echo -e "$red\n \busage: b go [b/d] [machine_name]"
    echo -e "example: $ b go b # goto active machine build folder"
    echo -e "example: $ b go d # goto active machine data folder"
    echo -e "example: $ b go d $mach_name # goto another machine's data folder"
  fi
} # }}}

docker_get_ip() { # {{{
  # return ip address of container; $ dip [containerName]
  docker inspect $1 | grep 'IPAddress"';
} # }}}
docker_go_container() { # {{{
  # get into container via cli; $ dgo [container_name]
  docker exec -it $1 /bin/bash
} # }}}
docker_rm_atomic() { # {{{
  docker kill $(docker ps -q) 2> /dev/null
  docker rm $(docker ps -aq) 2> /dev/null
  docker rmi $(docker images -q) 2> /dev/null
} # }}}
docker_rm_image() { # {{{
  # delete image and affiliated containers; $ drmi [serviceName]
	docker kill $(docker ps -aq --filter="name=$1") 2> /dev/null
	docker rm $(docker ps -aq --filter="name=$1") 2> /dev/null
  docker rmi $(docker images | grep $1) 2> /dev/null
  # docker rm $(docker ps -q -f status=exited) 2> /dev/null;
  # if docker images | grep -q $1; then
    # docker rmi $(docker images | awk -v lvar=$1 '$0~lvar { print $3 }');
    # docker rmi $(docker images | awk '/none/ { print $3 }') 2> /dev/null;
  # fi;
} # }}}
