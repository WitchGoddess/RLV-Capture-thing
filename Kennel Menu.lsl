//-----Link Channels-----//
integer DOOR_BUTTON     = 11008;
integer TIMER           = 11009;
integer RCV_TIMER       = 11010;
integer RLV             = 11012;
integer RLV_BACK        = 11013;
integer KEY_LIST        = 11014;

integer SENSOR          = 136;
integer KEY             = 1151;
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

string displayTime;

integer menuChannel;
integer captureChannel;
integer channelSetter;

integer PetAccess = TRUE;
integer Kennel_Locked = FALSE;
integer Kennel_Closed = FALSE;
list PetKeys;

string MSG_SEP = "^";
integer Seconds = 60;
string PingFromRelay;
key ownerk;
string OwnerB = "-";
string ToyModeB = "Un-Toymode";
string LockB = "-";
string Timerb = "-";
string Keysb = "-";
string InvisB="-";
key hasKey_key;
string hasKey;

integer Key_Taken = FALSE;
integer Timer_Running = FALSE;
integer lockedOut = FALSE;
integer Sub_lockedOut = FALSE;

list rlv;
list sensor_keys;
list sensor_names;
key door_operator = NULL_KEY;
key petkey = NULL_KEY;
integer linkCount;

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
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
    list KennelMenu = [ToyModeB, LockB, OwnerB, Keysb, Timerb, "Capture", InvisB];
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
    ToyModeB = "Un-Toymode";
    LockB = "Lock";
    Timerb = "Timer";
    Kennel_Locked = FALSE;
    Timer_Running = FALSE;
    lockedOut = FALSE;
    Sub_lockedOut = FALSE;
    PetAccess = TRUE;
    Key_Taken = FALSE;
    hasKey_key = NULL_KEY;
    hasKey = "";
    Keysb = "-";
    llPlaySound(door_unlock,1);
    llMessageLinked(LINK_SET, TIMER,"Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, SENSOR, "OFF", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, DOOR_BUTTON, "Unlock", NULL_KEY);
    llMessageLinked(LINK_SET, KEY, "key_hidden", NULL_KEY);
}

lock(){
    ToyModeB = "-";
    LockB = "Unlock";
    Timerb = "Timer";
    if (Kennel_Locked==FALSE) llPlaySound(door_lock,1);
    Kennel_Locked = TRUE;
    PetAccess = FALSE;
    llMessageLinked(LINK_SET, SENSOR, "ON", NULL_KEY);
    llMessageLinked(LINK_SET, RLV, "Lock", NULL_KEY);
    llMessageLinked(LINK_SET, DOOR_BUTTON, "Lock", NULL_KEY);
    if(Key_Taken == FALSE){
        Keysb = "Take Key";
        Key_Taken = FALSE;
        hasKey_key = NULL_KEY;
        hasKey = "";
        llMessageLinked(LINK_SET, KEY, "key_available", NULL_KEY);
    }
}

capture(string name){
    integer index = llListFindList(sensor_names, [name]);
    if (index != -1){
        key sensorKey = llList2Key(sensor_keys, index);
        integer poseballlink = getLinkWithName("cageframe");
//        relay(sensorKey, "@sit:" + (string)llGetKey() + "=force");
        relay(sensorKey, "@sit:" + (string)llGetLinkKey(poseballlink) + "=force");
        ToyModeB = "Un-Toymode";
        Timerb = "Timer";
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
        llMessageLinked(LINK_SET, DOOR_BUTTON, "Unlock", NULL_KEY);
        llMessageLinked(LINK_SET, DOOR_BUTTON, "ToyMode", NULL_KEY);
        llMessageLinked(LINK_SET, KEY, "key_hidden", NULL_KEY);
        llOwnerSay("Cage Reset");
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
                        llInstantMessage(llDetectedKey(0), "You try to move but find yourself completely inanimate. Owner test DEBUG");
                        if(Timer_Running == TRUE){
                            llWhisper(0,"You will become animated again once timer expires. Owner test DEBUG");
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
                        llInstantMessage(llDetectedKey(0), "You try to move but find yourself completely inanimate. Not Owner test DEBUG");
                        if(Timer_Running == TRUE)
                        {
                            timer_check();
                            llWhisper(0,"You will become animated again once timer expires. Not Owner test DEBUG");
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
            else if(command == "ToyMode"){
                ToyModeB = "Un-Toymode";
                LockB = "Lock";
                Timerb = "Timer";
                llMessageLinked(LINK_SET, SENSOR, "getKeys", NULL_KEY);
                llMessageLinked(LINK_SET, DOOR_BUTTON, "ToyMode", NULL_KEY);
                dialogMenu(door_operator);
            }
            else if(command == "Un-ToyMode"){
                PetKeys = [];
                ToyModeB = "Toymode";
                LockB = "-";
                Timerb = "-";
                Keysb = "-";
                llMessageLinked(LINK_SET, SENSOR, "OFF", NULL_KEY);
                llMessageLinked(LINK_SET, DOOR_BUTTON, "Un-ToyMode", NULL_KEY);
                dialogMenu(door_operator);
            }
            else if(command == "Lock"){
                llInstantMessage(door_operator,"Touch the plush again for Lock, Timer and Key options.");
                lock();
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
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id){
        if(num == SENSOR){
            list pets = llParseString2List(str, [","], []);
            string command = llList2String(pets, 0);
            key newPet1 = llList2Key(pets, 1);
            key newPet2 = llList2Key(pets, 2);
            key newPet3 = llList2Key(pets, 3);
            key newPet4 = llList2Key(pets, 4);
            
            if(command == "add"){
                PetKeys += [newPet1];
            }
            else if(command == "remove"){
                integer rc = llListFindList(PetKeys, [newPet1]);
                {
                    if(rc != (integer)-1)
                    {
                        llShout(RELAY_CHANNEL, "BunchoCommands,"+(string)newPet1+",!release");
                        PetKeys=llDeleteSubList(PetKeys, rc, rc);
                    }
                }
            }
            else if(command == "escaped"){
                list pets = llParseString2List(str, [","], []);
                string command = llList2String(pets, 0);
                key escapee = llList2Key(pets, 1);
                
                string escaped_pet = llKey2Name(escapee);
                
                if(Key_Taken == TRUE){
                    llInstantMessage(hasKey_key,escaped_pet + " has escaped.");
                }
            }
        }
        else if(num == KEY_LIST){
            PetKeys = llParseString2List(str, [","], []);
        }
        else if(num == RLV_BACK){
            if(str == "Return_From_RLV"){
                dialogMenu(door_operator);
            }
        }
        else if(num == RCV_TIMER){
            list messageList = llParseString2List(str, [MSG_SEP], []);
            string command = llList2String(messageList, 0);
            string recievedInfo = llList2String(messageList, 1);
            if(str == "Return_From_Timer"){
                dialogMenu(door_operator);
            }
            else if(str == "Owner_Locked"){
                integer rc = llListFindList(PetKeys, [ownerk]);
                if(rc == (integer)-1){
                    lockedOut = TRUE;
                }
                if(Kennel_Locked == FALSE){
                    llPlaySound(door_lock,1);
                }
                lock();
                Timer_Running = TRUE;
            }
            else if(str == "Sub_Locked"){
                integer rc = llListFindList(PetKeys, [door_operator]);
                if(rc == (integer)-1){
                    Sub_lockedOut = TRUE;
                }
                if(Kennel_Locked == FALSE){
                    llPlaySound(door_lock,1);
                }
                lock();
                Timer_Running = TRUE;
            }
            else if(str == "Timer_Stop"){
                Timer_Running = FALSE;
            }
            else if(str == "Unlock"){
                llSetTimerEvent(0);
                Unlock();
                PetKeys = [];
                ToyModeB = "Toymode";
                LockB = "-";
                Timerb = "-";
                llMessageLinked(LINK_SET, DOOR_BUTTON, "Un-ToyMode", NULL_KEY);
            }
        }
    }
    
    changed(integer change){
        integer poseballlink = getLinkWithName("cageframe");
        if (change & CHANGED_LINK){
            if (linkCount!=llGetObjectPrimCount(llGetKey())){
                llOwnerSay("Linked prim have changed.  Resetting.");
                kennelReset();
            }
//            if (llAvatarOnLinkSitTarget(LINK_ROOT)!=NULL_KEY){
            if (llAvatarOnLinkSitTarget(poseballlink)!=NULL_KEY){
                llMessageLinked(LINK_SET, SENSOR, "getKeys", NULL_KEY);
                llSleep(0.5);
                llMessageLinked(LINK_SET, DOOR_BUTTON, "ToyMode", NULL_KEY);        
                lock();
                llUnSit(llAvatarOnLinkSitTarget(LINK_ROOT));
            }
        }
    }
}
