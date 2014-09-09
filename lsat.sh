#!/bin/bash

#
# Livio SDL Automation Tool
#
# Omg, your here!!  Oh crap... um ya I wasn't really 
# expecting you to look at this... oh crap, um ok ok ok.
# So you can edit the values here, on the top.  But
# I couldn't loop past the STOP.
#
# Oh right, what does this do?  It automates stuff and
# junk to get SDL up and running on a new machine.

# ------------------------------------------------------- #
# User Input Values
# ------------------------------------------------------- #

# You can completely automate the script by filling in 
# these variables.  If you do not, the script will prompt
# you for them.


# Git Credentials
# If the SDL repo requires authentication then you can 
# provide your username and/or password here.  
# Ideally you should store this information in the git 
# global configuration or use ssh.  However, if you don't
# already have that setup this will work.
# -------------------------------------------------------

# Git repo username.
gitUsername=""

# Git repo password
gitPassword=""

# If the repo doesn't require authentication, you should
# change this flag to false.
isGitAuthRequired=false

# If any of the git submodules do not require 
# authentication you should change this flag to false.
isGitSubmoduleAuthRequired=false


# Notification Credentials
# If you wish to be notified of script events, such as 
# SDL build has completed, you can enter your info here.
# -------------------------------------------------------

# Your email address
email=""

# Your phone number, required for text notifications.
phoneNumber=""

# Your phone carrier email to text message address.  
# These can be found at www.emailtextmessages.com
carrierTextEmail=txt.att.net

# This script uses a mail API rather than installing a mail
# server.  Enter your Mandrill App API key.
mailApiKey=JR3GOYuPBPo4sBqFcs4dDQ


# ------------------------------------------------------- #
# Script Configurations
# ------------------------------------------------------- #

# Certain parts of the script are configurable using the 
# following variables.


# Script Flags
# Turn on/off script tasks and configurations.
# -------------------------------------------------------

# If true, installs VMware tools required to display SDL
# GUI at a useable resolution.
# 
# Warning:  This has been giving me some issues, use at 
#           your own risk
isVm=false

# If true, shows the script's log file in a new terminal
# while the script is executing.
showLog=false


# Notifications
# Turn on/off all notifications and specific events.  
# -------------------------------------------------------

# Send all enabled notifications via email
notifyViaEmail=false

# Send all enabled notifications via text message.
notifyViaText=false

# Turn on/off a notification when the script completes.
notifyOnCompletion=true


# Script Configurations
# -------------------------------------------------------

# List of dependencies to install using apt-get for SDL before trying to build.
dependencyList="cmake git g++ cmake gstreamer1.0 gstreamer0.10-ffmpeg automake1.11 bluez-tools libbluetooth3 libbluetooth-dev libpulse-dev libavahi-client-dev chromium-browser liblog4cxx10 liblog4cxx10-dev libudev-dev libxml2-dev"

# Build directory
rootDirectory="$HOME/sdl/"

# Directory to clone SDL core into.
sdlCoreGitDirectory=$rootDirectory"sdl"

# Directory to store SDL builds in.
sdlCoreBuildDirectory=$rootDirectory"sdl_build"

# Log file to store script logs in.
logFile=$rootDirectory"lsat.log"

# Log file to store SDL core logs in.
sdlLogFile=$rootDirectory"sdl.log"


# Git Repository Configurations
# -------------------------------------------------------

# SDL Genivi repository base url and branch
sdlCoreGeniviGitRepo="git.projects.genivi.org/smartdevicelink.git"
sdlCoreGeniviGitRepoBranch="dev/merge_3.5"
sdlCoreGeniviGitProtocol="git://"

# SDL core git repo base url.  Do not include http, ssh, or credentials.
sdlCoreGitRepo=$sdlCoreGeniviGitRepo

# SDL branch to checkout
sdlCoreGitRepoBranch=$sdlCoreGeniviGitRepoBranch

# Git remote protocol 
# Options: http://, https://, git://, or ssh://)
sdlCoreGitProtocol=$sdlCoreGeniviGitProtocol


# Build Configurations
# -------------------------------------------------------

# The SDL build flags to use with cmake.
cmakeBuildFlags="-DEXTENDED_POLICY_FLAG=ON"


# ------------------------------------------------------- #
# STOP -- You Don't Need to Change Anything Below -- STOP
# ------------------------------------------------------- #




# ------------------------------------------------------- #
# Global Variables
# ------------------------------------------------------- #

# Git repo without authentication
repoNoAuth=$sdlCoreGitProtocol$sdlCoreGitRepo

# Flags to indicate which action the user wants to perform.
# These should all initalize to false.
buildSdlFlag=false
installSdlFlag=false
startSdlFlag=false

# Is the script run with root permission
if [[ $UID != 0 ]]; then
  isRunAsRoot=false
else
  isRunAsRoot=true
fi

# User who invoked the script, even if using sudo
user="$SUDO_USER"
if [[ "$user" == "" ]]; then
  user=`whoami`
fi

# The inital working directory this script is started in.
initialDirectory=$PWD

# Has the package manager been updated yet?
isPmUpdated=false

# Tracks whether or not git authentication has been 
# enabled for a submodule.
isGitSubmoduleAuthEnabled=false


# ------------------------------------------------------- #
# Build Code Methods
# ------------------------------------------------------- #

# Remove any existing build(s) and rebuild SDL from source
# into the build directory specified in the configs.
function buildSdl {
  # Remove the old build, if it exists.
  if [ -d $sdlCoreBuildDirectory ]; then
    printJob "Removing old build files"
    echo "Deleting "$sdlCoreBuildDirectory
    rm -rf $sdlCoreBuildDirectory
    printJobDone
  fi

  printJob "Building SDL project files"
  
  # Create and navigate to the build directory.
  echo "Creating build folder "$sdlCoreBuildDirectory
  mkdir -p $sdlCoreBuildDirectory
  cd $sdlCoreBuildDirectory
  
  # Build SDL.
  cmake $cmakeBuildFlags $sdlCoreGitDirectory
  make

  # Set permissions of the build folder for the user 
  # who invoked the script.
  sudo chown -R $user:$user $sdlCoreBuildDirectory

  printJobDone
}


# ------------------------------------------------------- #
# Clear User Data
# ------------------------------------------------------- #

# Remove all users data from the global variables so we 
# don't leak data into the bash terminal.
function clearUserData {
  gitUsername=""
  gitPassword=""
  gitCredentials=""
  email=""
  phoneNumber=""
  carrierTextEmail=""
  mailApiKey=""
}


# ------------------------------------------------------- #
# Dependencies Methods
# ------------------------------------------------------- #

# Install all SDL and script dependencies using apt-get
function handleDependencies {
  # Update package manager's list
  printJob "Updating package manager"
  sudo apt-get update -y --force-yes
  isPmUpdated=true
  printJobDone

  # Handle VMs
  # TODO: Fix this, it is failing and causing errors.
  if $isVm; then
    printJob "Installing vmWare tools"
    sudo apt-get install open-vm-tools -y --force-yes
    printJobDone
  fi

  # Ubuntu 12.04 Specific
  if $isOsVersionPrecise; then
    sudo add-apt-repository ppa:gstreamer-developers/ppa -y
    sudo apt-get update
  fi

  # Install SDL dependencies
  printJob "Installing SDL Dependencies"
  sudo apt-get install -y --force-yes $dependencyList
  printJobDone
}

# ------------------------------------------------------- #
# End Method
# ------------------------------------------------------- #

# Exit the script and display an error message if available.
function end {
  msg=$1

  clearUserData

  if [[ "$msg" != "" ]]; then
    echo "Error:  "$msg
    exit 1
  else
    exit 0
  fi
}


# ------------------------------------------------------- #
# End Method
# ------------------------------------------------------- #

# Print a non-fatal error from within a method.
# Example usage:  function blah { return error "oh crap"; }
function error {
  echo -e "Error: "$1
  return 1
}


# ------------------------------------------------------- #
# Git Methods
# ------------------------------------------------------- #

# Clone or update the SDL code.
function gitCode {
  # Flag to indicate the repo was just cloned or not.
  isCloned=false

  # Clone the repo if it does not exist already.
  if [ ! -d "$sdlCoreGitDirectory" ]; then
    printJob "Cloning git repository"

    # Pull using authentication if needed and available.
    if $isGitAuthRequired && [[ "$repoAuth" != "" ]]; then
      git clone $repoAuth $sdlCoreGitDirectory
    else
      git clone $repoNoAuth $sdlCoreGitDirectory
    fi

    # Indicate the repo was just cloned.
    isCloned=true

    printJobDone
  fi

  # Ensure the clone was successful, otherwise exit.
  if [ ! -d "$sdlCoreGitDirectory" ]; then
    end "SDL repository was not cloned successfully."
  fi

  # Navigate to the repo
  cd $sdlCoreGitDirectory
    
  # Get the current branch name.
  currentBranch=$(git symbolic-ref HEAD)

  # Setup git authentication for the repo, this will be removed later.
  if [[ "$repoAuth" != "" ]]; then
    git config remote.origin.url $repoAuth
  fi
       
  # Update the git repository if it was not just cloned.
  if ! $isCloned; then
    printJob "Updating git repository"   
    git pull
    printJobDone
  fi

  # Checkout the branch, if not already on it.
  if [[  $currentBranch != *$sdlCoreGitRepoBranch ]]; then
    printJob "Checking out the branch"        
    git fetch origin $sdlCoreGitRepoBranch
    git checkout -b $sdlCoreGitRepoBranch origin/$sdlCoreGitRepoBranch
    printJobDone
  fi

  # Add git authentication for the submodules
  enableGitSubmoduleAuth "src/components/policy" 
 
  # Update submodule.
  printJob "Updating the submodules"
  git submodule update
  printJobDone

  # Disable git authentication for the submodules.
  disableGitSubmoduleAuth "src/components/policy"

  # Remove git credentials from the repository.
  git config remote.origin.url $repoNoAuth

  # Set permissions to the user who invoked the script.
  if $isRunAsRoot; then
    sudo chown -R $user:$user $sdlCoreGitDirectory
  fi
 
  # If we pull down new code we may need to run the applink setup script.
  # TODO: Don't run if code hasn't changed.
  runApplinkSetup
}

# Enable authentication for a submodule, if possible.
function enableGitSubmoduleAuth {
  # Check if authentication is not required or already enabled.
  if [ ! $isGitSubmoduleAuthRequired ] || $isGitSubmoduleAuthEnabled; then
    return 0;
  fi  

  # Verify the submodule parameter is valid.
  submodule="$1"
  if [[ "$submodule" == "" ]]; then
    return error "Cannot enable submodule authentication for an invalid submodule"
  fi

  printJob "Enabling submodule auth"

  # Prefix for a git url that includes the user's credentials.
  gitCredentials="https://$gitUsername:$gitPassword@"
  
  # Prefix for a git url that excludes the user's credentials.
  https="https://"
  
  # Pattern to find all urls with or without authentication.
  pattern="https://.*:.*@\|https://"

  # Find all instances of git repository urls and replaces them with urls that include authentication.
  # Then prints the modified .gitmodules file to a temp location.
  sed -e "s,${pattern},$gitCredentials,g" $sdlCoreGitDirectory"/.gitmodules" > $sdlCoreGitDirectory"/.gitmodules_tmp"

  # Overwrite the existing .gitmodules folder with the altered one.  Then remove the temp .gitmodules file.
  cat $sdlCoreGitDirectory"/.gitmodules_tmp" > $sdlCoreGitDirectory"/.gitmodules"
  rm $sdlCoreGitDirectory"/.gitmodules_tmp"

  # Debug Purposes only, print the altered .gitmodules file.
  #echo -e "Updated submodule '"$submodule"' remote urls:\n"
  #cat $sdlCoreGitDirectory"/.gitmodules"
    
  # Navigate to the git directory.
  currentDir=$PWD 
  cd $sdlCoreGitDirectory
  
  # Git Credentials string with username and password hidden for the logs.
  gitCredentialsHidden="https://username:password@"
  
  # Write changes in .gitmodules to .git/config and send the output
  # to the log with the git username and password sanitized.
  syncOutput=$(git submodule sync)
  echo $(sed -e "s,${pattern},$gitCredentialsHidden,g" <<< $syncOutput)
  
  # Reinitialize the submodule and output to the lgo with the git 
  # username and password sanitized.
  initOutput=$(git submodule init)
  echo $(sed -e "s,${pattern},$gitCredentialsHidden,g" <<< $initOutput)
  
  cd $currentDir

  # Mark the submodule as using authentication.
  isGitSubmoduleAuthEnabled=true
  printJobDone
}

# Disable authentication for a submodule, if possible.
function disableGitSubmoduleAuth {
 # Check if authentication is not required or already disabled.
  if [ ! $isGitSubmoduleAuthRequired ] || [ ! $isGitSubmoduleAuthEnabled ]; then
    return 0;
  fi  

  # Verify the submodule parameter is valid.
  submodule="$1"
  if [[ "$submodule" == "" ]]; then
    return error "Cannot disable submodule authentication for an invalid submodule"
  fi

  printJob "Disabling submodule auth"
 

  # Prefix for a git url that includes the user's credentials.
  gitCredentials="https://$gitUsername:$gitPassword@"
  
  # Prefix for a git url that excludes the user's credentials.
  https="https://"
  
  # Pattern to find all urls with or without authentication.
  pattern="https://.*:.*@\|https://"


  # Find all instances of git repository urls and replaces them with urls that exclude authentication.
  # Then prints the modified .gitmodules file to a temp location.
  sed -e "s,${pattern},$https,g" $sdlCoreGitDirectory"/.gitmodules" > $sdlCoreGitDirectory"/.gitmodules_tmp"

  # Overwrite the existing .gitmodules folder with the altered one.  Then remove the temp .gitmodules file.
  cat $sdlCoreGitDirectory"/.gitmodules_tmp" > $sdlCoreGitDirectory"/.gitmodules"
  rm $sdlCoreGitDirectory"/.gitmodules_tmp"
  
  # Debug Purposes only, print the altered .gitmodules file.
  #echo -e "Updated submodule '"$submodule"' remote urls:\n"
  #cat $sdlCoreGitDirectory"/.gitmodules"
    
  # Write changes in .gitmodules to .git/config
  currentDir=$PWD 
  cd $sdlCoreGitDirectory
  git submodule sync
  git submodule init
  cd $currentDir

  # Mark the submodule as using authentication.
  isGitSubmoduleAuthEnabled=false
  printJobDone
}


# ------------------------------------------------------- #
# Help Menu Methods
# ------------------------------------------------------- #

# Print a help menu to the console.
function printHelpMenu {
  echo -e "Livio SDL Automation Tool - A series of automation tools to help work with SDL.\n"
  
  echo -e "usage: \tlsat.sh [options]\n"

  echo -e "options:"
  echo -e "   -b \t build   \t build and run SDL core."
  echo -e "   -d \t debug   \t displays lsat logs while executing."
  echo -e "   -e \t email   \t sends script notifications via email."
  echo -e "   -h \t help    \t displays this help screen."
  echo -e "   -i \t install \t setup enviorment, get code, build, and run SDL core."
  echo -e "   -s \t start   \t just start SDL core, do not rebuild."
  echo -e "   -t \t text    \t sends script notifications via text message."
  echo
}


# ------------------------------------------------------- #
# Logging
# ------------------------------------------------------- #

# Setup a log file and redirect all output to it.
function startLogging {
  # Start time of script automation.
  startDateTime=$(date)

  # Create a new log file with the user permissions.
  if $isRunAsRoot; then
    #TODO: This is a hot fix for missing directory.
    sudo -u $user mkdir -p $rootDirectory
    sudo -u $user echo -e "SDL Setup Script\n" > $logFile
  else
    #TODO: This is a hot fix for missing directory.
    mkdir -p $rootDirectory
    echo -e "SDL Setup Script\n" > $logFile
  fi

  # Log everything to the log file.
  exec 3>&1 1>>${logFile} 2>&1

  # Display start time.
  echo "Script Started: $startDateTime"
  echo -e "*******************************************************\n" 

  # Watch logs in new terminal, if enabled.
  if $showLog ; then
    if $isRunAsRoot; then
      # If root, we need to start the new terminal as a standard user.
      sudo -u $user x-terminal-emulator -e "watch tail -n 20 $logFile"
    else
      x-terminal-emulator -e "watch tail -n 20 $logFile"
    fi
  fi
}


# ------------------------------------------------------- #
# Notify Complete
# ------------------------------------------------------- #

# Notify the user via email, phone, etc upon script completion.
function notifyComplete {
  if $notifyOnCompletion; then
    completeMessage="SDL Build Complete!"
    
    # Make sure curl is installed.
    if $notifyViaEmail || $notifyViaText; then 
      sudo apt-get install -y --force-yes curl
    fi
   
    # Send email
    if $notifyViaEmail; then
        curl -A 'Mandrill-Curl/1.0' -d '{"key":"'$mailApiKey'","message":{"html":"'"$completeMessage"'","from_email":"it@livioconnect.com","to":[{"email":"'$email'", "type":"to"}]}}' 'https://mandrillapp.com/api/1.0/messages/send.json'
    fi

    # Send Text Message
    if $notifyViaText; then
      curl -A 'Mandrill-Curl/1.0' -d '{"key":"'$mailApiKey'","message":{"html":"'"$completeMessage"'","from_email":"it@livioconnect.com","to":[{"email":"'$phoneNumber'@'$carrierTextEmail'", "type":"to"}]}}' 'https://mandrillapp.com/api/1.0/messages/send.json'
    fi
  fi
}


# ---------------------------------------- #
# OS Methods
# ---------------------------------------- #

isOsLinux=false
isOsUbuntu=false
isOsx64=false
isOsx32=false
isOsVersionPrecise=false

function getOsInfo {
  # Check if operating system is Ubuntu.
  if [[ `uname -s` == *"Linux"* ]]; then
    isOsLinux=true
    
    # Check if Linux version is Ubuntu
    if [[ `uname -a` == *"ubuntu"* ]]; then
      isOsUbuntu=true

      # Check if Ubuntu version is 12.04 Precise.
      if [[ `lsb_release -c` == *"precise"* ]]; then
        isOsVersionPrecise=true
      fi
    fi
  fi
}


# ---------------------------------------- #
# Print Methods
# ---------------------------------------- #

# Stores the current task being run.
currentJob=""

# Print to console and file.
function print {
    echo $1 | tee /dev/fd/3
}

# Print to console and file on the same line.
function printSameLine {
    echo -ne $1 | tee /dev/fd/3
}

# Print the start of a task to console and file.
function printJob {
    currentJob=$1
    echo "----------------------------------------"
    echo -e $1"...\n"
    echo -ne $1"..." 1>&3
}

# Print a completion message for the current tasks to console and file.
function printJobDone {
    echo
    echo -e $currentJob"...\t[ DONE ]"
    echo -e "----------------------------------------\n"
    echo -ne "\t[ DONE ]\n" 1>&3
}

# Print to the console.
function printConsole {
  echo $1 1>&3
}


# ------------------------------------------------------- #
# Root Privileges
# ------------------------------------------------------- #

# Ensure we have root permission.
function getRootPrivileges {
  # TODO: Auto login as root by re-running this script as root.
  if [[ $UID != 0 ]]; then
      echo "Please run this script with sudo:"
      echo "sudo $0 $*"
      exit 1
  else
    isRunAsRoot=true
  fi
}

# Cache root permission for the default time, usually 5 min.
function cacheRootPermission {
    # Cache root permission for the script, if not already root.
  if [[ $UID != 0 ]]; then
      sudo echo -ne ""
  fi
}


# ------------------------------------------------------- #
# Setup enviorment
# ------------------------------------------------------- #

# Setup enviorment using applink script.
function runApplinkSetup {
  printJob "Setting up enviorment"
  cd $sdlCoreGitDirectory
  sudo ./setup_env.sh
  printJobDone
}


# ------------------------------------------------------- #
# Start SDL
# ------------------------------------------------------- #

# Start SDL core which will launch the GUI.  Also display
# the output in a new terminal.
function startSdl {
  printJob "Starting SDL Core and GUI"

  # Navigate to the applications directory
  cd $sdlCoreBuildDirectory"/src/appMain/"

  echo "Starting SDL core in new terminal and logging to output to '"$sdlLogFile"'."

  # Start SDL in a new terminal and log the output to a file.
  if $isRunAsRoot; then
    # Create the log file with user's permissions, otherwise we can't access it.
    touch $sdlLogFile
    chown $user:$user $sdlLogFile
    
    # If root, we need to start the new terminal as a standard user.
    sudo -u $user x-terminal-emulator -e "bash -c \" ./smartDeviceLinkCore | tee $sdlLogFile ; exec bash \""
  else
    x-terminal-emulator -e "bash -c \" ./smartDeviceLinkCore | tee $sdlLogFile ; exec bash\""
  fi

  printJobDone
}


# ------------------------------------------------------- #
# User Input Methods
# ------------------------------------------------------- #

# Get the user's git credential, if not already listed.
function getGitCredentials {
  # If authentication is not required, then we don't need 
  # to prompt for it.
  if [ "$isGitAuthRequired" == "false" ]; then
    if [ "$isGitSubmoduleAuthRequired" == "false" ]; then
      repoAuth=$sdlCoreGitProtocol$sdlCoreGitRepo
      return 0
    fi
  fi

  #if [ ! isGitAuthRequired ] && [ ! isGitSubmoduleAuthRequired ]; then
  #  repoAuth="https://"$sdlCoreGitRepo
  #  return 0
  #fi

  # Git Username
  if [[ "$gitUsername" == "" ]]; then
    echo -n "Git username: "
    read gitUsername
  fi

  # Git Password
  if [[ "$gitPassword" == "" ]]; then
    echo -n "Git password: "
    stty_orig=`stty -g`
    stty -echo
    read gitPassword
    stty $stty_orig
    echo
  fi

  # Make sure a username and password were given.
  if [[ "$gitUsername" == "" ]] || [[ "$gitPassword" == "" ]]; then
    echo -e "Error:  Git username and password required.";
    exit
  fi

  # Setup git repo urls using authentication
  repoAuth=https://$gitUsername:$gitPassword@$sdlCoreGitRepo
}

# Get the user's notification information, if not already listed.
function getNotifyInfo {
  if $notifyViaText; then
    # Get the user's phone carrier email.
    if [[ "$carrierTextEmail" == "" ]]; then
      echo -n "Phone Carrier text email: "
      read carrierTextEmail
    fi

    # Get the user's phone number.
    if [[ "$phoneNumber" == "" ]]; then
      echo -n "Phone number: "
      read phoneNumber
    fi
  fi

  # Email address, if needed
  if $notifyViaEmail && [[ "$email" == "" ]]; then
      echo -n "Email: "
      read email
  fi

  # Mandrill API key
  if [[ "$mailApiKey" == "" ]]; then
      echo -n "Mandrill API key: "
      stty_orig=`stty -g`
      stty -echo
      read mailApiKey
      stty $stty_orig
      echo
  fi
}

# ******************************************************* #
# Script Logic
# ******************************************************* #

# Handle command line flags.
for var in "$@"
do
  case "$var" in
    -b | -build | [build])
      buildSdlFlag=true
      ;;
    -d | -debug | [debug])
      showLog=true
      ;;
    -e | -email | [email])
      notifyViaEmail=true
      ;;
    -h | -help | [help])
      printHelpMenu
      clearUserData
      exit
      ;;
    -i | -install | [install])
      installSdlFlag=true
      ;;
    -s | -start | [start])
      startSdlFlag=true
      ;;
    -t | -text | [text])
      notifyViaText=true
      ;;
  esac
done

# Setup enviorment, get code, build, and run SDL.
if $installSdlFlag; then
  getRootPrivileges
  getGitCredentials
  getNotifyInfo
  getOsInfo
  startLogging

  handleDependencies
  gitCode
  buildSdl
  startSdl

  notifyComplete
  clearUserData
  exit
fi

# Build and run the current code base.
if $buildSdlFlag; then
  getRootPrivileges
  getGitCredentials
  getNotifyInfo
  getOsInfo
  startLogging

  buildSdl
  startSdl

  notifyComplete
  clearUserData
  exit
fi

# Start SDL
if $startSdlFlag; then
  startLogging
  startSdl
  clearUserData
  exit
fi

printHelpMenu
clearUserData
exit
