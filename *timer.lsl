//-----Link Channels-----//
integer SENSOR          = 136;
integer TIMER           = 11009;
integer BACK            = 11010;
integer DOOR_BUTTON     = 11008;
integer LISTENER_TIMER2 = 11012;

string MSG_SEP = "^";

key ownerk;
key nameKey;

string HideTimerb = "HideTimer";
integer timerHidden = FALSE;
string HideTimer = "*Timer is Displayed when its running.";

//-----Timer-----//
integer slTimer = TRUE;
string number;
string timeword;
integer time;
integer Timer_CHANNEL = 0;
integer Button_CHANNEL = 0;
integer Timer_CHANNEL_LS;
integer Button_CHANNEL_LS;
integer releaseTime;
integer lastTimeCheck;
integer timerRunning;
string timerState = "Timer Stopped:";

string DisplayTime(integer seconds)
{
    integer hours;
    integer minutes;
            
    hours = seconds / 3600;
    seconds = seconds - (hours * 3600);
    minutes = seconds / 60;
    seconds = seconds - (minutes * 60);
    
    return((string)hours + "h:" + (string)minutes + "m:" + (string)seconds + "s");
}

//-----Channel Maker-----//
TimerButton_CHANNEL()
{
    if(Timer_CHANNEL == 0);
    {
        do
        {
            Timer_CHANNEL = ((integer) llFrand(3) - 1) * ((integer) llFrand(2147483647)); 
        }
        while(Timer_CHANNEL == 0);
    }
    if(Button_CHANNEL == 0);
    {
        do
        {
         Button_CHANNEL = ((integer) llFrand(3) - 1) * ((integer) llFrand(2147483647)); 
        }
        while(Button_CHANNEL == 0);
    }
}

timerMenu(key nameKey)
{
    Timer_CHANNEL = 0;
    Button_CHANNEL = 0;
    TimerButton_CHANNEL();
    Button_CHANNEL_LS = llListen(Button_CHANNEL, "", nameKey, "");
    Timer_CHANNEL_LS = llListen( Timer_CHANNEL, "", nameKey, "");
    llMessageLinked(LINK_SET, LISTENER_TIMER2, "Timeout" + "^" + "60", NULL_KEY);
    list tmr = [HideTimerb, "Main...", "-", "Add", "Remove", "Clear", "Start", "Stop", "Refresh"];
    llDialog(nameKey, "(Menu will Timeout in 60 Seconds).\n*" + timerState + "  " + DisplayTime(releaseTime) + "\n\n" + HideTimer + "\n\nClick Refresh to refresh the timer above.", tmr, Button_CHANNEL);
}

addMenu()
{
    list tmr1 = ["Back...", "Add 5 Mins", "Add 15 Mins", "Add 30 Mins", "Add 1 Hour", "Add 2 Hours", "Add 5 Hours", "Add 10 Hours", "Add 24 Hours", "Start", "Add 7 Days", "Add 2 Weeks"];
    llDialog(nameKey, "How much time would you like to add to the Timer?\n\n" + timerState + "  " + DisplayTime(releaseTime), tmr1, Timer_CHANNEL);
}

remMenu()
{
    list tmr1 = ["Back...", "- 5 Mins", "- 15 Mins", "- 30 Mins", "- 1 Hour", "- 2 Hours", "- 5 Hours ", "- 10 Hours", "- 24 Hours", "Start", "- 7 Days", "- 2 Weeks"];
    llDialog(nameKey, "How much time would you like to remove from the Timer?\n\n" + timerState + "  " + DisplayTime(releaseTime), tmr1, Timer_CHANNEL);
}

timing(list messageList)
{
    string HMW = llList2String(messageList, 2);
    string timePrefix = llGetSubString(HMW, 0, 0);
    //llOwnerSay(timePrefix);
    if(timePrefix == "M")
    {
        time = llList2Integer(messageList, 1);
        time = (time * 60);
    }
    else if(timePrefix == "H")
    {
        time = llList2Integer(messageList, 1);
        time = (time * 3600);
    }
    else if(timePrefix == "D")
    {
        time = llList2Integer(messageList, 1);
        time = (time * 86400);
    }
    else if(timePrefix == "W")
    {
        time = llList2Integer(messageList, 1);
        time = (time * 604800);
    }
}

startTimer(){
    if(releaseTime > 0){
        lastTimeCheck = llGetUnixTime();
        llSetTimerEvent(5);
        timerRunning = 1;
        timerState = "Timer Running:";
        llMessageLinked(LINK_SET, SENSOR, "TimerStarted", NULL_KEY);
        if(timerHidden == FALSE){
            llSetText(DisplayTime(releaseTime), <1,1,1>, 1.0);
        }
        else if (timerHidden == TRUE){
            llWhisper(0,"Timer is Hidden...");
            llSetText(" ", <1,1,1>, 1.0);
        }
        if(nameKey!=NULL_KEY && nameKey == ownerk){
            llMessageLinked(LINK_SET, BACK, "Owner_Locked", NULL_KEY);
        }
        else if(nameKey!=NULL_KEY){
            llMessageLinked(LINK_SET, BACK, "Sub_Locked", NULL_KEY);
        }
    }
    else{
        timerMenu(nameKey);
    }
}

default
{
    on_rez(integer p)
    {
        llResetScript();
    }
    state_entry()
    {
        //llWhisper(0,"Script Reset");
        ownerk = llGetOwner();
        llSetText(" ", <1,1,1>, 1.0);
        
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if(channel == Button_CHANNEL)
        {
            if(nameKey == id)
            {
                if(message == "Add")
                {
                    addMenu();
                }
                else if(message == "Remove")
                {
                    remMenu();
                }
                else if(message == "Start")
                {
                    startTimer();
                }
                else if(message == "Stop")
                {
                    llSetTimerEvent(0);
                    timerRunning = 0;
                    timerState = "Timer Stopped:";
                    llSetText(" ", <1,1,1>, 1.0);
                    //llMessageLinked(LINK_SET, BACK,"timeCHK" + MSG_SEP + DisplayTime(releaseTime), NULL_KEY); 
                    llWhisper(0,"Timer Stopped.");
                    llMessageLinked(LINK_SET, BACK, "Timer_Stop", NULL_KEY);  
                    llMessageLinked(LINK_SET, SENSOR, "TimerStopped", NULL_KEY);
                    llSleep(0.5);
                    timerMenu(nameKey);
                }
                else if(message == "Clear")
                {
                    llSetTimerEvent(0);
                    timerRunning = 0;
                    releaseTime = 0;
                    timerState = "Timer Stopped:";
                    llWhisper(0,"Timer Cleared and Stopped.");
                    llMessageLinked(LINK_SET, SENSOR, "TimerStopped", NULL_KEY);
                    llSetText(" ", <1,1,1>, 1.0);
                    llSleep(0.5);
                    timerMenu(nameKey);
                }
                else if(message == "Refresh")
                {
                    timerMenu(nameKey);
                }
                else if(message == "Main...")
                {
                     llMessageLinked(LINK_SET, BACK, "Return_From_Timer", NULL_KEY);
                }
                else if(message == "HideTimer")
                {
                     HideTimerb = "ShowTimer";
                     timerHidden = TRUE;
                     HideTimer = "*Timer is Hidden when its running.";
                     llWhisper(0,"Timer will now be Hidden when its running");
                     llSetText(" ", <1,1,1>, 1.0);
                     timerMenu(nameKey);
                }
                else if(message == "ShowTimer")
                {
                     HideTimerb = "HideTimer";
                     timerHidden = FALSE;
                     HideTimer = "*Timer is Displayed when its running.";
                     llWhisper(0,"Timer will now be Shown when its running");
                     llSetText(DisplayTime(releaseTime), <1,1,1>, 1.0);
                     timerMenu(nameKey);
                }
                else
                {
                    timerMenu(nameKey);
                }
            }
        }
        else if(channel == Timer_CHANNEL)
        {
            list messageList = llParseString2List(message, [" "], []);
            string command = llList2String(messageList, 0);
            string number = llList2String(messageList, 1);
            string timeword = llList2String(messageList, 2);
          if(nameKey == id)
          {
            if(command == "Add")
            {
                timing(messageList);
                releaseTime = releaseTime + time;
                if(timerHidden == FALSE){
                    llWhisper(0,number + " " + timeword + " added to Timer. Total Time: " + (string)DisplayTime(releaseTime));
                }
                addMenu();
            }
            else if(command == "-")
            {
                timing(messageList);
                releaseTime = releaseTime - time;
                
                if(releaseTime <= 0)
                {
                    if(timerRunning)
                    {
                        llWhisper(0, "Timer Cleared.");
                    }
                    
                    llSetTimerEvent(0);
                    timerRunning = 0;
                    releaseTime = 0;
                    llMessageLinked(LINK_SET, SENSOR, "TimerStopped", NULL_KEY);
                }
                
                if(timerHidden == FALSE)
                {
                    llWhisper(0,number + " " + timeword + " removed from Timer. Total Time: " + (string)DisplayTime(releaseTime));
                }
                remMenu();
            }
            else if(message == "Start")
            {
                startTimer();
            }
            else if(message == "Back...")
            {
                timerMenu(nameKey);
            }
          }
        }
    }
    timer()
        {
        integer currentTime = llGetUnixTime();
        releaseTime = releaseTime - (currentTime - lastTimeCheck);
        lastTimeCheck = currentTime;
        
        if(releaseTime <= 0)
        {
            llSetTimerEvent(0);
            timerRunning = 0;            
            releaseTime = 0;

            llMessageLinked(LINK_SET, SENSOR, "TimerStopped", NULL_KEY);
            llMessageLinked(LINK_SET, BACK, "Unlock", NULL_KEY); 
            llSetText(" ", <1,1,1>, 1.0);
        }
        else
        {
            if(timerHidden == FALSE)
            {
                llSetText(DisplayTime(releaseTime), <1,1,1>, 1.0);
            }
            else if (timerHidden == TRUE)
            {
                llSetText(" ", <1,1,1>, 1.0);
            }
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        list messageList = llParseString2List(str, [MSG_SEP], []);
        string command = llList2String(messageList, 0);
        key recievedKey = llList2Key(messageList, 1);
        if(num == TIMER)
        {
            nameKey = recievedKey;
            if(command == "Timer")
            {
                timerMenu(nameKey);
            }
            else if(command == "Time_Check")
            {
                llMessageLinked(LINK_SET, BACK,"timeCHK" + MSG_SEP + DisplayTime(releaseTime), NULL_KEY); 
            }
            else if(command == "Pause")
            {
                //llOwnerSay("Pause");
                llSetTimerEvent(0);
                timerRunning = 0;
                timerState = "Timer Stopped:";
                llSetText(" ", <1,1,1>, 1.0);
            }
            else if(command == "Resume")
            {
                lastTimeCheck = llGetUnixTime();
                llSetTimerEvent(5);
                timerRunning = 1;
                timerState = "Timer Running:";
                if(timerHidden == FALSE)
                {
                    llSetText(DisplayTime(releaseTime), <1,1,1>, 1.0);
                }
                else if (timerHidden == TRUE)
                {
                    llSetText(" ", <1,1,1>, 1.0);
                }
            }
            else if(command == "Unlock")
            {
                llSleep(1.0);
                llResetScript();
            }
        }
        else if(num == LISTENER_TIMER2){
            list messageList = llParseString2List(str, ["^"], []);
            string command = llList2String(messageList, 0);
            integer item = llList2Integer(messageList, 1);
            
            if(command == "Remove_Listener"){
                llListenRemove(Button_CHANNEL_LS);
                llListenRemove(Timer_CHANNEL_LS);
            }
        }
        else if (num == DOOR_BUTTON && command=="Lock"){
            if (releaseTime<300){
                nameKey=NULL_KEY;
                releaseTime = 0; //changed from 300 to 0 so 'lock' can simply lock without a timer *Dav
                startTimer();
            }
        }
    }
}
