**###### T1GER_MECHANICJOB MODIFIED BY JERICOFX#3512**

------------

if you think that my time deserve a coffe

buymeacoff.ee/jericofx

------------
###Why the obfuscation? 

 * Some 6 year old babys are claming this code and selling this for a really high price, so i obfuscate most part of the code and print stuff in the console just to tell the other people that this resource is free.


------------------------------------------------------------------

Take from the original resource and modified to work with Qbus based servers, almost everything is working like:
and if you don´t like it, don´t use it.
- Menu with command so you can Bind it.
- Buy, Rename, Shell shop
- Lift
- Crafting etc etc...

# IMPORTANT INFORMATION

I found a fix to the Nil values in the server console, it happend because when we are in the selection menu, the resource want an id, at that momento we dont have that, so the fix i found is going to the rs-spawn (qb-spawn) in this part https://prnt.sc/wdv3av  put the trigger event in this case is   TriggerEvent("t1ger_mechanicjob:getPlayerIden") like the image.


https://streamable.com/72f96d

To install this resource you need:

if you use a Custom based QBCore like me just change FXCore to .........

Modify Config.Core  = " " to match your version

MenuV from Tigo https://github.com/ThymonA/menuv

Run this SQL code : 
> CREATE TABLE t1ger_mechanic ( identifier varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL, shopID INT(11), name varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT "Mechanic Shop", money INT(11) NOT NULL DEFAULT 0, employees longtext NOT NULL DEFAULT '[]', storage longtext NOT NULL DEFAULT '[]', PRIMARY KEY (shopID) );

ALTER TABLE player_vehicles ADD health longtext NOT NULL DEFAULT '[{"value":100,"part":"electronics"},{"value":100,"part":"fuelinjector"},{"value":100,"part":"brakes"},{"value":100,"part":"radiator"},{"value":100,"part":"driveshaft"},{"value":100,"part":"transmission"},{"value":100,"part":"clutch"}]';

this will add a Heath table to the player_vehicles
- Need to add the items to the Share.lua

1. 	["car_door"] 		 			 = {["name"] = "car_door", 						["label"] = "Car Door", 				["weight"] = 5000, 		["type"] = "item", 		["image"] = "c4.png", 					["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = "A door from a car, no idea what you can do..."},

1. "car_hood"] 		 			 = {["name"] = "car_hood", 						["label"] = "Car Hood", 				["weight"] = 5000, 		["type"] = "item", 		["image"] = "c4.png", 					["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = "A Hood from a car, no idea what you can do..."},
	
1. ["car_trunk"] 		 			 = {["name"] = "car_trunk", 					["label"] = "Car Trunk", 				["weight"] = 5000, 		["type"] = "item", 		["image"] = "c4.png", 					["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = "A Trunk from a car, no idea what you can do..."},
	
1. ["car_wheel"] 					 = {["name"] = "car_wheel", 					["label"] = "Car Wheel", 				["weight"] = 5000, 		["type"] = "item", 		["image"] = "c4.png", 					["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = "A Wheel from a car, no idea what you can do..."},
	


No copyright, but appreciate if you give me credit for the work, it take me a lot of time to make it work.
Know Issues:

- Sometimes a restart resource is required to "recognize owner"
---------------
* ##Credits to the notification fix Omen#1072!!! 
* ##https://discord.gg/N3tWXBRyu6

------------

- I dont know if is a MenuV error or mine but if you craft, deposit money, or store items you need to close the menu and re-open to see the change (cannot be exploited because is the menu who doest update the value.)

REMEMBER THIS IS A WORK IN PROGRESS SO EXPECT SOME BUGS

All the credits go to T1ger, if you are the owner please contact me and i will delete it.

(Kids from certain framework that claim this is his work, prove it!)