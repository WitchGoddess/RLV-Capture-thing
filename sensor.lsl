integer RELAY_CHANNEL   = -1812221819;
integer SENSOR          = 136;
integer TIMER           = 11009;
integer BACK            = 11010;
integer RLV             = 11012;
integer KEY_LIST        = 11014;

integer STATUS_NORMAL   = 0;
integer STATUS_OFFLINE  = 1;
integer STATUS_ESCAPED  = 2;
string  TimerRunning    = "Stopped";
float   timerTick       = 2;

list RequestID;
list RequestAV;

key primForce = NULL_KEY;
vector petLoc;
vector offset = <0.0,0.0,1.0>;

vector upperRight;
vector lowerLeft;

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return -1; // No prim with that name, return -1.
}

posCheck(){
    integer length = llGetListLength(PetKeys);
    if(length != (integer)0){
        if(TimerRunning == "Running"){
            integer AVStat = llListFindList(PetStatus, [0]);
            if(AVStat == (integer)-1){
                llMessageLinked(LINK_SET, TIMER, "Pause", NULL_KEY);
                llWhisper(0,"Timer Paused.");
                TimerRunning = "Paused";
            }
        }
        else if(TimerRunning == "Paused"){
            integer AVStat = llListFindList(PetStatus, [0]);
            if(AVStat != (integer)-1){
                llMessageLinked(LINK_SET, TIMER, "Resume", NULL_KEY);
                llWhisper(0,"Timer Resumed.");
                TimerRunning = "Running";
            }
        }
    }
    integer x;
    TempPetKeys = [];
    TempPetStatus = [];
    TempPetKeys = PetKeys;
    TempPetStatus = PetStatus;
    
    for (x = 0; x < length; x++){
        key Pet = llList2Key(PetKeys, x);
        string name = llKey2Name(Pet);
        integer status = llList2Integer(PetStatus, x);
        
        if(status == STATUS_NORMAL){
            vector pos = llList2Vector(llGetObjectDetails(Pet,[OBJECT_POS]), 0);
            pos = (pos - llGetRootPosition()) / llGetRootRotation();
            
            if(pos.x > lowerLeft.x && pos.x < upperRight.x &&
               pos.y > lowerLeft.y && pos.y < upperRight.y &&
               pos.z > lowerLeft.z && pos.z < upperRight.z){}
            else{
                llSleep(5.0);
                RequestID += [llRequestAgentData(Pet, DATA_ONLINE)];
                RequestAV += [Pet];
            }
        }
        else if(status == STATUS_OFFLINE){
            RequestID += [llRequestAgentData(Pet, DATA_ONLINE)];
            RequestAV += [Pet];
        }
        else if(status == STATUS_ESCAPED){
            vector pos = llList2Vector(llGetObjectDetails(Pet,[OBJECT_POS]), 0);
            vector zeroPos = <0.00000, 0.00000, 0.00000>;
            petLoc = pos;
            pos = (pos - llGetRootPosition()) / llGetRootRotation();
            
            if(pos.x > lowerLeft.x && pos.x < upperRight.x &&
               pos.y > lowerLeft.y && pos.y < upperRight.y &&
               pos.z > lowerLeft.z && pos.z < upperRight.z){
                llMessageLinked(LINK_SET, RLV, "Relock" + "^" + (string)Pet, NULL_KEY);
                llWhisper(0,"Debug: Sent: Relock" + "^ " + (string)Pet);
                llWhisper(0,"Debug: Relock trigger sent"); 
                llWhisper(0,name+" is put back where it belongs.");
                TempPetStatus = llListReplaceList(TempPetStatus, [0], x, x);
            }
            else{
                if(pos == zeroPos){
                    llMessageLinked(LINK_SET, SENSOR, "escaped," + (string)Pet, NULL_KEY);
                    llInstantMessage(Pet, "You have broken free from your toymode.");
                    llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet+",!release");
                    TempPetKeys=llDeleteSubList(TempPetKeys, x, x);
                    TempPetStatus=llDeleteSubList(TempPetStatus, x, x);
                }
                else{
//                    llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ "@sit:" + (string)llGetLinkKey(LINK_ROOT) + "=force");
                    integer poseballlink = getLinkWithName("cageframe");
                    llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ "@sit:" + (string)llGetLinkKey(poseballlink) + "=force");
                    llWhisper(0,"Debug: Sit triggered"); 
                }
            }
        }
    }
    
    PetStatus = [];
    PetStatus = llList2List(TempPetStatus,0,-1);
    TempPetStatus = [];
    PetKeys = [];
    PetKeys = llList2List(TempPetKeys,0,-1);
    TempPetKeys =[];
    llMessageLinked(LINK_SET, KEY_LIST, llDumpList2String(PetKeys, ","), NULL_KEY);
}

setBox(){
    llSleep(1);
    list box = llGetBoundingBox(llGetKey());
    upperRight = llList2Vector(box,1);
    lowerLeft =  llList2Vector(box,0);
//    llSitTarget(ZERO_VECTOR,ZERO_ROTATION);
    integer poseballlink = getLinkWithName("cageframe");
//    llLinkSitTarget(LINK_ROOT,(upperRight+lowerLeft)/2,llEuler2Rot(<-90,0,0>*DEG_TO_RAD));
    offset=(upperRight+lowerLeft)/2;
}

list TempPetKeys;
list TempPetStatus;

list PetKeys;
list PetStatus;

default{
    state_entry(){
        setBox();
    }    
        
    on_rez(integer start_param){
        llResetScript();
    }
    
    link_message(integer sender_num, integer num, string str, key id){
        if(num == SENSOR){
            if(str == "ON"){
                llSetTimerEvent(timerTick);
            }
            else if(str == "OFF"){
                llSetTimerEvent(0);
            }
            else if(str == "getKeys"){
                llSensor("", NULL_KEY, AGENT, 20, PI);
            }
            else if(str == "TimerStarted"){
                TimerRunning = "Running";
            }
            else if(str == "TimerStopped"){
                TimerRunning = "Stopped";
            }
            
        }
    }
    
    timer(){
        integer length = llGetListLength(PetKeys);
        if(length == (integer)0){
            llWhisper(0,"There's no plush toy. Unlocking.");
            llSetTimerEvent(0);
            llMessageLinked(LINK_SET, SENSOR, "TimerStopped", NULL_KEY);
            llMessageLinked(LINK_SET, BACK, "Unlock", NULL_KEY); 
        }
        else{
            posCheck();
            llSetTimerEvent(timerTick);   
        }
    }
    
    dataserver(key queryid, string data){
        integer numRequests = llGetListLength(RequestID);
        integer x;

        for(x = 0; x < numRequests; x++){
            if(queryid == llList2Key(RequestID, x)){
                key AV = llList2Key(RequestAV, x);
                integer online = (integer)data;
                string message = llKey2Name(AV) + " is ";
                if(online){
                    message += "online";
                    list KeyofPet = [AV];
                    integer AVpos = llListFindList(PetKeys, KeyofPet);
                    if(AVpos != (integer)-1){
                        PetStatus = llListReplaceList(PetStatus, [2], AVpos, AVpos);
                    }
                }
                else{
                    message += "offline";
                    list KeyofPet = [AV];
                    integer AVpos = llListFindList(PetKeys, KeyofPet);
                    if(AVpos != (integer)-1){
                        PetStatus = llListReplaceList(PetStatus, [1], AVpos, AVpos);   
                    }
                }
                RequestID = llDeleteSubList(RequestID, x, x);
                RequestAV = llDeleteSubList(RequestAV, x, x);
                jump done;
            }
        }
        @done;
    }
    
    sensor(integer total_number){
        PetKeys = [];
        PetStatus = [];
        integer x;
        
        for (x = 0; x < total_number; x++){
            key Pet = llDetectedKey(x);
            vector pos = llList2Vector(llGetObjectDetails(Pet,[OBJECT_POS]), 0);
            pos = (pos - llGetRootPosition()) / llGetRootRotation();
            if(pos.x > lowerLeft.x && pos.x < upperRight.x &&
               pos.y > lowerLeft.y && pos.y < upperRight.y &&
               pos.z > lowerLeft.z && pos.z < upperRight.z){
                PetKeys += [llDetectedKey(x)];
                PetStatus += [0];
                string name = llKey2Name(Pet);
                llMessageLinked(LINK_SET, RLV, "Relock" + "^" + (string)Pet, NULL_KEY);
                llWhisper(0,"Debug: Sent: Relock" + "^ " + (string)Pet);
                llWhisper(0,"Debug: Relock trigger sent"); 
                llWhisper(0,name+" is back where it belongs.");
            }
        }
        llMessageLinked(LINK_SET, KEY_LIST, llDumpList2String(PetKeys, ","), NULL_KEY);
    }
}
