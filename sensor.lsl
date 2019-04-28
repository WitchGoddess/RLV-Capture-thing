integer RELAY_CHANNEL   = -1812221819;
integer SENSOR          = 136;
integer TIMER           = 11009;
integer BACK            = 11010;
integer RLV             = 11012;
integer PetKey_Chan     = 11014;
integer DOOR_BUTTON     = 11008;

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

integer poseballlink;

integer getLinkWithName(string name) {
    integer i = llGetLinkNumber() != 0;   // Start at zero (single prim) or 1 (two or more prims)
    integer x = llGetNumberOfPrims() + i; // [0, 1) or [1, llGetNumberOfPrims()]
    for (; i < x; ++i)
        if (llGetLinkName(i) == name) 
            return i; // Found it! Exit loop early with result
    return 0; // No prim with that name, return -1.
}

posCheck(){
    if(Pet != NULL_KEY){
        if(TimerRunning == "Running"){
            if(PetStatus == (integer)-1){
                llMessageLinked(LINK_SET, TIMER, "Pause", NULL_KEY);
                llWhisper(0,"Timer Paused.");
                TimerRunning = "Paused";
            }
        }
        else if(TimerRunning == "Paused"){
            if(PetStatus != (integer)-1){
                llMessageLinked(LINK_SET, TIMER, "Resume", NULL_KEY);
                llWhisper(0,"Timer Resumed.");
                TimerRunning = "Running";
            }
        }
    }
    integer x;
    TempPet = NULL_KEY;
    TempPet = Pet;
    TempPetStatus = PetStatus;
        string name = llKey2Name(Pet);

        if(PetStatus == STATUS_NORMAL){
            if(llAvatarOnLinkSitTarget(poseballlink) == Pet){}
            else{
                llSleep(5.0);
                RequestID += [llRequestAgentData(Pet, DATA_ONLINE)];
                RequestAV += [Pet];
            }
        }
        else if(PetStatus == STATUS_OFFLINE){
            RequestID += [llRequestAgentData(Pet, DATA_ONLINE)];
            RequestAV += [Pet];
        }
        else if(PetStatus == STATUS_ESCAPED){   
            vector pos = llList2Vector(llGetObjectDetails(Pet,[OBJECT_POS]), 0);
            vector zeroPos = <0.00000, 0.00000, 0.00000>;
            petLoc = pos;
            pos = (pos - llGetRootPosition()) / llGetRootRotation();
            
            if(llAvatarOnLinkSitTarget(poseballlink)){
                llSay(0,name+" has been put back where it belongs.");
                TempPetStatus = 0;
            }
            else{
                if(pos == zeroPos){
                    llMessageLinked(LINK_SET, SENSOR, "escaped," + (string)Pet, NULL_KEY);
                    llInstantMessage(Pet, "You have broken free from your toymode.");
                    llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet+",!release");
                    TempPet=NULL_KEY;
                    TempPetStatus=-1;
                }
                else{
                    llRegionSay(RELAY_CHANNEL, "BunchoCommands,"+(string)Pet + ","+ "@sit:" + (string)llGetLinkKey(poseballlink) + "=force");
                }
            }
        }
    
    PetStatus = TempPetStatus;
    TempPetStatus = -1;
    Pet = NULL_KEY;
    Pet = TempPet;
    TempPet = NULL_KEY;
    llMessageLinked(LINK_SET, PetKey_Chan, (string)Pet, NULL_KEY);
}

getKeys(){
    Pet = NULL_KEY;
    PetStatus = -1;
    if (llAvatarOnLinkSitTarget(poseballlink)!=NULL_KEY){
        Pet = llAvatarOnLinkSitTarget(poseballlink);
        PetStatus = 0;
        //string name = llKey2Name(Pet);
        //llWhisper(0,name+" is zipped up into the plush!"); //Moved this text to when 'makeplush' happens so it doesn't go off every time pet comes online or escapes.
    }
    llMessageLinked(LINK_SET, PetKey_Chan, (string)Pet, NULL_KEY);
}

key TempPet;
integer TempPetStatus;

key Pet;
integer PetStatus;

default{
    state_entry(){
        poseballlink = getLinkWithName("Plush");
        llSleep(1);
        //llLinkSitTarget(poseballlink,<0.0,0.0,0.5>,ZERO_ROTATION); //Use this if not using a different sitting script
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
                getKeys();
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
        if(Pet == NULL_KEY){
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
                    if(Pet != NULL_KEY){
                        PetStatus = 2;
                    }
                }
                else{
                    message += "offline";
                    if(Pet != NULL_KEY){
                        PetStatus = 1;   
                    }
                }
                RequestID = llDeleteSubList(RequestID, x, x);
                RequestAV = llDeleteSubList(RequestAV, x, x);
                jump done;
            }
        }
        @done;
    }
}
