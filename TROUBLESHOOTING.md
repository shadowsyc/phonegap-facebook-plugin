# Troubleshooting

If you cannot solve your issue here please check the **existing issues** on Github, if you still cannot find a solution please [create an issue](https://github.com/Wizcorp/phonegap-facebook-plugin/issues). 

When creating a Github issue **remember to**:

- List your platform!
- Provide sample code
- Provide a log (Xcode console or adb logcat)

Troubleshooting contents

- General
    - [How do I Build without Eclipse?](#how-do-i-build-without-eclipse) 
    - [How do I Add a Like Button?](#how-do-i-add-a-like-button)
    - [Where is the init API?](#where-is-the-init-api)
	- [How to install with NPM PhoneGap?](#how-to-install-with-npm-phonegap)

- Android
	- [No Reply From Login?](#no-reply-from-login) 
	- [My Hash Does Not Work, I am Using Windows](#my-hash-does-not-work-i-am-using-windows)
	- [Jar mismatch! Fix your dependencies](#jar-mismatch-fix-your-dependencies)

	
## How do I Build without Eclipse?

- Solution
    - Check the [Android Guide](https://github.com/Wizcorp/phonegap-facebook-plugin/blob/master/platforms/android/README.md)

## How do I Add a Like Button?

- Problem
    - I am trying to implement like button functionality in my app. Whenever user likes my facebook page, user will get rewards. So i have tried to implement this like button functionality as described here:
[https://developers.facebook.com/docs/plugins/like-button](https://developers.facebook.com/docs/plugins/like-button)
    
- Solution
    - It won't work for native apps because: [https://developers.facebook.com/docs/ios/like-button/](https://developers.facebook.com/docs/ios/like-button/) is not supported yet. **HOWEVER**; it can be done with the graph API [http://stackoverflow.com/questions/11915269/built-in-like-button-facebook-sdk-3-0](http://stackoverflow.com/questions/11915269/built-in-like-button-facebook-sdk-3-0)
    Things you have to take care of are :

    1. Your like button must not be the same (graphically) as the Facebook like button

    2. When you display your page / button you have to call the getLoginStatus method first to know if the current user is connected to its Facebook account. If he is connected then call `GET` [https://graph.facebook.com/me/og.likes?access_token=FB_ACCESS_TOKEN&object=URL_TO_LIKE](https://graph.facebook.com/me/og.likes?access_token=FB_ACCESS_TOKEN&object=URL_TO_LIKE) with the Facebook Access Token returned by the g3. etAccessToken method (if this returns data then style your like button with a red heart for example, a grey heart if the call returns an empty array).

    3. To create a like (when your user clicks on your like button and your like button is a grey heart) do a POST on [https://graph.facebook.com/me/og.likes?access_token=FB_ACCESS_TOKEN&object=URL_TO_LIKE](https://graph.facebook.com/me/og.likes?access_token=FB_ACCESS_TOKEN&object=URL_TO_LIKE)

    4. To remove a like (when your user clicks on your like button and your like button is a red heart) do a `DELETE` on [https://graph.facebook.com/LIKE_IDENTIFIER?access_token=FB_ACCESS_TOKEN](https://graph.facebook.com/LIKE_IDENTIFIER?access_token=FB_ACCESS_TOKEN). The `LIKE_IDENTIFIER` is returned from steps 2 or 3.

The better way to understand this little "workflow" is to manipulate the Graph API on the og.likes endpoint using the [Facebook Graph Explorer](https://developers.facebook.com/tools/explorer) tool.

## Where is the init API?

- Problem
    - I was using `FB.init()` and now it's not working.

- Solution
    - You are using an out-dated API. Please check the [new API with sample code](https://github.com/Wizcorp/phonegap-facebook-plugin/blob/master/README.md) and sample projects in `platforms/ios` and `platforms/android`.

## How to install with NPM PhoneGap?

- Problem
    - I'm trying to install via https the Facebook plugin in iOS, but when I try the following line:
    
`sudo phonegap local plugin add https://github.com/phonegap/phonegap-facebook-plugin.git --variable APP_ID="12345678910" --variable APP_NAME="MyAPP"`

Im getting the message "[error] Variable(s) missing: APP_ID, APP_NAME"

- Solution
    - The `PhoneGap` CLI and `Cordova` CLI differ slightly you will need to run:

`git clone https://github.com/Wizcorp/phonegap-facebook-plugin`

`cd to/your/project`

`phonegap local plugin add /path/to/here/phonegap-facebook-plugin --variable APP_ID="12345678910" --variable APP_NAME="AwesomeApp"`

## No Reply From Login?
   
- Problem
    - **facebookConnectPlugin.login doesn't call neither success nor faillure methods.** - When I'm disconnected from Facebook and don't have the native app, the iframe fallback is blank. Checking on chrome inspector, the elements are set to display: none.

- Solution
    - Copy and paste the following code to print your hash. Add the hash to your Facebook Developer Dashboard.

```
try {
  PackageInfo info = 
  cordova.getActivity().getPackageManager().getPackageInfo("com.goapes.golearn", PackageManager.GET_SIGNATURES);
  
  for (Signature signature : info.signatures) {
      MessageDigest md = MessageDigest.getInstance("SHA");
      md.update(signature.toByteArray());
      Log.e("MY KEY HASH:", Base64.encodeToString(md.digest(), Base64.DEFAULT));
  }

} catch (NameNotFoundException e) {

} catch (NoSuchAlgorithmException e) {

}
```

## My Hash Does Not Work, I am Using Windows

- Problem
    - Windows users have to be careful about openssl-for-windows [http://code.google.com/p/openssl-for-windows/downloads/list](http://code.google.com/p/openssl-for-windows/downloads/list), the latest version, at least on plataform 64bit, does not generate the correct hash that Facebook needs for android apps.

- Solution
    - Use one of these versions when creating your hash: **openssl-0.9.8e_X64.zip** or **openssl-0.9.8d_X64.rar**

You should **not** use the openssl-0.9.8k_X64.zip.

## Jar mismatch! Fix your dependencies

- Problem
    - I get this error:

```
BUILD FAILED
/usr/local/opt/android-sdk/tools/ant/build.xml:577: Jar mismatch! Fix your dependencies
```

- Solution
    - You may have duplicate android-support-v4.jar files. Remove android-support-v4.jar from the `/libs` folder of your project.