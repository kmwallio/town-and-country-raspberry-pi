# Town and Country Raspberry Pi

This is a collection of scripts for managing and consuming media content
on a Raspberry Pi Client located in a Chrysler Town & Country 2005, or
any other compatible vehicle.

It's really chopped together...

The code has been tested on a Model B Raspberry Pi in a 2005 Chrysler
Town and Country.

Internet connection is not required, but **highly** recommended.  By
default, the script will shuffle music located on the device.  To
control playback, manage playlists, watch movies, or push new content
to the device, an internet connection is needed.  So you need it for
at least the initial setup and updates, but not for when you're
driving out in the middle of nowhere.

## Installation

You will need:

* mpg123
* omxplayer
* Perl
  * DBD::SQLite
  * MP3::Tag
  * Net::EasyTCP
  * JSON
* espeak
* cURL

Git clone, or download and copy the contents of this project to your
Raspberry Pi.  Edit `client.pl` to fit your paths and settings.  Create
a script for automatic startup of `client.pl`.

## Managing Your Pi

Install the server on your box somewhere, and make sure to have
pointed your client install to it.  Manage content from the
server.

## Why?

One of the problems I have and have noticed is people trying to
manage their media while driving.  It's pretty dangerous, especially
with how everything is touch screens now.  I found that an iPod
shuffle works well for me, but charging it, keeping it in sync,
and a lot of other things are hard to do.  Plus, I drive a mini-van
and it'd be cool to be able to watch videos.

Apple TV and Chromecast require constant internet connection, and they
don't store the content on the box.  A Raspberry Pi seemed cheap
enough and powerful enough to do what I wanted.  It was just a matter
of hacking something together to put on it.  My phone could act as
a hotspot, and would let it sync it's content.

Passengers could connect to the URL I give and control what's playing.

So I though it'd be a neat experiment.

## Potential Plans

* Add content locally, instead of 'Push'
* Gesture control to keep drivers off their phones (need to see if Pi can
  handle it)?
* Graphics for 'What's Playing' and 'What's Next'
* PodCast subscriptions?
* More settings in DB instead of hard coded
