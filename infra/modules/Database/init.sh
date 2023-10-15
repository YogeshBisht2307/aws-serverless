#!/bin/bash
sleep 60
apt-get -y update
apt-get -y install xfsprogs
EBS_VOLUME_ID=$(echo ${EBSVolumeID} | sed "s/-//")
VOLUME_NAME=$(lsblk | grep disk | awk '{print $1}' | while read disk; do echo -n "$disk " && lsblk --nodeps -no serial /dev/$disk; done | grep $EBS_VOLUME_ID | awk '{print $1}')
echo "VOLUME_NAME - $VOLUME_NAME"

MOUNT_POINT=$(lsblk -o MOUNTPOINT -nr /dev/$VOLUME_NAME)
if [[ -z "$MOUNT_POINT" ]]
then
    MOUNT_POINT=/data
    mkfs -t xfs /dev/$VOLUME_NAME
    mkdir $MOUNT_POINT
    mount /dev/$VOLUME_NAME $MOUNT_POINT

    cp /etc/fstab /etc/fstab.orig
    VOLUME_ID=$(lsblk -o UUID -nr /dev/$VOLUME_NAME)

    if [[ ! -z $VOLUME_ID ]]
    then
    tee -a /etc/fstab <<EOF
    UUID=$VOLUME_ID  $MOUNT_POINT  xfs  defaults,nofail  0  2
EOF
    fi
fi

tee /var/lib/cloud/scripts/per-boot/script.sh <<EOF
#!/bin/bash
EBS_VOLUME_ID=\$(echo '${EBSVolumeID}' | sed "s/-//")
VOLUME_NAME=\$(lsblk | grep disk | awk '{print \$1}' | while read disk; do echo -n "\$disk " && lsblk --nodeps -no serial /dev/\$disk; done | grep \$EBS_VOLUME_ID | awk '{print \$1}')
echo "VOLUME_NAME - \$VOLUME_NAME"

MOUNT_POINT="\$(lsblk -o MOUNTPOINT -nr /dev/\$VOLUME_NAME)"
echo "MOUNT_POINT - \$MOUNT_POINT"

if [[ -z \$MOUNT_POINT ]]
then
    MOUNT_POINT=/data
    mkdir -p /var/log/startup-script
    FILE_NAME=/var/log/startup-script/ebs-mount-state-\$(date +%Y-%m-%dT%H:%M).txt
    PRIVATE_IP=\$(hostname -I | awk '{print \$1}')
    tee -a \$FILE_NAME <<ENDFILE
    ERROR: EBS Volumn /dev/\$VOLUME_NAME is not mounted to EC2 Instance '\$PRIVATE_IP'
ENDFILE

    FILE_SYSTEM=\$(lsblk -o FSTYPE -nr /dev/\$VOLUME_NAME)
    echo "FILE_SYSTEM - \$FILE_SYSTEM"

    if [[ \$FILE_SYSTEM != 'xfs' ]]
    then
        mkfs -t xfs /dev/\$VOLUME_NAME
    fi

    mkdir -p \$MOUNT_POINT
    mount /dev/\$VOLUME_NAME \$MOUNT_POINT

    cp /etc/fstab /etc/fstab.orig
    VOLUME_ID=\$(lsblk -o UUID -nr /dev/\$VOLUME_NAME)
    echo "VOLUME_ID - \$VOLUME_ID"

    # Make a entry in fstab file so that every time system restart, ebs will remain mounted to the mount point.
    # - UUID(Unique id of EBS Volume)
    # - MountPoint
    # - FileSystem
    # - default (Keep other configuration as default, such as read write permission)
    # - nofail (Do not report errors for this device if it does not exist)
    # - 0(Prevent file system from being dumpped)
    # - 2 (To indicate a non-root volume)

    if [[ ! -z \$VOLUME_ID ]]
    then
        tee -a /etc/fstab <<FSTAP_EOF
        UUID=\$VOLUME_ID  \$MOUNT_POINT  xfs  defaults,nofail  0  2
FSTAP_EOF
    fi
else
    echo "EBS Volume (\$VOLUME_NAME) is already mounted at \$MOUNT_POINT"
fi


POSTGRESQL_STATUS=\$(systemctl is-active postgresql)
echo "PSQL status \$POSTGRESQL_STATUS"

if [[ \$POSTGRESQL_STATUS != 'active' ]]
then
    IS_POSTGRESQL_INSTALLED=\$(dpkg-query -l | grep -E "\bpostgresql-14(\s|$)" | wc -l)
    echo "IS_POSTGRESQL_INSTALLED - \$IS_POSTGRESQL_INSTALLED"

    if [[ \$IS_POSTGRESQL_INSTALLED == 0 ]]
    then
        apt-get -y install gnupg2 wget
        sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt \$(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sh -c "gpg --dearmor > /etc/apt/trusted.gpg.d/postgresqldb.gpg"

        apt-get -y update
        apt-get -y install postgresql-14
        systemctl restart postgresql

        pg_createcluster -u postgres -d \$MOUNT_POINT/postgresql/postgresql-14/primary 14 primary

        PRIVATE_IP=\$(hostname -I | awk '{print \$1}')
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses='\$PRIVATE_IP'/g" /etc/postgresql/14/primary/postgresql.conf
        sed -i "s/max_connections = 100/max_connections=9999/g" /etc/postgresql/14/primary/postgresql.conf

        tee -a /etc/postgresql/14/primary/pg_hba.conf <<PGHBA_EOF
        host          all          all          ${VpcCIDR}     md5
PGHBA_EOF

        systemctl enable postgresql
        pg_ctlcluster 14 primary start
        systemctl restart postgresql

        sudo -u postgres psql -p ${DatabasePort} -c "CREATE DATABASE ${DatabaseName};"
        sudo -u postgres psql -p ${DatabasePort} -c "CREATE USER ${DatabaseUser} WITH CREATEROLE CREATEDB SUPERUSER REPLICATION PASSWORD '${DatabasePassword}';"
        sudo -u postgres psql -p ${DatabasePort} -d ${DatabaseName}  -c "ALTER USER postgres PASSWORD '${DatabasePassword}';"

        pg_ctlcluster 14 main stop
    else
        systemctl enable postgresql
        pg_ctlcluster 14 primary start
        systemctl restart postgresql
    fi
fi

PRIMARY_CLUSTER_STATUS=\$(pg_ctlcluster 14 primary status)
echo "PRIMARY_CLUSTER_STATUS- \$PRIMARY_CLUSTER_STATUS"

if [[ \$PRIMARY_CLUSTER_STATUS != *"server is running"* ]]; then
    pg_ctlcluster 14 primary start
fi

PRIMARY_CLUSTER_STATUS=\$(pg_ctlcluster 14 primary status)
echo "PRIMARY_CLUSTER_STATUS- \$PRIMARY_CLUSTER_STATUS"

if [[ \$PRIMARY_CLUSTER_STATUS != *"server is running"* ]]; then
    mkdir -p /var/log/startup-script
    FILE_NAME=/var/log/startup-script/ebs-mount-state-\$(date +%Y-%m-%dT%H:%M).txt
    tee -a \$FILE_NAME <<ENDFILE
    ERROR: Postgresql Primary Cluster is not Running
ENDFILE
fi

EOF

chmod 0755 /var/lib/cloud/scripts/per-boot/script.sh

MOUNT_POINT=$(lsblk -o MOUNTPOINT -nr /dev/$VOLUME_NAME)
echo "MOUNT_POINT - $MOUNT_POINT"

if [[ ! -z "$MOUNT_POINT" ]]
then
    apt-get -y install gnupg2 wget
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sh -c "gpg --dearmor > /etc/apt/trusted.gpg.d/postgresqldb.gpg"

    apt-get -y update
    apt-get -y install postgresql-14
    systemctl restart postgresql

    pg_createcluster -u postgres -d $MOUNT_POINT/postgresql/postgresql-14/primary 14 primary

    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses='$PRIVATE_IP'/g" /etc/postgresql/14/primary/postgresql.conf

    sed -i "s/max_connections = 100/max_connections=9999/g" /etc/postgresql/14/primary/postgresql.conf

    tee -a /etc/postgresql/14/primary/pg_hba.conf <<EOF 
    host          all          all          ${VpcCIDR}     md5
EOF

    systemctl enable postgresql
    pg_ctlcluster 14 primary start
    systemctl restart postgresql

    sudo -u postgres psql -p ${DatabasePort} -c "CREATE DATABASE ${DatabaseName};"
    sudo -u postgres psql -p ${DatabasePort} -c "CREATE USER ${DatabaseUser} WITH CREATEROLE CREATEDB SUPERUSER REPLICATION PASSWORD '${DatabasePassword}';"
    sudo -u postgres psql -p ${DatabasePort} -d ${DatabaseName}  -c "ALTER USER postgres PASSWORD '${DatabasePassword}';"
    
    pg_ctlcluster 14 main stop
fi