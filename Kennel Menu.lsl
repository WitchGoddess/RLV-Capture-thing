//-----Link Channels-----//
integer DOOR_BUTTON     = 11008;
integer TIMER           = 11009;
integer RCV_TIMER       = 11010;
integer RLV             = 11012;
integer KEY_LIST        = 11014;
integer SENSOR          = 136;
//-------------------------//

integer RANGE_CAPTURE   = 20;

//-----Channels-----//
integer MENU_CH         = 0;
integer RELAY_CHANNEL   = -1812221819;
integer CAPTURE_CHANNEL = 0;
//-------------------//

// Sound UUIDs //
key door_lock="4a23b467-2e4d-d783-3643-6fe1fe4eb179";
key door_unlock="e5e01091-9c1f-4f8c-8486-46d560ff664f";

// HardCoded list of allowed pets //
list AllowedPets = [(key)UUID of pet, (key)UUID of pet]

string displayTime;

integer menuChannel;
integer captureChannel;

integer PetAccess = TRUE;
integer Kennel_Locked = FALSE;
integer HasPlushPresent = FALSE;
list PetKeys;

string MSG_SEP = "^";
integer Seconds = 60;
string PingFromRelay;
key ownerk;
string OwnerB = "-";
string LockB = "-";
string Timerb = "-";
string Keysb = "-";
string InvisB="-";
string UnSitB="-";
key hasKey_key;
string hasKey;

integer Key_Taken = FALSE;
integer Timer_Running = FALSE;

list rlv;
list sensor_keys;
list sensor_names;
key door_operator = NULL_KEY;
integer linkCount;

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

integer poseballlink = getLinkWithName("Plush");

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
    list KennelMenu = [LockB, OwnerB, Keysb, Timerb, "Capture", InvisB, UnsitB];
    llDialog(door_operator, "Plush Toy Control Menu:\n\n(Menu will Timeout in 60 Seconds.)", KennelMenu, MENU_CH);
}

ownerMenu(key door_operator){
    MENU_CH = 0;
    channelMaker2();
    llListenRemove(menuChannel);
    llListenRemove(captureChannel);
    menuChannel = llListen( MENU_CH, "", door_operator, "");
    menuChannel = llListen ( CAPTURE_CHANNEL, "", door_operator, "");
    list OwnerMenu = ["Reset","Back..."];
    llDialog(door_operator, "Plush Toy Control Menu:.", OwnerMenu, MENU_CH);
}

Unlock(){
    LockB = "Lock";
    Timerb = "Timer";
    Kennel_Locked = FALSE;
    Timer_Running = FALSE;
    PetAccess = TRUE;
    Key_Taken = FALSE;
    hasKey_key = NULL_KEY;
    hasKey = "";
    Keysb = "-";
    UnSitB="UnPlush";
    llPlaySound(door_unlock,1);
    llMessageLinked(LINK_SET, TIMER,"Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, SENSOR, "OFF", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Unlock", NULL_KEY);
}

Lock(){
    LockB = "Unlock";
    Timerb = "Timer";
    UnSitB="UnPlush";
    if (Kennel_Locked==FALSE) llPlaySound(door_lock,1);
    Kennel_Locked = TRUE;
    PetAccess = FALSE;
    llMessageLinked(LINK_SET, SENSOR, "ON", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Lock", NULL_KEY);
    if(Key_Taken == FALSE){
        Keysb = "Take Key";
        Key_Taken = FALSE;
        hasKey_key = NULL_KEY;
        hasKey = "";
        llMessageLinked(LINK_SET, KEY, "key_available", NULL_KEY);
    }
}

MakePlush(){
    llMessageLinked(LINK_SET, RLV, "Plush", NULL_KEY);
    HasPlushPresent = TRUE;
}

Unplush(){
    UnSitB="-";
    llMessageLinked(LINK_SET, RLV, "UnPlush", NULL_KEY);
    llUnSit(llAvatarOnLinkSitTarget(poseballlink));
    HasPlushPresent = FALSE;
}

capture(string name){
    integer index = llListFindList(sensor_names, [name]);
    if (index != -1){
        key sensorKey = llList2Key(sensor_keys, index);
        relay(sensorKey, "@sit:" + (string)llGetLinkKey(poseballlink) + "=force");
        Timerb = "Timer";
        UnSitB="-";
    }
}

relay(key avatar, string message){
    llSay(RELAY_CHANNEL, llGetObjectName() + "," + (string) avatar + "," + message);
}

makeInvis(){
    float alpha=llList2Float(llGetLinkPrimitiveParams(5,[PRIM_COLOR,0]),1);
    if (alpha==0.0) llSetLinkAlpha(5,1,0);
    else llSetLinkAlpha(5,0,0);
}

default{
    on_rez(integer p){
        llResetScript();
    }
    
    state_entry(){
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
                integer rc = llListFindList(PetKeys, [(string)ownerk]);
                if(rc == (integer)-1){
                    door_operator = llDetectedKey(0);
                    dialogMenu(door_operator);
                }
                else{
                    if(Kennel_Locked == TRUE)                        {
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
                integer pet = llListFindList(PetKeys, [(string)llDetectedKey(0)]);
                if(pet != (integer)-1){
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
            else if (command == "Invis"){
                makeInvis();
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
                llMessageLinked(LINK_SET, KEY, "key_taken", NULL_KEY);
                llMessageLinked(LINK_SET, RLV, "key_taken" + "^" + (string)door_operator, NULL_KEY);
                llWhisper(0,name + " has taken the key, only them or the owner can unlock it now (or if a timer is set, it will auto-unlock when the timer expires.)");
                Key_Taken = TRUE;
                Keysb = "Return Key";
                dialogMenu(door_operator);
            }
            else if(message == "Return Key"){
                string name = llKey2Name(door_operator);
                llMessageLinked(LINK_SET, KEY, "key_available", NULL_KEY);
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
            else if(message == "Timer"){
                llMessageLinked(LINK_SET, TIMER,"Timer" + MSG_SEP + (string)door_operator, NULL_KEY);
            }
            else if(command == "UnPlush"){
                Unlock();
                llSleep(1);
                Unplush();
            }
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id){
        if(num == SENSOR){
            list pets = llParseString2List(str, [","], []);
            string command = llList2String(pets, 0);
            else if(command == "escaped"){
                list pets = llParseString2List(str, [","], []);
                string command = llList2String(pets, 0);
                key escapee = llList2Key(pets, 1);
                
                string escaped_pet = llKey2Name(escapee);
                
                if(Key_Taken == TRUE){
                    llInstantMessage(hasKey_key,escaped_pet + " has escaped!");
                }
            }
        }
        else if(num == KEY_LIST){
            PetKeys = llParseString2List(str, [","], []);
        }
        else if(num == RCV_TIMER){
            list messageList = llParseString2List(str, [MSG_SEP], []);
            string command = llList2String(messageList, 0);
            string recievedInfo = llList2String(messageList, 1);
            if(str == "Return_From_Timer"){
                dialogMenu(door_operator);
            }
            else if(str == "Locked"){
                if(Kennel_Locked == FALSE){
                    llPlaySound(door_lock,1);
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
                PetKeys = [];
                LockB = "-";
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
                if (llAvatarOnLinkSitTarget(poseballlink) == llListFindList(AllowedPets,llAvatarOnLinkSitTarget(poseballlink)){
                    llMessageLinked(LINK_SET, SENSOR, "getKeys", NULL_KEY);
                    MakePlush();
                    Lock();
                }
                else{
                    llUnSit(llAvatarOnLinkSitTarget(poseballlink))
                    llWhisper(0,"Debug: "+name+" does not belong here. Unsitted.");
                }
            }
            else if (HasPlushPresent==TRUE){
                Unplush();
            }
        }
    }
}