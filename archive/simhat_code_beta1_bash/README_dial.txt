
[EN]
This is the installation procedure for Waveshare SIM7600G-H-M2 4G HAT module.
It has been tested for:
    - RaspberryPi 3B+/4
    - OS Raspbian Buster (legacy)
    - JP Smart SIM card

For first installation, copy the source code (.7z .bash .txt .deb) on directory "/home/$(logname)/" or "~/"

Then, do these steps on the terminal:

1) Open terminal, run init_dial.sh, and input the <APN>,<username>,<password> for the SIM card.
~$ sudo chmod +x simhat_code/init_dial.bash && sudo bash simhat_code/init_dial.bash

3) Close terminal when it is done.

After this, the raspberry Pi will automatically use SIM Card to access the internet when when WI-Fi is not available.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

[JP]
Waveshare SIM7600G-H-M2 4G HATモジュールのインストール手順です。
動作確認済みです：
    - RaspberryPi 3B+/4
    - OS Raspbian Buster (レガシー)
    - JP スマートSIMカード

初回インストール時は、ソースコード（.7z .bash .txt .deb）をディレクトリ「/home/$(logname)/」または「~/」にコピーします。

次に、ターミナルで以下の手順を実行します：

1）ターミナルを開き、init_dial.shを実行し、SIMカードの<APN>,<username>,<password>を入力します。
~$ sudo chmod +x simhat_code/init_dial.bash && sudo bash simhat_code/init_dial.bash

2) 終了したらターミナルを閉じます。

これで、WI-Fiが使えないときに、raspberry Piが自動的にSIMカードを使ってインターネットにアクセスするようになります。