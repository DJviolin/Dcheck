#!/bin/bash

# set -e making the commands if they were like &&
set -e

read -e -p "Enter the path to the install dir (or hit enter for default path): " -i "$HOME/dcheck" INSTALL_DIR
echo $INSTALL_DIR

echo -e "\nCreating folder & file structure:"
mkdir -p $INSTALL_DIR/repo $INSTALL_DIR/files
cat /dev/null >> $INSTALL_DIR/files/domains.txt
cat /dev/null >> $INSTALL_DIR/files/available.txt
cat /dev/null >> $INSTALL_DIR/files/registered.txt
chmod -R 0777 $INSTALL_DIR/files
echo -e "\
  $INSTALL_DIR/repo\n\
  $INSTALL_DIR/files\n\
  $INSTALL_DIR/files/domains.txt\n\
  $INSTALL_DIR/files/available.txt\n\
  $INSTALL_DIR/files/registered.txt\n\
Done!"

if test "$(ls -A "$INSTALL_DIR/repo")"; then
  echo -e "\n\"$INSTALL_DIR/repo\" directory is not empty!\nYou have to remove everything from here to continue!\nRemove \"$INSTALL_DIR/repo\" directory (y/n)?"
  read answer
  if echo "$answer" | grep -iq "^y" ;then
    rm -rf $INSTALL_DIR/repo/
    echo -e "\"$INSTALL_DIR/repo\" is removed, continue installation...";
    mkdir -p $INSTALL_DIR/repo
    echo -e "\nCloning git repo into \"$INSTALL_DIR/repo\":"
    cd $INSTALL_DIR/repo
    git clone https://github.com/DJviolin/Dcheck.git $INSTALL_DIR/repo
    chmod +x $INSTALL_DIR/repo/service-start.sh $INSTALL_DIR/repo/service-stop.sh
    echo -e "\nShowing working directory..."
    ls -al $INSTALL_DIR/repo
  else
    echo -e "\nScript aborted to run\nExiting..."; exit 1;
  fi
else
  echo -e "\nCloning git repo into \"$INSTALL_DIR/repo\":"
  cd $INSTALL_DIR/repo
  git clone https://github.com/DJviolin/Dcheck.git $INSTALL_DIR/repo
  chmod +x $INSTALL_DIR/repo/service-start.sh $INSTALL_DIR/repo/service-stop.sh
  echo -e "Showing working directory..."
  ls -al $INSTALL_DIR/repo
fi

echo -e "\nUpdating jwhois.conf from https://raw.githubusercontent.com/jonasob/jwhois/master/example/jwhois.conf:"
curl -L https://raw.githubusercontent.com/jonasob/jwhois/master/example/jwhois.conf > $INSTALL_DIR/repo/jwhois.conf

echo -e "\nCreating additional files for the stack:"

# bash variables in Here-Doc, don't use 'EOF'
# http://stackoverflow.com/questions/4937792/using-variables-inside-a-bash-heredoc
# http://stackoverflow.com/questions/17578073/ssh-and-environment-variables-remote-and-local

echo -e "\nCreating: $INSTALL_DIR/repo/docker-compose.yml\n"
cat <<EOF > $INSTALL_DIR/repo/docker-compose.yml
dcheck:
  build: .
  container_name: repo_dcheck
  volumes:
    - $INSTALL_DIR/repo/etc/supervisor/conf.d/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf:ro
    - $HOME/dcheck:/root/dcheck/:rw
EOF
cat $INSTALL_DIR/repo/docker-compose.yml
chmod +x $INSTALL_DIR/repo/docker-compose.yml

# Systemd escaping:
## http://www.freedesktop.org/software/systemd/man/systemd.service.html#Command%20lines

echo -e "\nCreating: $INSTALL_DIR/repo/dcheck.service\n"
cat <<EOF > $INSTALL_DIR/repo/dcheck.service
[Unit]
Description=dcheck
After=etcd.service
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/opt/bin/docker-compose --file $INSTALL_DIR/repo/docker-compose.yml kill
ExecStartPre=-/opt/bin/docker-compose --file $INSTALL_DIR/repo/docker-compose.yml rm --force
ExecStart=/opt/bin/docker-compose --file $INSTALL_DIR/repo/docker-compose.yml up --force-recreate
ExecStartPost=/usr/bin/etcdctl set /dcheck Running
ExecStop=/opt/bin/docker-compose --file $INSTALL_DIR/repo/docker-compose.yml stop
ExecStopPost=/usr/bin/etcdctl rm /dcheck
Restart=always

[X-Fleet]
Conflicts=dcheck.service
EOF
cat $INSTALL_DIR/repo/dcheck.service

echo -e "\nCreating: $INSTALL_DIR/repo/crunch\n"
cat <<EOF > $INSTALL_DIR/repo/crunch
#!/bin/bash

docker run --rm -it -v $INSTALL_DIR:/root/dcheck/:rw repo_dcheck "echo pid1 > /dev/null && crunch \$@"
EOF
cat $INSTALL_DIR/repo/crunch
chmod +x $INSTALL_DIR/repo/crunch

echo -e "\nCreating: $INSTALL_DIR/repo/jwhois\n"
cat <<EOF > $INSTALL_DIR/repo/jwhois
#!/bin/bash

docker run --rm -it -v $INSTALL_DIR:/root/dcheck/:rw repo_dcheck "echo pid1 > /dev/null && chmod +x /root/dcheck/repo/dcheck.sh && cd /root/dcheck/repo && ./dcheck.sh"
EOF
cat $INSTALL_DIR/repo/jwhois
chmod +x $INSTALL_DIR/repo/jwhois

echo -e "\nCreating: $INSTALL_DIR/repo/dcheck.sh\n"
cat <<EOF > $INSTALL_DIR/repo/dcheck.sh
#!/bin/bash

REGISTERED=\$HOME/dcheck/files/registered.txt
AVAILABLE=\$HOME/dcheck/files/available.txt
DOMAINS=\$HOME/dcheck/files/domains.txt
GREPINPUT=\$HOME/dcheck/files/grepinput.txt
DOMAINSDIFF=\$HOME/dcheck/files/domainsdiff.txt
TLD='.com'

cat /dev/null >> \$GREPINPUT \\
&& cat /dev/null >> \$DOMAINSDIFF \\
&& grep -oPa --no-filename '^.*(?=(\.com))' \$AVAILABLE \$REGISTERED > \$GREPINPUT \\
&& grep -Fxvf \$GREPINPUT \$DOMAINS > \$DOMAINSDIFF \\
&& cat \$DOMAINSDIFF > \$DOMAINS \\
&& rm -rf \$GREPINPUT \$DOMAINSDIFF

#awk 'FNR==NR { a[\$0]; next } !(\$0 in a)' \$GREPINPUT \$DOMAINS > \$DOMAINSDIFF

while read -r domain; do
  MATCH=\$(jwhois --force-lookup --disable-cache --no-redirect -c jwhois.conf "\$domain\$TLD" | grep -oPa '^.*\b(Transferred Date|Updated Date|Creation Date|Registration Date|Expiration Date|Expiry Date)\b.*\$')
  if [ \$? -eq 0 ]; then
    echo -e "\$domain\$TLD\tregistered\t"\$(date +%y/%m/%d_%H:%M:%S)"\t\$MATCH" | tr '\n' '\t' |& tee --append \$REGISTERED
    echo "" |& tee --append \$REGISTERED
  else
    echo "\$domain\$TLD" |& tee --append \$AVAILABLE
  fi
done < \$DOMAINS
EOF
cat $INSTALL_DIR/repo/dcheck.sh
chmod +x $INSTALL_DIR/repo/dcheck.sh

cd $HOME

echo -e "\n
Dcheck has successfully built!\n\n\
Run docker-compose with:\n\
  $ docker-compose --file $INSTALL_DIR/repo/docker-compose.yml build\n\
Run the systemd service with:\n\
  $ cd $INSTALL_DIR/repo && ./service-start.sh\n\
Stop the systemd service with:\n\
  $ cd $INSTALL_DIR/repo && ./service-stop.sh"
echo -e "\nAll done! Exiting..."
