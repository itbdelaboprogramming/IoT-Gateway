# IoT-Gateway
Development of IoT gateway system for internet communication by using Raspberry-Pi.

The Raspberry-Pi can also be used as a router (internet gateway) for other device that is connected through the ethernet port.

This is the installation procedure for Waveshare SIM7600G-H 4G HAT module.
It has been tested for:
* RaspberryPi 3B+/4/Zero W2,
* OS Raspbian Buster (legacy), Raspbian Lite 32 bit, Ubuntu 18 Mate (arm)

For remote access functionality, follow the instruction on [ZeroTier](https://www.zerotier.com/) for creating a virtual LAN.

## Installation
For first installation, after the SIM Hat (hardware) module is installed, power up the RaspberryPi and copy the folder `simhat_code` to directory `/home/$(logname)/` or `~/`

Then, do these steps on the terminal:
1. Open terminal, run `init_dial.bash`, and input the APN, username, password for the SIM card.
```
sudo bash simhat_code/init_dial.bash
```
2. Follow the instructions on the terminal.
3. Close terminal when it is done.

After this, the RaspberryPi will automatically use SIM Card to access the internet when when Wi-Fi is not available.

## Notes:
If the RaspberryPi does not complete its boot-up after the SIM Hat (hardware) module is installed, the SIM Hat module may have interrupted the boot sequence. 

To solve this issue, do these steps:
1. Plug monitor and keyboard onto the Raspberry Pi then power it up
2. When the boot stops, you should be in U-boot terminal. Press enter.
3. type these commands:
```
setenv bootdelay -2
saveenv
boot
```
4. The boot sequence should continue. You can unplug the monitor and keyboard when the boot-up finished.

## 設置方法
リモートアクセス機能については、[ZeroTier](https://www.zerotier.com/) での仮想LANの作成方法に従ってください。

初回インストール時は、SIMハット（ハードウェア）モジュールを初めてインストールしたら、RaspberryPiの電源を入れ、`simhat_code` フォルダを `/home/$(logname)/` または `~/` ディレクトリにコピーしてください。

次に、ターミナルで以下の手順を実行します：
1. ターミナルを開き、`init_dial.bash` を実行し、SIMカードの APN, username, password を入力します。
```
sudo bash simhat_code/init_dial.bash
```
2. 端末の指示に従う。
3. 終了したらターミナルを閉じます。

これで、Wi-Fiが使えないときに、raspberry Piが自動的にSIMカードを使ってインターネットにアクセスするようになります。

## 注釈
SIM Hat（ハードウェア）モジュールを装着した後、RaspberryPiが起動を完了しない場合、
SIM Hatモジュールがブートシーケンスを中断している可能性があります。

この問題を解決するには、次の手順を実行します：
1. モニターとキーボードをRaspberry Piに接続し、電源を投入します。
2. 起動が止まったら、U-bootのターミナルになります。エンターキーを押してください。
3. 以下のコマンドを入力します：
```
setenv bootdelay -2
saveenv
boot
```
4. ブートシーケンスが継続するはずです。起動が終了したら、モニターとキーボードを取り外してください。