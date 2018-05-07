<h1> <img src="image/logo.png"> DevOps /etc</h1>

### BuS:D8 (Boxed up Stack: Drupal 8) Bootstrap

Deployment project that stands up a local containerized LEMP stack with a matching one on AWS. Also a management tool providing canned AWS, OS and Drupal/Drush commands that can be run locally and remotely. Built with Bash, Docker, Docker Compose, Docker Machine, Nginx, PHP-FPM, MariaDB and Drupal.

## docker aliases ########################################################
```
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
alias drmia='docker rmi $(docker images -q)' # delete all images
alias drmc='docker kill $(docker ps -aq) && docker rm $(docker ps -aq)'
alias dnuke='docker_rm_atomic'             # stop/delete all containers/images
```

## docker-compose aliases ################################################
```
alias dc='docker-compose'                  # docker-compose binary
alias dcup='docker-compose up -d'          # build services & run containers
alias dcb='docker-compose build'		       # (re)build service image [Name]
alias dcr='docker-compose restart'	       # restart all containers
alias dcon='docker-compose start'	         # start container(s) [Name]
alias dcof='docker-compose stop'	         # start all containers
alias dcps='docker-compose ps'	           # list docker-compose services
alias dcl='docker-compose logs'            # list service logs w/ tail -f
 docker-machine aliases ################################################
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
```

## vagrant aliases #######################################################
``` silence & push to bg; ssh to vm
alias vuwaf='gwaf && vagrant rsync-back > /dev/null && vagrant rsync-auto > /dev/null & ssh waf && fg'
rsync host to guest
alias synca='vagrant rsync-auto > /dev/null && fg'
alias syncb='vagrant rsync-back'            # one-shot rsync from guest to host
alias vst='vagrant status'                  # run from vagrant project directory
alias vup='vagrant up'                      # "
alias vpro='vagrant provision'              # "
alias vhal='vagrant halt'                   # "
alias vrel='vagrant reload'                 # "
alias vssh='vagrant ssh'                    # "
alias vkil='vagrant destroy'                # "
alias vsus='vagrant suspend'                # "
alias vres='vagrant resume'                 # "
alias vbls='VBoxManage list runningvms'     # list names of running VBox boxes
alias vbup='vbox_start'                     # manually start vbox
```

**Notes:**
This is an abandoned project that's only here for my personal reference
