# Toshitba tools
Status: unmaintained, probably made obsolete by newer kernel versions

Tools for making a toshiba satellite usable.

I have the misfortune of owning a toshiba satellite l855d-s5242 and here you will find
some tools and instructions which I have discovered work for making it less of a steaming
pile of crap.

## snd_unfuck.sh
Occasionally toshitba decides that there should be quiet time and I lose access to my sound
card, this is a simple script which neuters and kills pulseaudio, then unloads and reloads
the sound module, then allows pulseaudio to start once again.

## therm_unfuck.sh
This script is the cumlination of a bizarre search for the cause of processor overheating
and system shutdown. Firstly, if you find a way to control the fan speed on one of these
utter wheelbarrowloads of garbage, please open an issue on this repository because I would
like to know.
It seems that `#1`, the fan speed is controlled by BIOS and there's no changing that, `#2`
the system reliably overheats when performing memory heavy computing, this is not confined
to linux, even the venerable `memtest86+` causes the system to emergency-halt after 2
minutes of scanning.
Nobody seems to know much about this problem, likely because anyone with rudimentry
technical expertise knows better than to buy a computer from such a circus of an OEM, leaving
the rest of us poor fools, deceived by great tech specs and reasonable prices, fumbling in
the dark each with our own bucket of transistors and fail.
After updating the bios to see if the problem had been fixed (it hadn't, apparently useless
bios update process explained later), I began poking at some ACPI registers trying to figure
out what they did.
Toshiba has 5 `cooling_device` registers, found in `/sys/class/thermal/`. If one uses `acpi -V`
one will see the 5 listed (numbers shown by `acpi -V` are reverse of those in the sys directory,
we will use only the numbers in the sys directory). `acpi -V` shows `cooling_device5` as an
LCD, `cat /sys/class/thermal/cooling_device5/max_state` shows it to have a range of 0-7 and
writing to it causes the screen to dim, though I'm not entirely sure what it is cooling, one
cannot exclude the possibility that it is, still, a `cooling_device`.
`cooling_device0` has a range of 0-1 and `acpi -V` claims it is a fan, however writing numbers
neither increases nor decreases the speed of the system fan and we must conclude that it is
indeed a toy-lever.
Registers 1 and 2 seem to be linked together and they seem to control the processor speed
because when a 10 is written to one of them, the processor meter instantly rises, programs
which previously used very little processor time suddenly need a lot and - tellingly - the
tempreture stays low.
Registers 3 and 4 are rather more interesting, writing 10s to them causes the ACPI to react
by writing 3s to registers 1 and 2 (slowing down the processor somewhat). More interestingly,
reverting them back to zero (their initial state), returns the processor to it's normal speed
but causes a noticable tempreture drop!

### Test case
To test this thing, I used `memtester 1000` to abuse the memory, this caused tempreture to
rocket up to 90 degrees in about 30 seconds but by slamming these registers 3 and 4 in and
back out again, the tempreture dropped to 70 degrees where it stayed. The fact that the fix
is preserved even after putting these registers back to their original value tells me that
there is not some internal value like `do_not_spin_cpu_until_you_overheat_and_halt = true`
but it is indeed a genuine bug.
However, after starting another program (with memory stressor still running) the tempreture
rocketed back up to 85 degrees but again, writing to the registers brought it down.

### The script
I wrote a little script to automate this process, it reads the tempreture of the CPU and if
that goes over 75 degrees, it does the routine, I also included the fan register although
I'm not clear on whether it is necessary. Each of the registers is first read, then set to
it's highest value, then set back to it's original value, inexplicably fixing this bizarre
bug.


## Updating the bios
This is not a script, use your imagination. When you go to toshitba's helpful website, you
will find they ship the bios updates packaged as `.exe` files. This is probably logical as
anybody smart enough to buy one of their products likely doesn't know what an operating
system is, or bios for that matter... It would seem that the war is lost at the sight of an
`exe` file but being the cheap bastards they are, they used pirated WinRAR to generate a self
extracting zip so you can just unzip it using `unzip`. Now you're presented with an array of
files, some `.exe` file written in Visual Basic by an intern, a `.iso` file and some other
crap. The `.iso` is a bootable CD-ROM image for flashing the bios at boot time (CD-ROM is
an ancient device which looked like drink coasters and stored data for a few months before
corrupting it). One might assume that the ubuntu trick of writing the iso to a USB stick would
work, unfortunately no luck, however there is a perl script called `geteltorito` which is
capable of extracting the bootable harddrive image from the iso and *this* can be written to
USB.

    wget http://www.splode.com/~friedman/software/scripts/src/misc/geteltorito
    perl ./geteltorito -o os2012456b_620.img ./os2012456b_620.iso
    sudo dd if=./os2012456b_620.iso of=/dev/<yourUSBdevice>

Then reboot and you end up in freedos, these people couldn't even make a bootloader which
went directly to a user interface, clearly they don't expect their users to **EVER** update
the bios. Once you're in this freedos shell, you can type `flash` which starts their little
shell script to flash the bios. Although the computer got dangerously hot, it didn't halt
and the bios did update.
