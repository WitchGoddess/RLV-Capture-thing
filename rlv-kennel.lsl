integer MENU_CH = 0;
integer menuChannel;
//-----Link Channels-----//
integer RLV             = 11012;
integer BACK            = 11013;
integer KEY_LIST        = 11014;

integer RELAY_CHANNEL = -1812221819;

string MSG_SEP = "^";

key ownerk;
key nameKey;
key door_operator;

list PetKeys;
list rlv_hardcoded = ["@tplm=n","@tploc=n","@tplure=n","@sittp=n","@fly=n","@unsit=n","@sendchat=n","@edit=n","@rez=n","@addoutfit=n","@remoutfit=n","@fartouch:3=n"];
//Possible additions @camdistmax:0=n (force mouselook only), @camunlock=n (only disallow freecam), @chatnormal=n (can only whisper), @sendgesture=n (disallow gestures), @touchall=n (disallow touch at all), @touchworld=n (disallow touching anything but hud), @showworldmap=n, @showminimap=n, @showloc=n, "@shownames:"+ownerk+"=n", @showhovertextworld=n, 

integer checkingRLV;
integer RLV_detected;
integer Locked = FALSE;
integer Key_Taken = FALSE;

string ALL = "All menu Restrictions are enabled.";

key keyHolder = NULL_KEY;

//-----Channel Maker-----//

channelMaker2()
{
    if(MENU_CH == 0);
    {
        do
        {
            MENU_CH = ((integer) llFrand(3) - 1) * ((integer) llFrand(2147483647));
        }
        while(MENU_CH == 0);
    }
}

sendRLV()
{
    integer length = llGetListLength(PetKeys);
    integer x;
    
    for(x = 0; x < length; x++)
    {
        key Pet = llList2Key(PetKeys, x);
        //llSay(0, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv_hardcoded, "|"));
        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv_hardcoded, "|"));
    }   
    //llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)petName+",@tplm=n|@tploc=n|@tplure=n|@sittp=n|@fartouch=n");
}

releaseRLV()
{
    integer length = llGetListLength(PetKeys);
    integer x;
    
    for(x = 0; x < length; x++)
    {
        key Pet = llList2Key(PetKeys, x);
        llShout(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ",!release");
    }
}

sendCommand(string commandName, key id, string commands) {
    llSay(RELAY_CHANNEL, commandName + "," + (string) id + "," + commands);
}

execute(string name, key id, string message) {
    list tokens=llParseString2List (message, [","], []);
    if (llGetListLength(tokens) == 4) {
        string cmd_name = llList2String(tokens, 0);
        key target = llList2Key(tokens, 1);
        string cmd = llList2String(tokens, 2);
        string reply = llList2String(tokens, 3);
        if (target == llGetKey()) //talking to me?
        {
            if(cmd == "ping" && reply == "ping") //relay requested a ping
            {
                sendCommand("ping", llGetOwnerKey(id), "!pong");
            }
            else if (cmd == "!version") //reply to our !version request
            {
                //if (isCompatibleVersion((integer) reply)) {
                //    avatarsWithRelay += [llGetOwnerKey(id)];
                //}
            }
        }
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
        llListen( RELAY_CHANNEL, "", "", "");
    }
    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(checkingRLV);
        if(RLV_detected != TRUE)
        {
            //llOwnerSay("RLV Viewer wasn't Detected. Your Keyholder has been informed. If you logged in Regular viewer so you could Cheat then you are a naughty puppy.");
            //llMessageLinked(LINK_SET, RLV, "RLV_CHK_FAILED", NULL_KEY);
        }
    }
    link_message(integer sender_num, integer num, string str, key id)
    {
        list messageList = llParseString2List(str, [MSG_SEP], []);
        string command = llList2String(messageList, 0);
        key recievedKey = llList2Key(messageList, 1);
        if(num == RLV)
        {
            if(command == "Lock")
            {
                sendRLV();
                Locked = TRUE;
            }
            else if(command == "Unlock")
            {
                releaseRLV();
                Locked = FALSE;
            }
            else if(command == "key_taken")
            {
                Key_Taken = TRUE;
                keyHolder = recievedKey;
            }
            else if(command == "key_returned")
            {
                llSleep(1.0);
                keyHolder = NULL_KEY;
                Key_Taken = FALSE;
            }
            else if(command == "tempRelease")
            {
                key target = recievedKey;
                llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)target + ",!release");
            }
            else if(command == "Relock")
            {
                key target = recievedKey;
                llWhisper(0,"Debug: Received: command " + command + "and key " target);
                llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)target + ","+ llDumpList2String(rlv_hardcoded, "|"));
                llWhisper(0,"Debug: Relock triggered");                 
            }
        }
        else if(num == KEY_LIST)
        {
            //llOwnerSay("Key list " + str);
            PetKeys = llParseString2List(str, [","], []);
        }
    }      
}
