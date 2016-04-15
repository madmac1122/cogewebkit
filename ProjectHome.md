CoGeWebKit is a Quartz Composer plugin that leverages WebKit to allow offscreen rendering of web technologies including interactive Flash and Java content. Control mouse input, browse normally and post process rendered web pages in Quartz Composer.


Universal Binary, 32/64 bit, 10.5.8 or later.

![http://farm5.static.flickr.com/4071/4462960984_fc4f5fa543.jpg](http://farm5.static.flickr.com/4071/4462960984_fc4f5fa543.jpg)


**Changelog**

**rc3:**
  * adds isActive input parameter to toggle rendering on/off
  * fixes a page loading issue
  * removes restriction of maximum rendering dimension
  * some other changes, fixes

**rc2:**
  * fixes issues with web services depend on User Agent, like TypeKit, from now the plugin tells it is Safari
  * fixes a bug where SWF audio playback won't stop when the rendering stopped
  * adds Hide Scrollbar feature
  * the window of WebView now non-defered, this fixes some CGError issues

**rc1:**
  * major rendering speed up
  * bug fixes



**beta3:**
  * major rendering speed up
  * fix threading issues outside QC
  * adds method to rendering flash content with Flash Plugin v10
  * mouse interaction for flash content works too
  * adds inputCharacter input

**beta2:**
  * fix rendering issue on Snow Leopard
  * fix threading-issue outside QC
  * adds Mouse Input handling
  * adds Built-in Mini-Browser with basic history handling
  * adds input for Javascript
  * adds output for HTML string
  * adds output for HTML Image elements, as a structure
  * adds output for download progress
  * other misc changes

**beta1:**
  * initial release