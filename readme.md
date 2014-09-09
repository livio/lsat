# Livio SDL Automation Tool

This script automates the process of setting up an SDL head unit emulator on a Linux computer by building SDL from source, and running SDL.  Other automated tasks may be added in the future.

## Supported Operating System
This script will only work on Linux Ubuntu, for other operating systems you are stuck installing SDL manually.  I recommend using 12.04, the script may work on other versions, but it has not been tested yet.

# Usage
![Help Screen](http://i.imgur.com/b2g6FVn.png?1)

## Install Emulator
To install just run the script with the install flag.  This will install dependancies, configure your machine, build SDL from source, and then run SDL.

    ./lsat.sh -i
	
Installation can take a long long time. So why not have the script notify you by email when it is finished.

    ./lsat.sh -i -e
	
## Rebuild the current code
If you just want to build the current code base without pulling down updates from the remote repository then you can use the build flag.  This will build and start SDL.

    ./lsat.sh -b
	
## Start SDL
If you just want to start the current SDL build, use the start flag.

    ./lsat.sh -s
	
# Debug
If you want to see the script's output, or simply don't trust that the script is actually still doing things, then you can add the debug flag -d.  In debug mode the script shows the output of the script in a new terminal window.
    
    ./last.sh -d
    
# Customization
You can easily customize the script by editing the variables found at the top of the lsat file.  These options include your git repo username/password, notificaitons settings, logging, etc.

## Git
You can change the git repo and branch the script will pull from, as well as how git authenticates.

### Repository
Change the git repository by editing the *sdlCoreGitRepo* variable.  This variable only stores the base url, excluding authentication and protocol.

    sdlCoreGitRepo="git.projects.genivi.org/smartdevicelink.git"

### Protocol
If you want to use a different protocol, such as ssh instead of https, you need to modify the *sdlCoreGitProtocol* variable.
    
    sdlCoreGitProtocol="git://"

### Branch    
Change the repository branch using the *sdlCoreGitRepoBranch* variable.

    sdlCoreGitRepoBranch="master"
    
### Authentication 
If the git repository and submodule do not require a username and password, then you should disable the *isGitAuthRequired* and/or *isGitSubmoduleAuthRequired* flag(s).

    isGitAuthRequired=false
    isGitSubmoduleAuthRequired=false

As long as either the git repository and/or submodule(s) require authentication then the script will prompt you to enter your credentials. The script will only ask if the script command issued requires git authentication, such as when cloning or updating the repository.  The git credentials prompt will occur once at the start of the script.  If you do not want this prompt to appear, you can fill out the git credential variables *gitUsername* and *gitPassword* in the script configuration portion.
  
    gitUsername="SpaceBalls"
    gitPassword="12345"
    
If only a username is required, leave the password field blank.  However if you still want the script to prompt for a git repository password, then you can enable the *promptForPassword* variable.

    promptForPassword=true

# Notifications
The script can send you event notifications so you don't have to sit and watch it.  It can send you an email and/or a text message by adding the -e or -t flags respectively.  Here is an example of sending both text and email notificaitons while the script builds and runs SDL. 

    ./lsat.sh -b -e -t

Text messages are sent using each phone carrior's "email to SMS" email address.  You may need to replace the *carrierTextEmail* variable with your phone carrier's sms email address.  [Here is a list of them](http://www.emailtextmessages.com).
   
    carrierTextEmail=txt.att.net

## Notificaitons Available
You can turn on/off the types of notificaitons you recieve by editing the script's flag variables found at the start of the script.  Here is a list of those flags:

+ **notifyOnCompletion** - Sends a notification after the script has finished building or installing.

## Mandrill API
Instead of installing a mail server the script uses a free mailing API called Mandrill.  Only 12,000 emails can be sent each month with this free account, so you may want to [sign up](https://mandrill.com/pricing/) for your own account.  Once you have an account, you can generate an API key and copy/paste it into the script in the mailApiKey variable.
