#!/bin/bash

#user_data = <<EOF

echo "================================================== sudo user creation =========================================="
useradd -m pccuser && echo "pccuser:password" | chpasswd
cat /etc/passwd | grep pccuser

#cat <<EOF > /etc/sudoers.d/pccuser-users
#User rules for ssm-user
#pccuser ALL=(ALL) NOPASSWD:ALL

#EOF
touch /etc/sudoers.d/pccuser-users
echo "pccuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/pccuser-users

exec &> >(tee -a /home/pccuser/DASinstall.log)

##################################### CREATING SYSCTL SERVICES #######################################
cat <<EOF > /etc/systemd/system/job-server-v1.20.3.service
[Unit]
Description=Power Curve Job Server
After=network.target

[Service]
Type=simple
ExecStart="/home/pccuser/powercurve/dasservers/Job Server v1.20.3/run.sh"
ExecStop="/home/pccuser/powercurve/dasservers/Job Server v1.20.3/stop.sh"

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/repository-server-v1.20.3.service
[Unit]
Description=Power Curve Repository Server
After=network.target

[Service]
Type=simple
ExecStart="/home/pccuser/powercurve/dasservers/Repository Server v1.20.3/run.sh"
ExecStop="/home/pccuser/powercurve/dasservers/Repository Server v1.20.3/stop.sh"

[Install]
WantedBy=multi-user.target
EOF

chmod 755 /etc/systemd/system/job-server-v1.20.3.service
chmod 755 /etc/systemd/system/repository-server-v1.20.3.service

su - pccuser #switching to sudo user POINTLESS TO DO THIS BECAUSE EVERY SINGLE LINE RUN IS VIA ROOT SINCE USER DATA AWS
echo "current user is" $whoami

##############################################################################

echo "installing java (zulu-jdk11)"
cd /home/pccuser/; wget https://cdn.azul.com/zulu/bin/zulu11.64.19-ca-jdk11.0.19-linux_x64.tar.gz
sudo tar -xvzf zulu11.64.19-ca-jdk11.0.19-linux_x64.tar.gz -C /home/pccuser

#sudo mkdir /usr/java; sudo tar -xvzf zulu11.64.19-ca-jdk11.0.19-linux_x64.tar.gz -C /usr/java
#cd /usr/java/zulu11.64.19-ca-jdk11.0.19-linux_x64/bin; for i in java javac jfr; do path=$(find `pwd`/$i -type f); echo $path; sudo alternatives --install /usr/bin/$i $i $path 20000 ; done
#sudo update-alternatives --config $i

###############################################################################

#sudo cat <<EOF > /etc/profile.d/pccuser.sh

##!/bin/sh

#export PATH="/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64/bin:$PATH"
#export JAVA_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64
#export JRE_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64

#EOF

touch /etc/profile.d/pccuser.sh
echo "#!/bin/sh" > /etc/profile.d/pccuser.sh
echo "export PATH=\"/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64/bin:\$PATH\"" >> /etc/profile.d/pccuser.sh
echo "export JAVA_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64" >> /etc/profile.d/pccuser.sh
echo "export JRE_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64" >> /etc/profile.d/pccuser.sh

cat /etc/profile.d/pccuser.sh

############################
echo "============= installation of DAS ==========="
#############################

sudo aws s3 cp s3://pcc-jobreposerver/setup-design-server-1.20.13-fy23-4-HF02-unix-dist.tar.gz /home/pccuser/
echo "============== checking if tar.gz copied: ls -larth output"
ls -larth
echo "changing ownership for the tar file"
sudo chown pccuser:pccuser /home/pccuser/setup-design-server-1.20.13-fy23-4-HF02-unix-dist.tar.gz
#sudo chmod 755 /home/pccuser/setup-design-server-1.20.13-fy23-4-HF02-unix-dist.tar.gz
ls -larth /home/pccuser/
echo "checking current dir"; pwd
echo "untarring DAS"
sudo tar -xvzf /home/pccuser/setup-design-server-1.20.13-fy23-4-HF02-unix-dist.tar.gz -C /home/pccuser #will give das_linux_installer
echo "check for presence of das linux installer"
ls -larth
#cd /home/pccuser/das_linux_installer
echo "check current dir"; pwd


echo "editing install.properties"
######################################
#vi das_linux_installer/install.properties

#installpath="/opt/powercurve/DecisionAnalyticsServers"
#line26 installpath="/home/pccdas/powercurve/dasservers"
#mkdir -p home/pccuser/powercurve/dasservers
sed -i.bak "s|/opt/powercurve/DecisionAnalyticsServers|powercurve/dasservers|" /home/pccuser/das_linux_installer/install.properties

#pipe is used as the separator and in case SPACE or DOLLAR$ is there then backslash \ is used to escape (consider them as text) them
sed -i "s|/home/\$SUDO_USER/PowerCurve/Decision\ Analytics\ Servers\ v1.20|/home/pccuser/das/profile|" /home/pccuser/das_linux_installer/install.properties

#das_server_trust_store_directory="/home/$SUDO_USER/PowerCurve"
#line65 das_server_trust_store_directory="/home/pccdas/$SUDO_USER/das/truststore"
sed -i "s|/home/\$SUDO_USER/PowerCurve|home/pccuser/das/truststore|" /home/pccuser/das_linux_installer/install.properties

#das_trust_store_password="1qaz!QAZ"
#das_trust_store_password="Sg0Ey$3a6J9f8"
sed -i "s|1qaz\!QAZ|Sg0Ey\$3a6J9f8|" /home/pccuser/das_linux_installer/install.properties

sed -i "s|8095|61000|" /home/pccuser/das_linux_installer/install.properties
sed -i "s|8097|53050|" /home/pccuser/das_linux_installer/install.properties
sed -i "s|8096|61001|" /home/pccuser/das_linux_installer/install.properties
sed -i "s|8098|53051|" /home/pccuser/das_linux_installer/install.properties


echo "========================================== editing install.sh ========================================="
#shall add the string at 16th line...in case already a line is there, it will move down when this is inserted in the file
sed -i.bak '16i JAVA_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64' /home/pccuser/das_linux_installer/install.sh
sed -i '89i echo "$java_version -eq 11 satisfied ======= entering the IF condition under install() block"' /home/pccuser/das_linux_installer/install.sh
sed -i '90i cd /home/pccuser; echo "PWD is"; echo $pwd ; echo "installpath is"; echo $installpath; echo "current user is"; echo $whoami' /home/pccuser/das_linux_installer/install.sh #added vidya's recommendation
sed -i '91i echo "copying install.xml to /home/pccuser"; cp -pvr /home/pccuser/das_linux_installer/install.xml /home/pccuser/; chown root:root /home/pccuser/install.xml' /home/pccuser/das_linux_installer/install.sh #added vidya's recommendation
sed -i '94i echo "$java_version -eq 11 NOT satisfied"' /home/pccuser/das_linux_installer/install.sh


touch /home/pccuser/.vimrc
echo "set nu" > /home/pccuser/.vimrc

echo "================= changing das installer owner"
chown -R pccuser:pccuser /home/pccuser/; ls -larth

#run installer
echo "============================================== run installer ========================================================="
cp -pvr /home/pccuser/das_linux_installer/setup-design-server-1.20.13-fy23-4-HF02-standard.jar /home/pccuser/
cd /home/pccuser/das_linux_installer
echo "current user whoami is"
whoami
echo "PWD is"
pwd
echo "============================== creating /home/pccuser/powercurve/dasservers ================="
mkdir -p /home/pccuser/powercurve/dasservers

sudo ./install.sh


#copy jar to DB drivers
sudo wget https://jdbc.postgresql.org/download/postgresql-42.7.3.jar -P '/home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/dbdrivers'
sudo wget https://jdbc.postgresql.org/download/postgresql-42.7.3.jar -P '/home/pccdas/powercurve/dasservers/Repository\ Server\ v1.20.3/dbdrivers' 


echo "################################################## JOBSERVER EDITS ############################################"
#vi /home/pccuser/powercurve/dasservers/Job\ Server\ v1.20.3/run.sh
#line6 ./apps/pccdas/.bashrc
#line10 JAVA_HOME=/home/pccdas/jdk-11.0.7

cd '/home/pccuser/powercurve/dasservers/Job Server v1.20.3/'
sed -i.bak '6i /home/pccdas/.bashrc' run.sh
sed -i '10i JAVA_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64' run.sh
sed -i.bak 's|/apps/java/zulu11.64.19-ca-jdk11.0.19-linux_x64|/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64|' setenv.sh
sed -i 's/Ddbdrivers\=dbdrivers/& -DEnableEntityCompositionFeature=true -DlightweightPD=true/' setenv.sh

#vi /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/db_management_config.xml

sudo mv -v /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/jsf.properties /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/jsf.properties.bkp
sudo mv -v /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/db_management_config.xml /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/db_management_config.xml.bkp
sudo aws s3 cp s3://pcc-jobreposerver/dbfiles/jsf.properties /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/
sudo aws s3 cp s3://pcc-jobreposerver/dbfiles/db_management_config.xml /home/pccdas/powercurve/dasservers/Job\ Server\ v1.20.3/conf/
#edit "remote-services.properties" also; could not pass hostname for URL

sed -i '74i wrapper.java.additional.107=-DEnableEntityCompositionFeature=true' /home/pccuser/powercurve/dasservers/Job\ Server\ v1.20.3/wrapper/conf/wrapper.conf
sed -i '75i wrapper.java.additional.108=-DlightweightPD=true' /home/pccuser/powercurve/dasservers/Job\ Server\ v1.20.3/wrapper/conf/wrapper.conf

echo "################################################## REPOSERVER EDITS ############################################"
cd '/home/pccuser/powercurve/dasservers/Repository Server v1.20.3/'
sed -i.bak '6i /home/pccdas/.bashrc' run.sh
sed -i '10i JAVA_HOME=/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64' run.sh
sed -i.bak 's|/apps/java/zulu11.64.19-ca-jdk11.0.19-linux_x64|/home/pccuser/zulu11.64.19-ca-jdk11.0.19-linux_x64|' setenv.sh
sed -i 's/Ddbdrivers\=dbdrivers/& -DEnableEntityCompositionFeature=true -DlightweightPD=true/' setenv.sh

cd conf
sudo mv -v audit.properties audit.properties.bkp
sudo mv -v com.experian.eda.repositoryservice.cfg com.experian.eda.repositoryservice.cfg.bkp
sudo mv -v com.experian.eda.securityrepositoryservice.cfg com.experian.eda.securityrepositoryservice.cfg.bkp
sudo aws s3 cp s3://pcc-jobreposerver/dbfiles/audit.properties .
sudo aws s3 cp s3://pcc-jobreposerver/dbfiles/com.experian.eda.repositoryservice.cfg .
sudo aws s3 cp s3://pcc-jobreposerver/dbfiles/com.experian.eda.securityrepositoryservice.cfg .
#edit "server-set.properties" as well and check for correct port details in "org.ops4j.pax.web.cfg"

cd ../wrapper/conf
sed -i '74i wrapper.java.additional.107=-DEnableEntityCompositionFeature=true' wrapper.conf
sed -i '75i wrapper.java.additional.108=-DlightweightPD=true' wrapper.conf


echo "====================================== starting REPOSITORY SERVER ==========================================="
sudo systemctl start repository-server-v1.20.3.service
sudo systemctl enable repository-server-v1.20.3.service

echo "====================================== starting JOB SERVER ==========================================="
sudo systemctl start job-server-v1.20.3.service
sudo systemctl enable job-server-v1.20.3.service
#EOF
