# A Live Looper Script for Sonic Pi and TouchOSC

## Introduction

This is an application to capture and loop sound with Sonic Pi; recording and playback will be triggered and controlled with a [touchosc](https://hexler.net/docs/touchosc) interface. The sound is captured from the soundcard with the `live_audio`-functionality of Sonic Pi. The touchosc layout should work on a smartphone as well as any other tablet device where touchosc is running.

The idea behind it: If you want to play with Sonic Pi together with other musicians you can capture incomming sound, loop it and have some basic playback controls. I wanted to have an external controller so that I can do the recording and playback control of these captured loops without having to code. The (live) coding part is reserved for additional sounds and the manipulation of the recorded sounds.

## TouchOSC-Interface and Features

![Live Looper touchosc interface](overview.png?raw=true "Live Looper touchosc interface")

1. **Metronome Control**: The metronome is initially switched on; as soon as you have triggered recording one of the tracks, the metronome will start to count the respective cycle (e. g. 8 beats) stressing the first beat. You can deactivate it completely by pushing the button below the metronome volume fader (No. 1).
2. **Record Tracks**: You have 4 tracks (or loops) available (No. 2). Once you have selected one, it will recording as soon as a new loops starts (depending on the configured track length for the track you have chosen to record; the length is indicated in beats on the recording buttons).
3. **Play Tracks**: Use the green buttons to toggle track replay and set the volume with the track faders (No. 3).
4. **Low- and Highpass filters** For each track there is a low- (No. 4) and a hiphpass (No. 5) filter available.
5. **Feedback Loop**: The feedback loop (No. 6) is recording continuously: the live sound is fed back to the recording. There are 10 possible steps: the first step disables the loop; the next steps (buttons) continually inclease the fading length by incleasing the volume with which the loop will be (re-)recorded each run.

## Notes on Playing and Recording (a picture of 4 loop cycles)

The 'play' live loop is replaying the recorded sample if `t[n]_play == true` and cueing the recording live loop if `t[n]_rec == true`; the record live loop will record if `t[n]_rec == true` or just sleep for the configurated length.

Let's assume we are talking about track no 1, meaning live loop `:play_track1` and `:record_track1` both with a length of 8 beats and 4 cycles to see how play and record are working together:

key: - = 1 beat; ->1 = first run; x = some event (e. g. midi toggle or cue/sync)

```
:play_t1
 ->1                       ->2                       ->3                     ->4
| -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  - | - play recorded
           x              x                         x                            sample...
   toggle rec pressed     1. cue :record_track1
                          2. metronom signal in-    stop extra metronom signal
                             dicating recording:
                             "1...2...3.+.4..+"
 :record_t1
->1                       ->2                       ->3                      ->4
| -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  - | - just sleep...
                          x                         x                       x
                      picks up sync        1. syncs and starts recording    LED cleared
                                           2. blinking toggle LED           ^
                                                    ^                       |
                                                    |                       |
                                               [if controller accepts midi feedback]
```

In cycle 4 `:play_t1` will replay the recorded track1 if `t[1]_play` is true (= associated controller button 'on') and `:record_t1` will just sleep.

## Components

The script `touchosc-live-looper.rb` and of course the TouchOSC interface description `live-looper.touchosc`.

## Setup

To set the live looper up you will have to do at least the following:

* Install the touchosc layout on your smartphone: The file `live-looper.touchosc` in the folder `touchosc` is an archive containing a file `index.xml`. To install it on your mobile device download the [touchosc editor](https://hexler.net/software/touchosc), open `live-looper.touchosc` with it and use the [`sync function`](https://hexler.net/docs/touchosc-editor-sync) to transfer the layout to your smartphone.
* Configure touchosc app and your smarthone (assuming you have installed touchosc already)
  * Make sure your computer and the smartphone are on the same wifi network.
  * Enter the OSC dialogue in touchosc and set OSC to the IP of your computer.
  * Set the outgoing port to 4559.
  * Set the incomming port to 4000 (you can choose another port but you will then have to adjust `:port` in the controller script).
  * Note: The local IP address of you smartphone which will be display at the bottom of touchosc's OSC dialogue.
* Copy the files `touchosc-live-looper-init.rb` to your harddrive 
* Load the this file into Sonic Pi and do some basic configuration:
  * `:ip` of the mobile device
  * `:port`, which is the port on your mobile device
  * All the rest you can leave as it is for the start and adjust at a later time.
* Run the controller script in Sonic Pi and you should hear the metronome.
* I suggest that you start with the feedback loop. It is easy to handle and fun to play with!
* And - of course - you will need some sound input to record (accordingly you will have to configure your sound system which I do with Jack under Linux)

## Working with recorded loops

One of the more interesting things is to record some sound and work with it in a separate buffer.

All tracks can be addressed for further manipulation via: 

```
sample "~/.sonic-pi/store/default/cached_samples/t[1..4].wav
```

Synchronisation of all additional live_loops with:

```
sync: :play_t1[..4]
```

Try e. g. with a 4-beat-loop:

```
live_loop :my_track, sync: :play_t1 do
  sample "~/.sonic-pi/store/default/cached_samples/t1.wav", beat_stretch: 8
  sleep 8
end
```

Note: The path syntax is for Linux. You will have to adjust the path if working with Windows or MacOSX.
