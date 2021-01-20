#!/bin/bash
# 
. /lib/lsb/init-functions

daemonname="deskpi"
tempmonscript=/usr/bin/pmwFanControl
deskpidaemon=/lib/systemd/system/$daemonname.service
safeshutdaemon=/lib/systemd/system/$daemonname-safeshut.service
installationfolder=/home/$USER/deskpi

# install wiringPi library.
log_action_msg "DeskPi Fan control script installation Start." 

# Create service file on system.
if [ -e $deskpidaemon ]; then
	sudo rm -f $deskpidaemon
fi

# adding dtoverlay to enable dwc2 on host mode.
sudo sed -i '/dtoverlay=dwc2*/d' /boot/firmware/config.txt 
sudo sed -i '$a\dtoverlay=dwc2,dr_mode=host' /boot/firmware/config.txt 

# install PWM fan control daemon.
log_action_msg "DeskPi main control service loaded."
cd $installationfolder/drivers/c/ 
sudo cp -rf $installationfolder/drivers/c/pwmFanControl /usr/bin/pwmFanControl
sudo cp -rf $installationfolder/drivers/c/fanStop  /usr/bin/fanStop
sudo cp -rf $installationfolder/deskpi-config  /usr/bin/deskpi-config
sudo cp -rf $installationfolder/Deskpi-uninstall  /usr/bin/Deskpi-uninstall
sudo chmod 755 /usr/bin/pwmFanControl
sudo chmod 755 /usr/bin/fanStop
sudo chmod 755 /usr/bin/deskpi-config
sudo chmod 755 /usr/bin/Deskpi-uninstall

# Build Fan Daemon
sudo echo "[Unit]" > $deskpidaemon
sudo echo "Description=DeskPi PWM Control Fan Service" >> $deskpidaemon
sudo echo "After=multi-user.target" >> $deskpidaemon
sudo echo "[Service]" >> $deskpidaemon
sudo echo "Type=oneshot" >> $deskpidaemon
sudo echo "RemainAfterExit=true" >> $deskpidaemon
sudo echo "ExecStart=sudo /usr/bin/pwmFanControl &" >> $deskpidaemon
sudo echo "[Install]" >> $deskpidaemon
sudo echo "WantedBy=multi-user.target" >> $deskpidaemon

# send signal to MCU before system shuting down.
sudo echo "[Unit]" > $safeshutdaemon
sudo echo "Description=DeskPi Safeshutdown Service" >> $safeshutdaemon
sudo echo "Conflicts=reboot.target" >> $safeshutdaemon
sudo echo "Before=halt.target shutdown.target poweroff.target" >> $safeshutdaemon
sudo echo "DefaultDependencies=no" >> $safeshutdaemon
sudo echo "[Service]" >> $safeshutdaemon
sudo echo "Type=oneshot" >> $safeshutdaemon
sudo echo "ExecStart=/usr/bin/sudo /usr/bin/fanStop" >> $safeshutdaemon
sudo echo "RemainAfterExit=yes" >> $safeshutdaemon
sudo echo "[Install]" >> $safeshutdaemon
sudo echo "WantedBy=halt.target shutdown.target poweroff.target" >> $safeshutdaemon

log_action_msg "DeskPi Service configuration finished." 
sudo chown root:root $safeshutdaemon
sudo chmod 755 $safeshutdaemon

sudo chown root:root $deskpidaemon
sudo chmod 755 $deskpidaemon

log_action_msg "DeskPi Service Load module." 
sudo systemctl daemon-reload
sudo systemctl enable $daemonname.service
sudo systemctl start $daemonname.service &
sudo systemctl enable $daemonname-safeshut.service

# Finished 
log_success_msg "DeskPi PWM Fan Control and Safeshut Service installed successfully." 
# greetings and require rebooting system to take effect.
log_action_msg "System will reboot in 5 seconds to take effect." 
sudo sync
sleep 5 
sudo reboot
