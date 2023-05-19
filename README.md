# Minecraft-Aim-Assisted-Ship-Controller-ValkyrienSkies2-ComputerCraft

[Download the Map and Mod pack From PlanetMinecraft](https://www.planetminecraft.com/project/ms-glare-the-lens-flare-valkyrien-skies-2-create-computercraft/)

## Ms. Glare The LENS-FLARE
[YouTube Video](https://youtu.be/taD_ttDTe9o)

![2023-05-15_18 24 47](https://github.com/19PHOBOSS98/Minecraft-Aim-Assisted-Ship-Controller-ValkyrienSkies2-ComputerCraft/assets/37253663/005d3817-2475-418b-8ec3-4b74fe054505)



This was based on my last project:
[Minecraft-Omnidirectional-Drone-Controller](https://github.com/19PHOBOSS98/Minecraft-Omnidirectional-Drone-Controller-ValkyrienSkies2-ComputerCraft)

As good as a fighter Mr. Grin is, I needed Sol to have her own themed fighter-crafts. I started off trying to give Ms. Glare something like a "plane-mode" to complement her default "VTOL-mode"

...I didn't like it.


While I was looking for a good background music to sync to for her showcase video I found Cayote Kisses' banger of a song called [Six Shooter](https://youtu.be/Y2shDoIBJIs)

(GO CHECK IT OUT!)

So... that's why I spent the whole week coding in an Auto-Targeting system for her :)

## FEATURES

### AUTO-TARGETING
She can account for target velocity and lead her aim. 

If her target is out of range she automatically switches to the next. 

Her radar range is set to 500 blocks.

If she can't find any ships within the radar range she automatically turns off auto-targetting

### ORBIT MODE
In addition to the Auto-Targeting feature, she also has an ORBIT mode. Instead of staying in place and "glaring" at her targets she can maintain a set distance between them. 

With the ORBIT mode she can literally run circles around you. 

Try and fly away, she will follow. Stop to rest, she will wait right there with you...

## The Handicaps That I Had To Overcome
### CBC:AUTOCANNON BULLET VELOCITY
So to get it to aim right, I needed to know how fast the Create:Autocannon projectiles travel. After digging thru the addon's code and asking around Reddit:
[I made a post](https://www.reddit.com/r/feedthebeast/comments/13iqmys/whats_the_createbig_cannons_projectile_speed/)

I found out that:

`Autocannon_projectile_velocity = barrel_length/minecraft_tick`

(minecraft_tick = 0.05sec)

I also found that Autocannon projectiles don't experience the effects of gravity or drag so they travel in a straight line without slowing down.

## NOTES
ValkyrienSkies2:Computers adds a peripheral called a [Ship Radar](https://github.com/TechTastic/ValkyrienComputers/wiki/Ship-Radar). As the name suggests, I used it along with Create:BigCannons' Autocannons to get this to work.

You might notice that the aim drifts a bit while orbiting a target... I think this has to do with the way I set Ms. Glare's PID gains (I haven't set the Integral gains). For now I'm happy with how she came out :)

## Prerequisits
You might need to read up on these topics before diving in the code. Here are some videos that should help you get started:

  +Quaternions: https://youtu.be/1yoFjjJRnLY
  
  +Inertia Tensors: https://youtu.be/SbTSATs-DBA
  
  +PWM Signals: https://youtu.be/B_Ysdv1xRbA
  
  +PID Controller for Lua: https://youtu.be/K4sHec1qGKg
  
  
## A Few Things To Note Before Using The Schematics and World Save

### **!!!!USE AT YOUR OWN RISK, MAKE BACK UPS!!!!**

Prepare the game to use atleast **12GB** of RAM by setting the JVM Arguments in the Minecraft Launcher

### COMPUTERCRAFT FOLDERS

Folder 0: For the Wireless Pocket Computer.

Folder 4: For the Create Link Controller setup (0scorcher_remote_armed.nbt)

Folder 11: For the main onboard computer


### PRE-"SHIP ASSEMBLY" CHECKS
1. Make sure to set the Thruster Speed to 55000 in the VS2-Tournament Mod Config Settings (this is specifically for Lens-Flare).
2. Disable the block-black-list over at the VS2-Eureka mod config settings (or whichever VS2 addon that has an assembler block that you use to assemble ships with). 
3. Build Create schematic as is. Do NOT rotate or mirror the schematics.
4. Disable Create: Autocannon Contraption before assembling as a VS2 ship (this will break the glass wings and a few thrusters).
5. Replenish cannon ammo if needed.
6. I usually just go for a VS2-Eureka Ship Helm to assemble a ship but the other addons' assembler blocks should work just as fine.

### POST-"SHIP ASSEMBLY" CHECKS
1. Reassemble the Autocannon contraption along with the bits that where broken off in the process in the PRE-"SHIP ASSEMBLY" CHECKS.
2. Make sure the VS2-Tournament thrusters are all upgraded to level *2* thrusters.
3. Turn on the cable-modems on the redstone integrators (0scorcher_remote_armed.nbt).
4. Spin the hand cranks to make them look like handle bars.

### PREFLIGHT CHECKS
1. Run `remote.lua` on the Create-Link Controller setup (0scorcher_remote_armed.nbt) and grab the Link Cotroller
2. Prepare to run `reset.lua` on the Wireless Pocket Computer. This should reset the craft thrusters and reboot the main onboard computer if anything goes wrong
3. Prepare a VS2-Eureka Ship Helm on hand. Placing it on a ship forces it to stop freaking out if anything goes wrong 
4. Run `flight_control_firmware_lens_flare.lua` on the main onboard computer
5. Fly

### POSTFLIGHT CHECKS
**THIS IS IMPORTANT TO DO BEFORE LOGGING OFF**
1. After flying, run `reset.lua` on your Wireless Pocket Computer to shutoff the thrusters and stop the main script. 

    CC:Computers turnoff when the player exits the world. Upon logging back in, the onboard computers would be turned off but the Redstone Integrator peripherals would retain their last redstone settings and inturn would still be powering the thrusters.
    
    If this ever happens, the Lens-Flare would start flying off by itself when you log in.
    
    At the very least quickly prepare a VS2-Eureka Ship Helm to calm the ship down.
    
## CONTROLS
```
space   - up
shift   - down
w,a,s,d - forward,left,backward,right

space+a - yaw left
space+d - yaw right
space+w - pitch forward
space+s - pitch back
shift+a - roll left
shift+d - roll right

a+w+space - drift left
d+w+space - drift right
a+s+space - drift left backwards
d+s+space - drift right backwards

shift+space+w - cannons burst

shift+space+a+d+w - auto-target mode
shift+space+a/d - scroll-through-targets
shift+space+a+d+s - orbit mode

ORBIT MODE:
w   - up around target
s   - down around target
a,d - left, right around target
space - close the distance from target
shift - back off from target

```

### RELEVANT MODS:

**Valkyrien Skies:**
```
valkyrienskies-118-forge-2.1.0-beta.125a40781d5d (Valkyrien Skies 2 Core)

vc-1.5.2+2090972a50 (Valkyrien Skies 2-Computers)

eureka-1.1.0-beta.8 (Valkyrien Skies 2-Eureka)

takeoff-forge-1.0.0-beta1+308678c5c5 (Valkyrien Skies 2-Takeoff)

tournament-forge-1.0.0-beta3-0.6+f5dce4613f (Valkyrien Skies 2-Tournament)

Clockwork_Pre-Alpha_Patch_1.3c_FORGE (Valkyrien Skies 2-Clockwork)
```

**Create:**
```
create-1.18.2-0.5.0.i (Create Core)

createbigcannons-forge-1.18.2-0.5.1.a-nightly-1c78f14 (Create Big Cannons)
```

**ComputerCraft:**
```
cc-tweaked-1.18.2-1.101.2 (ComputerCraft Tweaked)

AdvancedPeripherals-0.7.27r (ComputerCraft Advanced Peripherals)
```
