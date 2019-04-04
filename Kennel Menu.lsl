//-----Link Channels-----//
integer DOOR_BUTTON     = 11008;
integer TIMER           = 11009;
integer RCV_TIMER       = 11010;
integer RLV             = 11012;
integer PetKey_Chan        = 11014;
integer SENSOR          = 136;
//-------------------------//

integer RANGE_CAPTURE   = 20;

//-----Channels-----//
integer MENU_CH         = 0;
integer RELAY_CHANNEL   = -1812221819;
integer CAPTURE_CHANNEL = 0;
//-------------------//

// Sound UUIDs //
key plush_lock_snd="dec9fb53-0fef-29ae-a21d-b3047525d312";
key plush_unlock_snd="82fa6d06-b494-f97c-2908-84009380c8d1";
key zip_plush_snd="41bac678-f15d-3752-5c6b-f511edb8af35";
key unzip_plush_snd="e9a2470e-9d16-e5aa-515c-39f37fe9a2cb";
//old unzip sound: db367252-0201-a5dc-df12-53f6e48e3bd7

// HardCoded list of allowed pets //
list AllowedPets = ["29f5f1c7-f330-4e2c-ba99-828ee4e8ea53"];

string displayTime;

integer menuChannel;
integer captureChannel;

integer PetAccess = TRUE;
integer Plush_Locked = FALSE;
integer HasPlushPresent = FALSE;
key Pet;

string MSG_SEP = "^";
integer Seconds = 60;
string PingFromRelay;
key ownerk;
key LastSitter;
string OwnerB = "-";
string LockB = "-";
string Timerb = "-";
string Keysb = "-";
string UnPlushB="-";
string HideDollB="-";
key hasKey_key;
string hasKey;

integer Key_Taken = FALSE;
integer Timer_Running = FALSE;

list rlv;
list sensor_keys;
list sensor_names;
key door_operator = NULL_KEY;
integer linkCount;
integer poseballlink = -1;
integer eyeslink = -1;

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return 0; // No prim with that name, return -1.
}


channelMaker2(){
    MENU_CH=-((integer)llFrand(100000))+999;
    CAPTURE_CHANNEL=-((integer)llFrand(100000))+999;
}

timer_check(){
    llMessageLinked(LINK_SET, TIMER, "Time_Check", NULL_KEY);
}

kennelReset(){
    llMessageLinked(LINK_SET, RLV, "Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, TIMER,"Unlock" + MSG_SEP + (string)door_operator, NULL_KEY);
    llResetOtherScript("*rlv-kennel");
    llResetOtherScript("*sensor");
    llResetScript();
}

dialogMenu(key door_operator){
    MENU_CH = 0;
    channelMaker2();
    llListenRemove(menuChannel);
    llListenRemove(captureChannel);
    menuChannel = llListen( MENU_CH, "", door_operator, "");
    captureChannel = llListen( CAPTURE_CHANNEL, "", door_operator, "");
    list KennelMenu = [LockB, OwnerB, Keysb, Timerb, "Capture", UnPlushB];
    llDialog(door_operator, "Plush Toy Control Menu:\n\n(Menu will Timeout in 60 Seconds.)", KennelMenu, MENU_CH);
}

ownerMenu(key door_operator){
    MENU_CH = 0;
    channelMaker2();
    llListenRemove(menuChannel);
    llListenRemove(captureChannel);
    menuChannel = llListen( MENU_CH, "", door_operator, "");
    menuChannel = llListen ( CAPTURE_CHANNEL, "", door_operator, "");
    list OwnerMenu = ["Reset", HideDollB, "Back..."];
    llDialog(door_operator, "Plush Toy Control Menu:.", OwnerMenu, MENU_CH);
}

Unlock(){
    LockB = "Lock";
    Timerb = "Timer";
    Plush_Locked = FALSE;
    Timer_Running = FALSE;
    PetAccess = TRUE;
    Key_Taken = FALSE;
    hasKey_key = NULL_KEY;
    hasKey = "";
    Keysb = "-";
    UnPlushB="UnPlush";
    llPlaySound(plush_unlock_snd,1);
    llMessageLinked(LINK_SET, TIMER,"Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, SENSOR, "OFF", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Unlock", NULL_KEY);
}

Lock(){
    LockB = "Unlock";
    Timerb = "Timer";
    UnPlushB="UnPlush";
    if (Plush_Locked==FALSE) llPlaySound(plush_lock_snd,1);
    Plush_Locked = TRUE;
    PetAccess = FALSE;
    llMessageLinked(LINK_SET, SENSOR, "ON", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Lock", NULL_KEY);
    if(Key_Taken == FALSE){
        Keysb = "Take Key";
        Key_Taken = FALSE;
        hasKey_key = NULL_KEY;
        hasKey = "";
    }
}

MakePlush(){
    llPlaySound(zip_plush_snd,1);
    llMessageLinked(LINK_SET, RLV, "Plush", NULL_KEY);
    HasPlushPresent = TRUE;
    MakeInvis(FALSE);
    llSleep(1.5); //added delay for sound before doing lock
    Lock();

}

Unplush(){
    UnPlushB="-";
    llMessageLinked(LINK_SET, RLV, "UnPlush", NULL_KEY);
    llUnSit(llAvatarOnLinkSitTarget(poseballlink));
    HasPlushPresent = FALSE;
    MakeInvis(TRUE);
    llPlaySound(unzip_plush_snd,1);
}

MakeInvis(integer invis){
    if (invis==TRUE){
        llSetLinkAlpha(poseballlink,0,ALL_SIDES);
        llSetLinkAlpha(eyeslink,0,ALL_SIDES);
        HideDollB="Show Doll";
    }
    else {
        llSetLinkAlpha(poseballlink,1,ALL_SIDES);
        llSetLinkAlpha(eyeslink,1,ALL_SIDES);
        HideDollB="Hide Doll";
    }
}

capture(string name){
    integer index = llListFindList(sensor_names, [name]);
    if (index != -1){
        key sensorKey = llList2Key(sensor_keys, index);
        relay(sensorKey, "@sit:" + (string)llGetLinkKey(poseballlink) + "=force");
    }
}

relay(key avatar, string message){
    llSay(RELAY_CHANNEL, llGetObjectName() + "," + (string) avatar + "," + message);
}

default{
    on_rez(integer p){
        llResetScript();
    }
    
    state_entry(){
        poseballlink = getLinkWithName("Plush");
        eyeslink = getLinkWithName("Eyes");
        MakeInvis(FALSE);
        channelMaker2();
        ownerk = llGetOwner();
        linkCount=llGetObjectPrimCount(llGetKey());
        llListen(CAPTURE_CHANNEL, "", NULL_KEY, "");
        llOwnerSay("Plush Reset");
    }
    
    sensor(integer num){
        sensor_keys = [];
        sensor_names = [];
        integer i;
        for(i=0; i < num && i<13; i++){
            key id = llDetectedKey(i);
            string name = llKey2Name(id);
            if (llStringLength(name) > 24){
                name = llGetSubString(name, 0, 23);
            }
            sensor_keys += [id];
            sensor_names += [name];
        }
 
        // show dialog if list contains names
        if (llGetListLength(sensor_names) > 0){
            llDialog(door_operator, "Capture:", sensor_names, CAPTURE_CHANNEL);
        }
    }
    
    touch_start(integer total_number){
        float dist = llVecDist(llDetectedPos(0), llGetPos());
        if(dist < 10.0 || llDetectedKey(0)==llGetOwner()){
            if(llDetectedKey(0) == ownerk){
                OwnerB = "Setup";
                if((string)ownerk != (string)Pet){
                    door_operator = llDetectedKey(0);
                    dialogMenu(door_operator);
                }
                else{
                    if(Plush_Locked == TRUE)                        {
                        llInstantMessage(llDetectedKey(0), "You try to move but find yourself completely inanimate.");
                        if(Timer_Running == TRUE){
                            llWhisper(0,"You will become animated again once timer expires.");
                        }
                    }
                    else{
                        door_operator = llDetectedKey(0);
                        dialogMenu(door_operator);
                    }
                }
            }
            else if(llDetectedKey(0) != ownerk){
                if((string)llDetectedKey(0) != (string)Pet){
                    if(PetAccess == TRUE){
                        door_operator = llDetectedKey(0);
                        dialogMenu(door_operator);
                    }
                    else if(PetAccess == FALSE){
                        llInstantMessage(llDetectedKey(0), "You try to move but find yourself completely inanimate.");
                        if(Timer_Running == TRUE)
                        {
                            timer_check();
                            llWhisper(0,"You will become animated again once timer expires.");
                        }
                    }
                }
                else{
                    if(Key_Taken == FALSE){
                        door_operator = llDetectedKey(0);
                        dialogMenu(door_operator);
                    }
                    else if(Key_Taken == TRUE){
                        if(llDetectedKey(0) == hasKey_key)
                        {
                            door_operator = llDetectedKey(0);
                            dialogMenu(door_operator);
                        }
                        else{
                            llWhisper(0,"This plush toy has been locked and " + hasKey + " has taken the key. Only them or the toy's owner can unlock it.  (Or it will auto-unlock if a timer is running when it expires.)");
                        }
                    }
                }
            }
        }
        else{
            llInstantMessage(llDetectedKey(0),"Sorry, you can't access the menu from that far away. Come closer.");
        }
    }
    
    listen(integer channel, string name, key id, string message){
        if (channel == CAPTURE_CHANNEL && id==door_operator){
            capture(message);
        }
        else if(channel == MENU_CH){
            list messageList = llParseString2List(message, [MSG_SEP], []);
            string command = llList2String(messageList, 0);
            key verify = llList2Key(messageList, 1);
            string recievedkey = llList2Key(messageList, 2);
            if (command=="Capture"){
                llSensor("", NULL_KEY, AGENT, RANGE_CAPTURE, PI);
            }
            else if(command == "Setup"){
                if (id==llGetOwner())
                    ownerMenu(door_operator);
                else llInstantMessage(id,"You are not the owner.");
            }
            else if(command == "Back..."){
                dialogMenu(door_operator);
            }
            else if(command == "Lock"){
                llInstantMessage(door_operator,"Touch the plush again for Lock, Timer and Key options.");
                Lock();
            }
            else if(command == "Unlock"){
                Unlock();
                dialogMenu(door_operator);
            }
            else if(message == "Take Key"){
                hasKey_key = door_operator;
                hasKey = llKey2Name(door_operator);
                llMessageLinked(LINK_SET, RLV, "key_taken" + "^" + (string)door_operator, NULL_KEY);
                llWhisper(0,name + " has taken the key, only them or the owner can unlock it now (or if a timer is set, it will auto-unlock when the timer expires.)");
                Key_Taken = TRUE;
                Keysb = "Return Key";
                dialogMenu(door_operator);
            }
            else if(message == "Return Key"){
                string name = llKey2Name(door_operator);
                llMessageLinked(LINK_SET, RLV, "key_returned" + "^" + (string)door_operator, NULL_KEY);
                llWhisper(0,name + " has returned the key, anyone unlock it if they choose.");
                Key_Taken = FALSE;
                hasKey_key = NULL_KEY;
                hasKey = "";
                Keysb = "Take Key";
                dialogMenu(door_operator);
            }
            else if(command == "Reset" && id==llGetOwner()){
                kennelReset();
            }
            else if(command == "Hide Doll" && id==llGetOwner()){
                MakeInvis(TRUE);
            }
            else if(command == "Show Doll" && id==llGetOwner()){
                MakeInvis(FALSE);
            }
            else if(message == "Timer"){
                llMessageLinked(LINK_SET, TIMER,"Timer" + MSG_SEP + (string)door_operator, NULL_KEY);
            }
            else if(command == "UnPlush"){
                Unlock();
                llSleep(1); //Delay between automatically unlocking and getting out of the plush
                Unplush();
            }
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id){
        if(num == SENSOR){
            list pets = llParseString2List(str, [","], []);
            string command = llList2String(pets, 0);
            if(command == "escaped"){
                list pets = llParseString2List(str, [","], []);
                string command = llList2String(pets, 0);
                key escapee = llList2Key(pets, 1);
                
                string escaped_pet = llKey2Name(escapee);
                Unplush();
                if(Key_Taken == TRUE){
                    llInstantMessage(hasKey_key,escaped_pet + " has escaped!");
                }
            }
        }
        else if(num == PetKey_Chan){
            Pet = (key)str;
        }
        else if(num == RCV_TIMER){
            list messageList = llParseString2List(str, [MSG_SEP], []);
            string command = llList2String(messageList, 0);
            string recievedInfo = llList2String(messageList, 1);
            if(str == "Return_From_Timer"){
                dialogMenu(door_operator);
            }
            else if(str == "Locked"){
                if(Plush_Locked == FALSE){
                    llPlaySound(plush_lock_snd,1);
                }
                Lock();
                Timer_Running = TRUE;
            }
            else if(str == "Timer_Stop"){
                Timer_Running = FALSE;
            }
            else if(str == "Unlock"){
                llSetTimerEvent(0);
                Unlock();
                Pet = NULL_KEY;
                LockB = "Lock";
                Timerb = "-";
            }
        }
    }
    
    changed(integer change){
        if (change & CHANGED_LINK){
            if (linkCount!=llGetObjectPrimCount(llGetKey())){
                llOwnerSay("Linked prim have changed.  Resetting.");
                kennelReset();
            }
            if (llAvatarOnLinkSitTarget(poseballlink)!=NULL_KEY){
                if (llListFindList(AllowedPets, [(string)llAvatarOnLinkSitTarget(poseballlink)]) != (integer)-1){
                    llMessageLinked(LINK_SET, SENSOR, "getKeys", NULL_KEY);
                    LastSitter = llAvatarOnLinkSitTarget(poseballlink);
                    llSleep(1); //If lock or makeplush fails to work, try added this pause. Unknown why it's hit or miss without it.
                    MakePlush();
                }
                else{
                    llInstantMessage(llAvatarOnLinkSitTarget(poseballlink), "You do not belong here. Unsitted.");
                    llUnSit(llAvatarOnLinkSitTarget(poseballlink));                    
                }
            }
            else if (HasPlushPresent==TRUE && Plush_Locked==FALSE && llListFindList(AllowedPets, [(string)LastSitter]) != (integer)-1){
                Unplush();
            }
        }
    }
}