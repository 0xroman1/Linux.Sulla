# Linux.Sulla

### Sulla potuit, ego non potero?
![sulla](https://brewminate.com/wp-content/uploads/2018/08/083018-21-Lucius-Cornelius-Sulla-Rome-Roman-Republic-Ancient-History.jpg)

![poc image](https://i.imgur.com/cm5D1ot.png)

### About
**This is not a good or practical virus, just a proof of concept to learn infection methods and basic anti virtual-machine techniques.**


Infection occurs by coverting the target PT_NOTE section to PT_LOAD. I did not develop this technique and just wrote this to learn.



It uses a non destructive payload (local execve shellcode)



### To build
```
git clone https://github.com/0xroman1/Linux.Sulla.git
chmod +x build
./build
```
