
[EN]
This is the installation procedure for Waveshare SIM7600G-H-M2 4G HAT module.
It has been tested for:
    - RaspberryPi 3B+/4
    - OS Ubuntu 18 Mate

For first installation, after the SIM Hat (hardware) module is installed, power up the RaspberryPi and
copy the source code (.7z .bash .txt .deb) on directory "/home/$(logname)/" or "~/"

Then, do these steps on the terminal:

1) Open terminal, run init_dial.bash, and input the <APN>,<username>,<password> for the SIM card.
~$ sudo chmod +x simhat_code/init_dial.bash && sudo bash simhat_code/init_dial.bash

3) Close terminal when it is done.

After this, the RaspberryPi will automatically use SIM Card to access the internet when when WI-Fi is not available.

*Notes:
If the RaspberryPi does not complete its boot-up after the SIM Hat (hardware) module is installed,
the SIM Hat module may have interrupted the boot sequence. 
To solve this issue, do these steps:
1) Plug monitor and keyboard onto the Raspberry Pi the power it up
2) When the boot stops, you should be in U-boot terminal. Press enter.
3) type these commands:
    > setenv bootdelay -2
    > saveenv
    > boot
4) The boot sequence should continue. You can unplug the monitor and keyboard when the boot-up finished.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

[JP]
Waveshare SIM7600G-H-M2 4G HATモジュールのインストール手順です。
動作確認済みです：
    - RaspberryPi 3B+/4
    - OS Ubuntu 18 Mate

初回インストール時は、SIMハット（ハードウェア）モジュールを装着した後、
RaspberryPiの電源を投入し ソースコード（.7z .bash .txt .deb）をディレクトリ「/home/$(logname)/」または「~/」にコピーする。

次に、ターミナルで以下の手順を実行します：

1) ターミナルを開き、init_dial.bashを実行し、SIMカードの<APN>,<username>,<password>を入力します。
~$ sudo chmod +x simhat_code/init_dial.bash && sudo bash simhat_code/init_dial.bash

2) 終了したらターミナルを閉じます。

これで、WI-Fiが使えないときに、raspberry Piが自動的にSIMカードを使ってインターネットにアクセスするようになります。

*注釈
SIM Hat（ハードウェア）モジュールを装着した後、RaspberryPiが起動を完了しない場合、
SIM Hatモジュールがブートシーケンスを中断している可能性があります。
この問題を解決するには、次の手順を実行します：
1) モニターとキーボードをRaspberry Piに接続し、電源を投入します。
2) 起動が止まったら、U-bootのターミナルになります。エンターキーを押してください。
3) 以下のコマンドを入力します：
    > setenv bootdelay -2
    > saveenv
    > boot
4) ブートシーケンスが継続するはずです。起動が終了したら、モニターとキーボードを取り外してください。