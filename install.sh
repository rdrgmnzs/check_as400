#!/bin/bash
#NAGIOS_PATH=/usr/local/nagios
#NAGIOS_USER=nagios
#NAGIOS_GROUP=nagios

echo "Nagios/Icinga AS400 Plugin Installation Script"
echo

#DON'T MODIFY PAST THIS POINT
#-------------------------------------
#
#Lets define some functions we will need.
#

READ_NAGIOS_OR_ICINGA(){
  echo -n "Are you using nagios or icinga? :"
  read NAGIOS_OR_ICINGA
}

READ_CONFIG_PATH(){
  echo -n "Please type the full path to the nagios/icinga config file (ex. /usr/nagios/nagios.cfg or /etc/icinga/icinga.cfg): "
  read CONFIG_PATH
  if [ ! -f $CONFI_PATH ];
  then
    echo "That path does not seem to exist!"
    READ_CONFIG_PATH
  fi
}

READ_PLUGINS_PATH(){
  echo -n "Please type the full path to the nagios plugin directory (ex. /usr/nagios/plugins or /usr/lib64/nagios/plugins): "
  read PLUGINS_PATH
  if [ ! -d $PLUGINS_PATH ];
  then
    echo "That path does not seem to exist!"
    READ_PLUGINS_PATH
  fi
}

READ_JAVA_PATH(){
  echo -n "Please type the full path to your java executable (ex. /usr/bin/java): "
  read JAVA_PATH
  if [ ! -x $JAVA_PATH ];
  then
    echo "That does not seem to exist or be executable!"
    READ_JAVA_PATH
  fi
}

DETECT_OWNER_AND_GROUP(){
  echo
  if [ -e $CONFIG_PATH ];
  then
    if [ "$NAGIOS_OR_ICINGA" == 'nagios' ];
    then
      USER=`cat $CONFIG_PATH |grep -e nagios_user | cut -d= -f2`
      GROUP=`cat $CONFIG_PATH |grep -e nagios_group | cut -d= -f2`
    elif [ "$NAGIOS_OR_ICINGA" == 'icinga' ];
    then
      USER=`cat $CONFIG_PATH |grep -e icinga_user | cut -d= -f2`
      GROUP=`cat $CONFIG_PATH |grep -e icinga_group | cut -d= -f2`
    fi
    if [ $USER ];
    then
      if [ $GROUP ];
      then
        echo "Detected $NAGIOS_OR_ICINGA user as '$USER' and the group as '$GROUP'..."
      else
        echo
        echo "ERROR: Unable to detect your NAGIOS_OR_ICINGA user and group. "
        echo "Is your $CONFIG_PATH properly setup?"
        exit 1
      fi
    else
      echo
      echo "ERROR: Unable to detect your NAGIOS_OR_ICINGA user and group. "
      echo "Is your $CONFIG_PATH properly setup?"
      exit 1
    fi
  else
    echo
    echo "ERROR: Your $CONFIG_PATH file does not seem to exist!"
    exit 1
  fi
}

READ_NAGIOS_OR_ICINGA
READ_CONFIG_PATH
READ_PLUGINS_PATH
READ_JAVA_PATH
DETECT_OWNER_AND_GROUP


echo "Generating check_as400 script based on your paths..."
echo "USER=\`cat $PLUGINS_PATH/.as400 |grep -e USER | cut -d = -f 2\`" >check_as400
echo "PASS=\`cat $PLUGINS_PATH/.as400 |grep -e PASS | cut -d = -f 2\`" >>check_as400
echo "$JAVA_PATH -cp $PLUGINS_PATH check_as400 -u \$USER -p \$PASS \$*" >>check_as400
chmod 744 check_as400

echo "Installing java classes..."
cp *.class $PLUGINS_PATH
echo "Installing check script..."
cp check_as400 $PLUGINS_PATH
if [ ! -e $PLUGINS_PATH/.as400 ] ;
then
  echo "Installing .as400 security file..."
  cp example/example.as400 $PLUGINS_PATH/.as400
  chmod 700 $PLUGINS_PATH/.as400
fi

echo "Setting permissions..."
cd $PLUGINS_PATH
chown $USER:$GROUP check_as400.class check_as400_cmd_vars.class check_as400_lang.class check_as400 .as400
RESULT=$?
if [ $RESULT -eq 1 ];
then
  echo 
  echo "ERROR: Unable to set permissions on the files in $PLUGINS_PATH!"
  echo "Check to make sure they have proper owner and group permissions "
  echo "before using the plugin!"
fi

echo
echo "Install Complete!"
echo
echo " !!!!! Be sure and modify your $PLUGINS_PATH/.as400 "
echo " !!!!! with the correct user and password.        "
echo
echo "Also add the contents of the checkcommands.example file"
echo "into your checkcommands.cfg"
echo

