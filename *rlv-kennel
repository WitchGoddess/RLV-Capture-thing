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
list rlv_hardcoded = ["@tplm=n","@tploc=n","@tplure=n","@sittp=n","@fly=n","@unsit=n"];
list rlv = ["@sendchat=y","@chatshout=y","@edit=y","@rez=y","@addoutfit=y","@remoutfit=y","@fartouch=y","@showworldmap=y","@showminimap=y","@showloc=y","@setenv=y"];
//list rlv_dress;
//list rlv_undress;

list rlv_full;
string search;
string replace;
string Y_N;
string Srch;
string Rep;
string note;
string AllDen;

string rlvcode = "";
string rlvcode1 = "";
string rlvcode2 = "";
string rlvcode3 = "";
string rlvcode4 = "";
string rlvcode5 = "";
string rlvcode6 = "";

integer checkingRLV;
integer RLV_detected;
integer Locked = FALSE;
integer Key_Taken = FALSE;


//string Sitb = "Sit Y";
string SendChatb = "SendChat Y";
string ChatShoutb = "Shout Y";
//string SendIMb = "Send-IM Y";
//string RecvChatb = "RecvChat Y";
//string RecvIMb = "Recv-IM Y";
string Editb = "Edit Y";
string Rezzb = "Rezz Y";
//string ShowINVb = "ShowINV Y";
string Outfitb = "Outfit Y";
//string ViewNoteb = "ViewNote Y";
string FarTouchb = "FarTouch Y";
string WorldMapb = "WorldMap Y";
string MiniMapb = "MiniMap Y";
string ShowLocb = "ShowLoc Y";
//string ShowNamesb = "ShwName Y";
string SetEnvb = "Set-Env Y";

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

dialogMenu(key door_operator)
{
    llListenRemove(menuChannel);
    MENU_CH = 0;
    channelMaker2();
    menuChannel = llListen( MENU_CH, "", door_operator, "");
    //llMessageLinked(LINK_SET, LISTENER_TIMER, "Timeout" + "^" + (string)Seconds + "^" + (string)menuChannel, NULL_KEY);
    list KennelMenu = ["More", "Back...", "Deny-ALL", "Allow-ALL", Rezzb, Editb, SendChatb];
    llDialog(door_operator, "Cage RLV Control Menu:\n\nY = Allowed\nN = Denied\n\n(Menu will Timeout in 60 Seconds.)", KennelMenu, MENU_CH);
}

dialogMenu2(key door_operator)
{
    llListenRemove(menuChannel);
    MENU_CH = 0;
    channelMaker2();
    menuChannel = llListen( MENU_CH, "", door_operator, "");
    //llMessageLinked(LINK_SET, LISTENER_TIMER, "Timeout" + "^" + (string)Seconds + "^" + (string)menuChannel, NULL_KEY);
    list KennelMenu = ["Back..", SetEnvb, Outfitb, MiniMapb, ShowLocb, FarTouchb, ChatShoutb];
    llDialog(door_operator, "Cage RLV Control Menu:\n\nY = Allowed\nN = Denied\n\n(Menu will Timeout in 60 Seconds.)", KennelMenu, MENU_CH);
}

addRem(string search,string replace,string note,string AllDen)
{
    integer rc = llListFindList(rlv, ["@" + search]);
    {
        if(rc != (integer)-1)
        {
            rlv=llDeleteSubList(rlv, rc, rc);
        }
    }
    rlvcode1 = "@" + replace;
    rlv+= [rlvcode1];
    if(Locked == TRUE)
    {
        llWhisper(0, note + AllDen);
    }
    integer length = llGetListLength(PetKeys);
    integer x;
    
    for(x = 0; x < length; x++)
    {
        key Pet = llList2Key(PetKeys, x);
        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ rlvcode1);
    }
}

hearExceptions(string search,string replace,key keyHolder)
{
    integer rc1 = llListFindList(rlv, ["@recvchat:" + (string)keyHolder + "=" + search]);
    {
        if(rc1 != (integer)-1)
        {
            rlv=llDeleteSubList(rlv, rc1, rc1);
        }
    }
    if(Key_Taken == TRUE)
    {
        rlvcode1 = "@recvchat:" + (string)keyHolder + "=" + replace;
        rlv+= [rlvcode1];
        integer length = llGetListLength(PetKeys);
        integer x;
        for(x = 0; x < length; x++)
        {
            key Pet = llList2Key(PetKeys, x);
            llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ rlvcode1);
        }
        
        rlvcode2 = "@sendim:" + (string)keyHolder + "=" + replace;
        rlv+= [rlvcode2];
        integer length2 = llGetListLength(PetKeys);
        integer y;
        for(y = 0; y < length2; y++)
        {
            key Pet = llList2Key(PetKeys, y);
            llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ rlvcode2);
        }
        
        rlvcode3 = "@recvim:" + (string)keyHolder + "=" + replace;
        rlv+= [rlvcode3];
        integer length3 = llGetListLength(PetKeys);
        integer z;
        for(z = 0; z < length3; z++)
        {
            key Pet = llList2Key(PetKeys, z);
            llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ rlvcode3);
        }
    }
    
    integer rc2 = llListFindList(rlv, ["@sendim:" + (string)keyHolder + "=" + search]);
    {
        if(rc2 != (integer)-1)
        {
            rlv=llDeleteSubList(rlv, rc2, rc2);
        }
    }
    rlvcode2 = "@sendim:" + (string)keyHolder + "=" + replace;
    rlv+= [rlvcode2];
    integer length2 = llGetListLength(PetKeys);
    integer y;
    for(y = 0; y < length2; y++)
    {
        key Pet = llList2Key(PetKeys, y);
        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ rlvcode2);
    }
    
    integer rc3 = llListFindList(rlv, ["@recvim:" + (string)keyHolder + "=" + search]);
    {
        if(rc3 != (integer)-1)
        {
            rlv=llDeleteSubList(rlv, rc3, rc3);
        }
    }
}

sendRLV()
{
    integer length = llGetListLength(PetKeys);
    integer x;
    
    for(x = 0; x < length; x++)
    {
        key Pet = llList2Key(PetKeys, x);
        rlv_full = rlv_hardcoded + rlv;
        //llSay(0, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv_full, "|"));
        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv_full, "|"));
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
    listen(integer channel, string name, key id, string message)
    {
        list messageList = llParseString2List(message, [MSG_SEP], []);
        string command = llList2String(messageList, 0);
        string YesNo = llList2String(messageList, 1);
        string recievedkey = llList2Key(messageList, 2);
        
        if(channel == MENU_CH)
        {
            list messageList = llParseString2List(message, [" "], []);
            string command = llList2String(messageList, 0);
            string YesNo = llList2String(messageList, 1);
            string recievedkey = llList2Key(messageList, 2);
            
            if(YesNo == "Y")
            {
                Y_N = "N";
                Srch = "=y";
                Rep = "=n";
                AllDen = " is now Denied.";
            }
            else if(YesNo == "N")
            {
                Y_N = "Y";
                Srch = "=n";
                Rep = "=y";
                AllDen = " is now Allowed.";
            }
            //llOwnerSay(message);
      /*      if(command == "Sit")
            {
                search = "sit" + Srch;
                replace = "sit" + Rep;
                Sitb = "Sit " + Y_N;
                note = "Sitting";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else */ if(command == "SendChat")
            {
                search = "sendchat" + Srch;
                replace = "sendchat" + Rep;
                SendChatb = "SendChat " + Y_N;
                note = "Speaking in Chat";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "Shout")
            {
                search = "chatshout" + Srch;
                replace = "chatshout" + Rep;
                ChatShoutb = "Shout " + Y_N;
                note = "Shouting in Chat";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            }
         /*   else if(command == "Send-IM")
            {
                search = "sendim" + Srch;
                replace = "sendim" + Rep;
                SendIMb = "Send-IM " + Y_N;
                note = "Sending IM's";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "RecvChat")
            {
                search = "recvchat" + Srch;
                replace = "recvchat" + Rep;
                RecvChatb = "RecvChat " + Y_N;
                note = "Hearing Chat";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "Recv-IM")
            {
                search = "recvim" + Srch;
                replace = "recvim" + Rep;
                RecvIMb = "Recv-IM " + Y_N;
                note = "Receiving IM's";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            } */
            else if(command == "Edit")
            {
                search = "edit" + Srch;
                replace = "edit" + Rep;
                Editb = "Edit " + Y_N;
                note = "Edit";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "Rezz")
            {
                search = "rez" + Srch;
                replace = "rez" + Rep;
                Rezzb = "Rezz " + Y_N;
                note = "Rezz";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
       /*     else if(command == "ShowINV")
            {
                search = "showinv" + Srch;
                replace = "showinv" + Rep;
                ShowINVb = "ShowINV " + Y_N;
                note = "Opening Inventory";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            } */
            else if(message == "Outfit Y")
            {
                integer rc = llListFindList(rlv, ["@addoutfit=y"]);
                {
                if(rc != (integer)-1)
                    {
                        rlv=llDeleteSubList(rlv, rc, rc);
                    }
                }
                integer rc1 = llListFindList(rlv, ["@remoutfit=y"]);
                {
                if(rc1 != (integer)-1)
                    {
                        rlv=llDeleteSubList(rlv, rc1, rc1);
                    }
                }
                rlvcode1 = "@addoutfit=n";
                rlvcode2 = "@remoutfit=n";
                rlv+= [rlvcode1];
                rlv+= [rlvcode2];
                Outfitb = "Outfit N";
                integer length = llGetListLength(PetKeys);
                integer x;
    
                for(x = 0; x < length; x++)
                {
                    key Pet = llList2Key(PetKeys, x);
                    llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + "," + rlvcode1 + "|" + rlvcode2);
                }
                if(Locked == TRUE)
                {
                    llWhisper(0, "Wearing/Removing Clothing is now Denied.");
                }
                dialogMenu2(door_operator);
            }
            else if(message == "Outfit N")
            {
                integer rc = llListFindList(rlv, ["@addoutfit=n"]);
                {
                if(rc != (integer)-1)
                    {
                        rlv=llDeleteSubList(rlv, rc, rc);
                    }
                }
                integer rc1 = llListFindList(rlv, ["@remoutfit=n"]);
                {
                if(rc1 != (integer)-1)
                    {
                        rlv=llDeleteSubList(rlv, rc1, rc1);
                    }
                }
                rlvcode1 = "@addoutfit=y";
                rlvcode2 = "@remoutfit=y";
                rlv+= [rlvcode1];
                rlv+= [rlvcode2];
                Outfitb = "Outfit Y";
                integer length = llGetListLength(PetKeys);
                integer x;
    
                for(x = 0; x < length; x++)
                {
                    key Pet = llList2Key(PetKeys, x);
                    llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + "," + rlvcode1 + "|" + rlvcode2);
                }
                if(Locked == TRUE)
                {
                    llWhisper(0, "Wearing/Removing Clothing is now Allowed.");
                }
                dialogMenu2(door_operator);
            }
         /*   else if(command == "ViewNote")
            {
                search = "viewnote" + Srch;
                replace = "viewnote" + Rep;
                ViewNoteb = "ViewNote " + Y_N;
                note = "Viewing Notecards";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            } */
            else if(command == "FarTouch")
            {
                search = "fartouch" + Srch;
                replace = "fartouch" + Rep;
                FarTouchb = "FarTouch " + Y_N;
                note = "Far-Touch";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "WorldMap")
            {
                search = "showworldmap" + Srch;
                replace = "showworldmap" + Rep;
                WorldMapb = "WorldMap " + Y_N;
                note = "Viewing World-Map";
                addRem(search,replace,note,AllDen);
                dialogMenu(door_operator);
            }
            else if(command == "MiniMap")
            {
                search = "showminimap" + Srch;
                replace = "showminimap" + Rep;
                MiniMapb = "MiniMap " + Y_N;
                note = "Viewing Mini-Map";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            }
            else if(command == "ShowLoc")
            {
                search = "showloc" + Srch;
                replace = "showloc" + Rep;
                ShowLocb = "ShowLoc " + Y_N;
                note = "Viewing Locations";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            }
       /*     else if(command == "ShwName")
            {
                search = "shownames" + Srch;
                replace = "shownames" + Rep;
                ShowNamesb = "ShwName " + Y_N;
                note = "Viewing Names";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            } */
            else if(command == "Set-Env")
            {
                search = "setenv" + Srch;
                replace = "setenv" + Rep;
                SetEnvb = "Set-Env " + Y_N;
                note = "Setting Environment Settings";
                addRem(search,replace,note,AllDen);
                dialogMenu2(door_operator);
            }
            else if(command == "More")
            {
                dialogMenu2(door_operator);
            }
            else if(command == "Back..")
            {
                dialogMenu(door_operator);
            }
            else if(command == "Back...")
            {
                llMessageLinked(LINK_SET, BACK, "Return_From_RLV", NULL_KEY);
            }
            else if(message == "Deny-ALL")
            {
                //Sitb = "Sit N";
                SendChatb = "SendChat N";
                ChatShoutb = "Shout N";
                //SendIMb = "Send-IM N";
                //RecvChatb = "RecvChat N";
                //RecvIMb = "Recv-IM N";
                Editb = "Edit N";
                Rezzb = "Rezz N";
                //ShowINVb = "ShowINV N";
                Outfitb = "Outfit N";
                //ViewNoteb = "ViewNote N";
                FarTouchb = "FarTouch N";
                WorldMapb = "WorldMap N";
                MiniMapb = "MiniMap N";
                ShowLocb = "ShowLoc N";
                //ShowNamesb = "ShwName N";
                SetEnvb = "Set-Env N";
                ALL = "All menu Restrictions are enabled.";
                rlv = ["@sendchat=n","@chatshout=n","@edit=n","@rez=n","@addoutfit=n","@remoutfit=n","@fartouch=n","@showworldmap=n","@showminimap=n","@showloc=n","@setenv=n"];
                if(Locked == TRUE)
                {
                    integer length = llGetListLength(PetKeys);
                    integer x;
        
                    for(x = 0; x < length; x++)
                    {
                        key Pet = llList2Key(PetKeys, x);
                        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv, "|"));
                    }
                    llWhisper(0,"All RLV menu Restrictions are now Denied");
                }
                dialogMenu(door_operator);
            }
            else if(message == "Allow-ALL")
            {
                //Sitb = "Sit Y";
                SendChatb = "SendChat Y";
                ChatShoutb = "Shout Y";
                //SendIMb = "Send-IM Y";
                //RecvChatb = "RecvChat Y";
                //RecvIMb = "Recv-IM Y";
                Editb = "Edit Y";
                Rezzb = "Rezz Y";
                //ShowINVb = "ShowINV Y";
                Outfitb = "Outfit Y";
                //ViewNoteb = "ViewNote Y";
                FarTouchb = "FarTouch Y";
                WorldMapb = "WorldMap Y";
                MiniMapb = "MiniMap Y";
                ShowLocb = "ShowLoc Y";
                //ShowNamesb = "ShwName Y";
                SetEnvb = "Set-Env Y";
                ALL = "All menu Restrictions are disabled.";
                rlv = ["@sendchat=y","@chatshout=y","@edit=y","@rez=y","@addoutfit=y","@remoutfit=y","@fartouch=y","@showworldmap=y","@showminimap=y","@showloc=y","@setenv=y"];
                if(Locked == TRUE)
                {
                    integer length = llGetListLength(PetKeys);
                    integer x;
        
                    for(x = 0; x < length; x++)
                    {
                        key Pet = llList2Key(PetKeys, x);
                        llSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ llDumpList2String(rlv, "|"));
                    }
                    llWhisper(0,"All RLV menu Restrictions are now Allowed");
                }
                dialogMenu(door_operator);
            }
        }
        else if (channel == RELAY_CHANNEL)
        {
            execute(name, id, message);
        }
    }
    link_message(integer sender_num, integer num, string str, key id)
    {
        list messageList = llParseString2List(str, [MSG_SEP], []);
        string command = llList2String(messageList, 0);
        key recievedKey = llList2Key(messageList, 1);
        if(num == RLV)
        {
            if(command == "RLV_menu")
            {
                door_operator = recievedKey;
                dialogMenu(door_operator);
            }
            else if(command == "Lock")
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
                search = "rem";
                replace = "add";
                hearExceptions(search,replace,keyHolder);
            }
            else if(command == "key_returned")
            {
                search = "add";
                replace = "rem";
                hearExceptions(search,replace,keyHolder);
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
                llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)target + ","+ llDumpList2String(rlv_full, "|"));
            }
        }
        else if(num == KEY_LIST)
        {
            //llOwnerSay("Key list " + str);
            PetKeys = llParseString2List(str, [","], []);
        }
    }      
}
