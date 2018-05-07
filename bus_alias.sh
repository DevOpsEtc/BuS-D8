  ###############################################
  ##  filename: bus_alias                      ##
  ##  path:     ~/src/deploy/localhost/docker/                         ##
  ##  purpose:  BuS aliases                    ##
  ##  date:     12/21/2015                     ##
  ##  repo:     https://github.com/DevOpsEtc  ##
  ###############################################

# vim: set fdm=marker:                       # treat triple braces as folds
# docker-machine regenerate-certs [machine name]

# misc aliases {{{
alias b='bus'                                # call bus function
alias bgo='cd ~/bus; ls -ahF'                # goto BuS folder
alias gitc='git -C $p_m/data'                # run git using machine data repo
alias pgo='project_go'                       # goto project folder [mach_name]
alias vbls='VBoxManage list runningvms'      # list names of running VBox boxes
alias vbup='vbox_start'                      # manually start vbox
# }}}
# docker aliases {{{
alias d='docker'                           # docker binary
alias dx='docker exec -it'                 # run command on container [name]
alias dl='docker logs'                     # list container log [name] [-f]
alias dps='docker ps'                      # list containers (running)
alias dpsa='docker ps -a | grep Exited'    # list containers (exited)
alias dpsq='docker ps -q' 				         # list container IDs (running)
alias dpsaq='docker ps -aq'                # list container IDs (all)
alias drel='docker_releases.sh'            # download latest docker releases
alias dst='docker stats $(docker ps -q)'   # container memory/cpu usage
alias dip='docker_get_ip'                  # list container IP [name]
alias dgo='docker_go_container'            # open container cli
alias din='docker inspect'                 # list container/image info [name]
alias dim='docker images'                  # list images
alias drmi='docker_rm_image'               # delete image [name]
# alias drmia='docker rmi $(docker images -q)' # delete all images
alias drmc='docker kill $(docker ps -aq) && docker rm $(docker ps -aq)'
alias dnuke='docker_rm_atomic'             # stop/delete all containers/images
# }}}
# docker-compose aliases {{{
alias dc='docker-compose'                  # docker-compose binary
alias dcup='docker-compose up -d'          # build services & run containers
alias dcb='docker-compose build'		       # (re)build service image [Name]
alias dcr='docker-compose restart'	       # restart all containers
alias dcon='docker-compose start'	         # start container(s) [Name]
alias dcof='docker-compose stop'	         # start all containers
alias dcps='docker-compose ps'	           # list docker-compose services
alias dcl='docker-compose logs'            # list service logs w/ tail -f
# }}}
# docker-machine aliases {{{
alias dm='docker-machine'                  # docker-machine binary
alias dma='docker-machine active'          # list machines (active)
alias dmas='machine_set_active'            # set active machine; opt [mach_name]
alias dmgo='machine_go'                    # ssh into machine; opt [mach_name]
alias dmip='machine_get_ip'                # get machine ip; opt [mach_name]
alias dmls='docker-machine ls'			       # list machines (all)
alias dmrm='docker-machine rm'             # remove machine; opt [mach_name]
alias dmr='machine_restart'                # restart machine; opt [mach_name]
alias dmon='machine_start'                 # restart machine; opt [mach_name]
alias dmof='machine_stop'                  # restart machine; opt [mach_name]
# }}}
# drush aliases {{{
alias dxd='docker exec -it tool drush'     # run drush on waf.dev
alias dxd-c='dxd cache-rebuild'            # clear all drupal 8 caches
# open one-time login link for specified user; uid 1=default
alias dxd-l="dxd user-login | pbcopy && open $(pbpaste)"
alias dxd-m='drupal_maintenance && dxd-c'  # toggle maintenance mode on/off
# }}}
