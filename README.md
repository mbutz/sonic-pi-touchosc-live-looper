# A Live Looper Script for Sonic Pi and TouchOSC

## Introduction

This is an application to capture and loop sound with Sonic Pi; recording and playback will be triggered and controlled with a [touchosc](https://hexler.net/docs/touchosc) interface. The sound is captured from the soundcard with the `live_audio`-functionality of Sonic Pi. The touchosc layout is build for a smartphone but should also work on any tablet device where touchosc is running.

The idea behind it: If you want to play with Sonic Pi together with other musicians you can capture incomming sound, loop it and have some basic playback controls. I wanted to have an external controller so that I can do the recording and playback control of these captured loops without having to code. The (live) coding part is reserved for additional sounds and the manipulation of the recorded sounds.

## TouchOSC-Interface and Features

![Live Looper touchosc interface](overview.png?raw=true "Live Looper touchosc interface")

1. **Metronome Control**: The metronome is initially switched on but not audible; as soon as you have selected a track, the metronome will start to count the respective cycle (e. g. 8 beats) stressing the first beat. After you have recorded a track the metronome will silent again until you have selected a track again. You can deactivate it completely by pushing the button at the bottom. You can also adjust the volume with the slider. While e. g. changing the selection from a 4-beat- to an 8-beat-track it can seem that the metronome is suspending; this is due to the fact, that the metronome always waits until the next 8-beat-cycle will start (because you switched the tracks) and thus will wait 4 beats. 
2. **Tracks** 1 to 4: You have 4 tracks (or loops) available. Once you have selected one, it is armed for recording and will record after a) you pressed the `record button` and b) the current cycle has finished. The number shown at the top left corner indicates the length of the track in beats (initially all tracks a set to 8 beats but you can adjust that in `touchosc-live-looper.sps`). Any time Sonic Pi actually records, you will see a green LED on the left upper corner of the `track button`. After the recording has been done the LED will switch off and the track will be disarmed.
3. **Record**: Starts the recording if you have selected a track (see 2); it does so by running the library script.
4. **Playback Volume of Track 1-4** Volume of track 1 to 4. Set to 0 you can mute a track completely.
5. **Feedback Loop**: The feedback loop is recording continuously: the live sound is fed back to the recording. There are 6 possible steps: the first step, the blue button at the bottom, disables the loop; the next 4 steps control the fading length of what has been recorded. If you press the top blue button the loop will not fade - thus record everything on top of what has been recorded so far (of cause the quality of previous recordings will change/degrade because with every loop the record will be recorded again).

![Live Looper touchosc while recording](recording.png?raw=true "Live Looper touchosc while recording")

## Components

There are 4 files involved:
    
* **Setup Script** (`touchosc-live-looper.sps`) for setup and configuration. Conveniently I load this as a `snippet`, that's why the filename ends with ".sps". Snippets are so far an unsupported feature of Sonic Pi. See [here for more information](https://github.com/samaaron/sonic-pi/issues/587#issuecomment-131945899) about how to setup and use snippets. If you do not want to use snippets just load this file into a Sonic Pi buffer, adjust variables at the top and run it once. 
* **Initialisation** (`touchosc-live-looper-init.rb`) of the `touchosc` interface.
* **Libray** (`touchosc-live-looper-lib.rb`)
* **TouchOSC-layout**: The layout has been made for use on an Android smartphone (layout size 580x320 pixels). Do not unpack and edit this file manually but with touchosc editor available at: https://hexler.net/software/touchosc. Note: The layout contains an additional page with High- and Lowpassfilter for each of the recording tracks.

## Arturia MiniLab mkII Live Looper

The folder `arturia_live_looper` contains a midi version of the Live Looper that can be triggered using the Arturia MiniLab mkII Midi controller. (With the drawback that the MiniLab keyboard is not able to receive Midi control messages about the Live Loopers state.)

## Setup

To set the live looper up you will have to do at least the following:

* Install the touchosc layout on your smartphone: The file `live-looper.touchosc` in the folder `touchosc` is an archive containing a file `index.xml`. To install it on your mobile device download the [touchosc editor](https://hexler.net/software/touchosc), open `live-looper.touchosc` with it and use the [`sync function`](https://hexler.net/docs/touchosc-editor-sync) to transfer the layout to your smartphone.
* Configure touchosc app and your smarthone (assuming you have installed touchosc already)
  * Make sure your computer and the smartphone are on the same wifi network.
  * Enter the OSC dialogue in touchosc and set OSC to the IP of your computer.
  * Set the outgoing port to 4559.
  * Set the incomming port to 4000 (you can choose another port but you will then have to adjust `:port` in the controller script).
  * Note: The local IP address of you smartphone which will be display at the bottom of touchosc's OSC dialogue.
* Copy the files `touchosc-live-looper-init.rb` and `touchosc-live-looper-lib.rb` to your harddrive 
* Load the controller script `touchosc-live-looper.sps` into Sonic Pi and do some basic configuration:
  * `:ip` of the mobile device
  * `:port`, which is the port on your mobile device
  * Set the path of the library script via the variable `:path`.
  * All the rest you can leave as it is for the start and adjust at a later time.
* Run the controller script in Sonic Pi and you should hear the metronome.
* I suggest that you start with the feedback loop. It is easy to handle and fun to play with!
* And - of course - you will need some sound input to record (accordingly you will have to configure your sound system which I do with Jack under Linux)

## Working with recorded loops

One of the more interesting things is to record some sound and work with it in a separate buffer. You can address all 4 tracks (and the feedback loop) for further manipulation in a separate buffer via:

```
sample "~/.sonic-pi/store/default/cached_samples/track[1..4].wav"
sample "~/.sonic-pi/store/default/cached_samples/tfb.wav"
```

Try e. g. with a 4-beat-loop:

```
live_loop :my_track, sync: :t1 do # for syncing also available: :t[1..4]
  sample "~/.sonic-pi/store/default/cached_samples/track1.wav", beat_stretch: 8
  sleep 8
end
```

Note: The path syntax is for Linux. You will have to adjust the path if working with Windows or MacOSX.

## TODOs

Less redundant code: The code could be much shorter and less redundant if I used functions at the appropriate places. I have not found the time to do that.

Latency: I think the `live looper` shows a latency which I could not track down yet. I'd appreciate some feedback on this if someone has an idea where this comes from and how it could be resolved.
