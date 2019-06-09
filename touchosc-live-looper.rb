# TouchOSC Live Looper for Sonic Pi
# Filename: touchosc-live-looper.rb
# Project site and documentation: https://github.com/mbutz/sonic-pi-touchosc-live-looper
# License: https://github.com/mbutz/sonic-pi-touchosc-live-looper/blob/master/LICENSE
#
# Copyright 2018 by Martin Butz (http://www.mkblog.org).
# All rights reserved.
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#
# Sonic Pi is provided by Sam Aaron:
# https://www.sonic-pi.net
# https://github.com/samaaron/sonic-pi
# Please consider to support Sam financially via https://www.patreon.com/samaaron

#
# Live Looper Concept and Logic ##################################################################
#
# There are 2 live_loop types constantly running in parallel once you have started this script:
# play_t[n] and record_t[n]; length is set by :t[n]_len in the configuration section.
# These live_loops will be generated dynamically: if you set :track_conf[[...],[...]] you will
# get 2 tracks with 2 live_loops per track; you can configure as much tracks as you want. Note
# that for full functionality you'll need two midi toggles (play/record) and 3 rotaries (volume,
# lpf and hpf cutoff) per track. Essential are only the toggles. Of course you will have to set
# properties for all tracks in the configuration section below. Configure :track_conf as well
# as the other variables such as e. g. t[n]_len for track length in beats and t[n]_play (boolean)
# to indicate the starting value value for the play toggle (false = do not replay the loop).
#
# Notes on Playing and Recording (e. g. 4 cycles of the loops)
#
# The 'play' live_loop is replaying the recorded sample if t[n]_play == true and cueing the
# recording live_loop if t[n]_rec == true; the record live_loop will record if t[n]_rec == true
# or just sleep for configurated length.
#
# Let's assume we are talking about track no 1, meaning live_loop :play_track1 and :record_track1
# both with a length of 8 beats and 4 cycles to see how play and record are working together:
#
# key: - = 1 beat; ->1 = first run; x = some event (e. g. midi toggle or cue/sync)
#
# :play_t1
#  ->1                       ->2                       ->3                     ->4
# | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  - | - play recorded
#            x              x                         x                            sample...
#    toggle rec pressed     1. cue :record_track1
#                           2. metronom signal in-    stop extra metronom signal
#                              dicating recording:
#                              "1...2...3.+.4..+"
#  :record_t1
# ->1                       ->2                       ->3                      ->4
# | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  -  | -  -  -  -  -  -  -  - | - just sleep...
#                           x                         x                       x
#                       picks up sync        1. syncs and starts recording    LED cleared
#                                            2. blinking toggle LED           ^
#                                                     ^                       |
#                                                     |                       |
#                                                [if controller accepts midi feedback]
#
# In cycle 4 :play_t1 will replay the recorded track1 if t[1]_play # is true (= associated
# controller button 'on') and # :record_t1 will just sleep.
#
##################################################################################################

###################################################################################
# FIXME: Add more comments for starters
###################################################################################

# IP of Device running TouchOSC
set :ip, "[INSERT IP HERE]"
# Port configured on device running TouchOSC
set :port, [INSERT PORT NUMBER HERE]
use_osc get(:ip), get(:port)

set :my_bpm, 120 # set BPM

set :default_len_track, 8 # default track length
set :fb_track_len, 4

# Set :msg to 1 if you want some feedback such as volume changes
set :msg, 2 # 0 = none, 1 = info, 2 = debug
set :monitor, true
set :time_fix_play, 0.0 # latency fix

set :rec_metro, get(:metro_amp) # recording metro volume
set :master_amp_rec, 2.0 # recording master volume
set :master_amp_play, 1.0 # playback master volume

# In case you are using an Arturia Beatstep like me
set :sync_beatstep, 0

define :msg do | text, var=" " |
  puts "--------------------"
  puts "#{text} #{var}"
  puts "++++++++++++++++++++"
  puts "                    "
end

set :track_conf, [
  ["t1", :t1_len, :t1_amp, :t1_lpf, :t1_hpf, :t1_play, :t_rec_1_1, "/looper/t/rec/1/1"],
  ["t2", :t2_len, :t2_amp, :t2_lpf, :t2_hpf, :t2_play, :t_rec_2_1, "/looper/t/rec/2/1"],
  ["t3", :t3_len, :t3_amp, :t3_lpf, :t3_hpf, :t3_play, :t_rec_3_1, "/looper/t/rec/3/1"],
  ["t4", :t4_len, :t4_amp, :t4_lpf, :t4_hpf, :t4_play, :t_rec_4_1, "/looper/t/rec/4/1"]
]

set :t1_len, 8
set :t1_amp, 2
set :t1_lpf, 130
set :t1_hpf, 0
set :t1_play, 0
set :t_rec_1_1, 0

set :t2_len, 8
set :t2_amp, 2
set :t2_lpf, 130
set :t2_hpf, 0
set :t2_play, 0
set :t_rec_2_1, 0

set :t3_len, 4
set :t3_amp, 2
set :t3_lpf, 130
set :t3_hpf, 0
set :t3_play, 0
set :t_rec_3_1, 0

set :t4_len, 4
set :t4_amp, 2
set :t4_lpf, 130
set :t4_hpf, 0
set :t4_play, 0
set :t_rec_4_1, 0

set :fb_amp_1_1, 1
set :metro_on, 1
set :metro_amp, 0.5

osc "/looper/fb/amp/1/1", get(:fb_amp_1_1)
osc "/looper/metro/on", get(:metro_on)
osc "/looper/metro/amp", get(:metro_amp)

# Set all track settings in touchosc interface
tick_set :track_num, 1
get(:track_conf).size.times do
  tick(:track_num)
  osc "/looper/t/" + look(:track_num).to_s + "/len", get(("t" + look(:track_num).to_s + "_len").to_sym)
  osc "/looper/t/" + look(:track_num).to_s + "/amp", get(("t" + look(:track_num).to_s + "_amp").to_sym)
  osc "/looper/t/" + look(:track_num).to_s + "/lpf", get(("t" + look(:track_num).to_s + "_lpf").to_sym)
  osc "/looper/t/" + look(:track_num).to_s + "/hpf", get(("t" + look(:track_num).to_s + "_hpf").to_sym)
  osc "/looper/t/" + look(:track_num).to_s + "/play", get(("t" + look(:track_num).to_s + "_play").to_sym)
  osc "/looper/t/rec/" + look(:track_num).to_s + "/1", get(("t_rec_" + look(:track_num).to_s + "_1").to_sym)
end

define :parse_osc do |address|
  v = get_event(address).to_s.split(",")[6]
  if v != nil
    return v[3..-2].split("/")
  else
    return ["error"]
  end
end

live_loop :touchosc_multis do
  use_real_time
  adr   = "/osc/looper/*/*/*/*"
  data  = sync adr
  seg   = parse_osc adr
  label = seg[2].to_s + "_" + seg[3].to_s + "_" + seg[4].to_s + "_" + seg[5].to_s
  set label.to_sym, data[0]

  if seg[2].to_s == "fb"
    a = line 0.0, 1.45, steps: 10, inclusive: true
    a = [0.0, 0.35, 0.7, 0.8, 0.9, 1.05, 1.15, 1.25, 1.35, 1.45]
    case seg[5].to_s
    when "1"
      set :fb_amp, a[0]
    when "2"
      set :fb_amp, a[1]
    when "3"
      set :fb_amp, a[2]
    when "4"
      set :fb_amp, a[3]
    when "5"
      set :fb_amp, a[4]
    when "6"
      set :fb_amp, a[5]
    when "7"
      set :fb_amp, a[6]
    when "8"
      set :fb_amp, a[7]
    when "9"
      set :fb_amp, a[8]
    when "10"
      set :fb_amp, a[9]
    end
  end
end

live_loop :touchosc_metro do
  use_real_time
  adr   = "/osc/looper/*/*"
  data  = sync adr
  seg   = parse_osc adr
  label = seg[2].to_s + "_" + seg[3].to_s
  set label.to_sym, data[0]
  if get(:msg) == 2
    msg "var (single): ", label
    msg "sync (single): ", data
  end
end

live_loop :touchosc_track_settings do
  use_real_time
  adr   = "/osc/looper/*/*/*"
  data  = sync adr
  seg   = parse_osc adr
  label = seg[2].to_s + seg[3].to_s + "_" + seg[4].to_s
  set label.to_sym, data[0]

  # control ...
  if seg[4].to_s == "amp" || "lpf" || "hpf"
    ctrl = ("ctrl_" + seg[2].to_s + seg[3].to_s).to_sym # ctrl_t1
    # check that ctrl handle will be correctly set in play loops !!!
    opt = seg[4].to_sym
    control get(ctrl), opt=>data[0]
    if get(:msg) == 2
      msg "---> ctrl handle: ", ctrl
      msg "---> opt: ", opt
      msg "---> data: ", data[0]
    end
  end
  if get(:msg) == 2
    msg "var (tracks): ", label
    msg "sync (tracks): ", data
  end
end

use_bpm get(:my_bpm)
use_sched_ahead_time 1

# Start Metronome / Sync Beatstep                                  #
# -----------------------------------------------------------------#

live_loop :beat do
  s = sample :elec_tick, amp: get(:metro_amp) if get(:metro_on) == 1
  set :beat_metro, s # set pointer for control statement
  if get(:sync_beatstep) == 1
    midi_clock_beat
  end
  sleep 1
end

if get(:sync_beatstep) == 1
  midi_start
end

# Metronome                                                        #
# -----------------------------------------------------------------#
# marks the "1" in case a track is set up for recording
live_loop :metro_marking_one do
  sync :rec
  s = sample :elec_tick, amp: get(:metro_amp), rate: 0.75 if get(:metro_on) == 1
  set :marker_metro, s
  sleep get(:default_len_track)
end

# (Re)Play and Record Functions                                    #
# -----------------------------------------------------------------#
#
# All tracks can be addressed for further manipulation via:
# 'sample "~/.sonic-pi/store/default/cached_samples/t[1..4].wav"' resp.
# Synchronisation of all additional live_loops with: sync: :play_t1[..4]

# Dynamically builds as much play back live_loops as configurated
# if recording toggle true:
# 1. send cue and start metronome on loop run in advance (fix: will also run
# during recording as toggle is still true as long as the recording hasn't
# finished so use modulo and let metro only be audible _before_ recording
# 2. play recorded track[n] sample already contains if t[n]_play == true.
#
define :build_playback_loop do |idx|
  track_sample = buffer[get(:track_conf)[idx][0], get(get(:track_conf)[idx][1])]
  ctrl = ("ctrl_" + (get(:track_conf)[idx.to_int][0])).to_sym
  live_loop ("play_" + (get(:track_conf)[idx.to_int][0])).to_sym do
    on get(get(:track_conf)[idx][6]) do
      cue :rec
      cnt = tick % 2
      in_thread do
        if cnt < 1
          n = get(get(:track_conf)[idx][1]) / 2.0
          sleep n
          n.times do
            m = sample :elec_tick, rate: 1.5, amp: get(:metro_amp) if get(:metro_on) == 1
            set :mute_metro, m
            sleep 1
          end
        end
      end
    end #on :t[n]_rec
    on get(get(:track_conf)[idx][5]) do
      time_warp get(:time_fix_play) do
        s = sample track_sample, amp: get(get(:track_conf)[idx][2]), lpf: get(get(:track_conf)[idx][3]), hpf: get(get(:track_conf)[idx][4])
        set ctrl, s
      end # time_warp
    end
    sleep get(get(:track_conf)[idx][1])
  end
end

# Dynamically builds as much recording live_loops as configurated
# in contrast to playback loops: Recording only works for one track at a time
#
# if recording toggle true:
# 1. set it to false, we only want to record one loop running
# 2. let LED blink (needs support from controller)
# 3. shut down live audio used for monitoring incoming sound while not recording
# 4. record to prepared buffer for loop length
# 5. stop recording and clear LED
# else just sleep for loop length
#
define :build_recording_loop do |idx|
  # for easy access to recording buffer name and live audio
  track_sample = buffer[get(:track_conf)[idx][0], get(get(:track_conf)[idx][1])]
  audio = ("audio_" + (get(:track_conf)[idx.to_int][0])).to_sym
  live_loop ("record_" + (get(:track_conf)[idx.to_int][0])).to_sym do
    if get(get(:track_conf)[idx][6]) == 1 # if :t[n]_rec true
      sync :rec
      #osc get(:track_conf)[idx][7], 1
      set get(:track_conf)[idx][6], 0 # :t[n]_rec
      in_thread do
        t = get(get(:track_conf)[idx][1])
        #get(get(:track_conf)[idx][1]).times do
        (2 * t).times do
          osc get(:track_conf)[idx][7], 1
          sleep 0.25
          osc get(:track_conf)[idx][7], 0
          sleep 0.25
        end
      end
      live_audio :mon, :stop
      with_fx :record, buffer: track_sample, pre_amp: get(:master_amp_rec) do
        live_audio audio, stereo: true
      end
      sleep get(get(:track_conf)[idx][1])
      live_audio audio, :stop
      osc get(:track_conf)[idx][7], 0
    elsif
      if get(:monitor)
        live_audio :mon, stereo: true # switch monitor on
      end
      sleep get(get(:track_conf)[idx][1])
    end
  end
end

# Create the play back and recording live_loops; look into track_conf to find out how many...
i = 0
# FIXME: On first run this throughs an error: "undefined method size"
get(:track_conf).size.times do |i|
  build_playback_loop(i)
  build_recording_loop(i)
  i =+ 1
end

# -----------------------------------------------------------------#
# Feedback Loop Section                                            #
# -----------------------------------------------------------------#

# Get feedback volume from touchosc
# Feedback volume = volume for rerecording pevious loop sound:
# the lower this is the faster the loop will fade.
# 0.00 = bottom button = no feedback loop
# 1.45 = top button = feedback loop will play forever allthough
# with every record the sound will change and probably loose quality.

# Set up feedback track ('tfb')
# Track can be addressed in a for further manipulation via:
# 'sample "~/.sonic-pi/store/default/cached_samples/tfb.wav"'
tfb = buffer[:tfb, get(:fb_track_len)]

live_loop :record_fb do
  with_fx :record, buffer: tfb, pre_amp: get(:fb_amp), pre_mix: 1 do
    sample tfb, amp: 1
    live_audio :audio_fb
  end
  sleep get(:fb_track_len)
end

# (Re)Play Tracks
live_loop :play_fb do
  sample tfb, amp: 1
  sleep get(:fb_track_len)
end
