# Linux.Sulla

### Sulla potuit, ego non potero?
![sulla](https://brewminate.com/wp-content/uploads/2018/08/083018-21-Lucius-Cornelius-Sulla-Rome-Roman-Republic-Ancient-History.jpg)

![poc image](https://i.imgur.com/cm5D1ot.png)

### About
**This is not a good or practical piece of VX, just a proof of concept to learn infection methods and basic anti virtual-machine techniques.**


Infection occurs by coverting the target PT_NOTE section to PT_LOAD. I did not develop this technique and just wrote this to learn.



It uses a non destructive payload (local execve shellcode)



### To build
```
git clone https://github.com/0xroman1/Linux.Sulla.git
chmod +x build
./build
```


### Sources:
Please read from these people as they are a lot smarter than I am.


PT_NOTE Infection on SymbolCrash by @sblip   https://shorturl.at/uzVY7


LINUX.MIDRASHIM by @TMZvx                	https://shorturl.at/gkASV


LINUX.KROPOTKINE by @S01den @sblip           https://shorturl.at/kxHPQ


Returing to OEP despite PIE from tmpout      https://shorturl.at/hqxSU
