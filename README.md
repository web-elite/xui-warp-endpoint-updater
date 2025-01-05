[🇮🇷](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README-fa.md) | [🇺🇸]([/guides/content/editing-an-existing-page](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README.md))

# What is it ?
This script will automatically find the best Warp endpoint IP and place it in your x-ui panel and finally restart the xray core.
After the script has been run, you can choose how many hours it will automatically run and update the Warp endpoint IP.
This script will not interfere with your existing Warp settings.
Please make sure you have a backup of your Warp settings before running this script.

> Thanks Ptech From https://github.com/Ptechgithub/warp
> 
> Script By Me https://github.com/Web-Elite

# How To Install
> ⚠️ Note: Be sure the warp tag exists in your Outbounds in x-ui settings. (At least one warp tag is required.)
>
![Warp Tag exist in Outbands](https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/img/setting-xui.png "Warp Tag exist in Outbands")

1- Run the following line in the terminal
<pre>
bash <(curl -fsSL https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/install.sh)
</pre>
2- After executing the above command, just select an option. (Selecting this option is for the desired time for automatic script execution.)

3- Installation is complete.

> ⚠️ Note: Be sure to backup your x-ui panel database before running this script and make sure that the warp tag exists in your Outbounds.

