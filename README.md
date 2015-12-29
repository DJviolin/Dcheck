# Dcheck

### Dockerised Domain Checker using Jwhois

## Prerequisites

1. Docker Client
2. Docker-compose
3. Systemd

## Installation

```
$ curl -L https://raw.github.com/DJviolin/Dcheck/master/install.sh > $HOME/install-dcheck.sh
$ chmod +x $HOME/install-dcheck.sh
$ cd $HOME
$ ./install-dcheck.sh
$ rm -rf $HOME/install-dcheck.sh
```

## Usage

Build the image:

```
$ docker build --rm -t dcheck $HOME/dcheck/repo
```

Start the Systemd service:

```
$ chmod +x ~/dcheck/repo/service-start.sh ~/dcheck/repo/service-stop.sh
$ cd ~/dcheck/repo
$ ./service-start.sh
```

Running Domain Checker:

```
$ chmod +x ~/dcheck/jwhois
$ cd ~/dcheck
$ ./jwhois
```

Running Crunch Random List generator:

```
$ chmod +x ~/dcheck/crunch
$ cd ~/dcheck
$ ./crunch "1 6 0123456789 -o /root/dcheck/files-crunch/000000.txt"
```

Testing container:

```
$ docker run --rm -it --name dcheck -v $HOME/dcheck:/root/dcheck/:rw dcheck
```

Update frequently the jwhois.conf from [here](https://raw.githubusercontent.com/jonasob/jwhois/master/example/jwhois.conf).
