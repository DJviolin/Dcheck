# Dcheck

### Dockerised Domain Checker using Jwhois

## Prerequisites

1. Docker Client
2. Docker-compose
3. Systemd

## Installation

```
$ curl -L https://raw.github.com/DJviolin/Dcheck/master/install-dcheck.sh > $HOME/install-dcheck.sh
$ chmod +x $HOME/install-dcheck.sh
$ cd $HOME
$ ./install-dcheck.sh
$ rm -rf $HOME/install-dcheck.sh
```

## Usage

Build the image:

```
$ docker-compose --file ~/dcheck/repo/docker-compose.yml build
```

Start the Systemd service:

```
$ cd ~/dcheck/repo
$ ./service-start.sh
```

Stop the Systemd service:

```
$ cd ~/dcheck/repo
$ ./service-stop.sh
```

Running Domain Checker:

```
$ cd ~/dcheck/repo
$ ./jwhois
```

Checking Dcheck log:

```
$ docker exec -it repo_dcheck /bin/bash -c 'tail -f /var/log/supervisord/dcheck-stdout.log'
```

Running Crunch Random List generator:

```
$ cd ~/dcheck/repo
$ ./crunch "1 6 0123456789 -o /root/dcheck/files-crunch/000000.txt"
```

Update frequently the jwhois.conf from [here](https://raw.githubusercontent.com/jonasob/jwhois/master/example/jwhois.conf).
