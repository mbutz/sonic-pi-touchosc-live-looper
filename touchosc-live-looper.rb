# TouchOSC Live Looper
# ====================

# IP of Device running TouchOSC
set :ip, "192.168.42.129"
# Port configured on device running TouchOSC
set :port, 9000
use_osc get(:ip), get(:port)

set :my_bpm, 120 # set BPM

set :default_len_track, 8 # default track length
set :fb_track_len, 8


# Set :msg to 1 if you want some feedback such as volume changes
set :msg, 1 # 0 = none, 1 = info, 2 = debug
set :monitor, true
set :time_fix_play, 0.0 # latency fix

set :rec_metro, get(:metro_amp) # recording metro volume
set :master_amp_rec, 2.0 # recording master volume
set :master_amp_play, 1.0 # playback master volume

set :sync_beatstep, 1

define :msg do | text, var=" " |
  puts "--------------------"
  puts "#{text} #{var}"
  puts "++++++++++++++++++++"
  puts "                    "
end

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

osc "/looper/fb/amp/1/1", get(:fb_1_1)
osc "/looper/metro/on", get(:metro_on)
osc "/looper/metro/amp", get(:metro_amp)

osc "/looper/t/1/len", get(:t1_len)
osc "/looper/t/1/amp", get(:t1_amp)
osc "/looper/t/1/lpf", get(:t1_lpf)
osc "/looper/t/1/hpf", get(:t1_hpf)
osc "/looper/t/1/play", get(:t1_play)
osc "/looper/t/rec/1/1", get(:t_rec_1_1)

osc "/looper/t/2/len", get(:t2_len)
osc "/looper/t/2/amp", get(:t2_amp)
osc "/looper/t/2/lpf", get(:t2_lpf)
osc "/looper/t/2/hpf", get(:t2_hpf)
osc "/looper/t/2/play", get(:t2_play)
osc "/looper/t/rec/2/1", get(:t_rec_2_1)

osc "/looper/t/3/len", get(:t3_len)
osc "/looper/t/3/amp", get(:t3_amp)
osc "/looper/t/3/lpf", get(:t3_lpf)
osc "/looper/t/3/hpf", get(:t3_hpf)
osc "/looper/t/3/play", get(:t3_play)
osc "/looper/t/rec/3/1", get(:t_rec_3_1)

osc "/looper/t/4/len", get(:t4_len)
osc "/looper/t/4/amp", get(:t4_amp)
osc "/looper/t/4/lpf", get(:t4_lpf)
osc "/looper/t/4/hpf", get(:t4_hpf)
osc "/looper/t/4/play", get(:t4_play)
osc "/looper/t/rec/4/1", get(:t_rec_4_1)

set :track_conf, [
  ["t1", :t1_len, :t1_amp, :t1_lpf, :t1_hpf, :t1_play, :t_rec_1_1, "/looper/t/rec/1/1"],
  ["t2", :t2_len, :t2_amp, :t2_lpf, :t2_hpf, :t2_play, :t_rec_2_1, "/looper/t/rec/2/1"],
  ["t3", :t3_len, :t3_amp, :t3_lpf, :t3_hpf, :t3_play, :t_rec_3_1, "/looper/t/rec/3/1"],
  ["t4", :t4_len, :t4_amp, :t4_lpf, :t4_hpf, :t4_play, :t_rec_4_1, "/looper/t/rec/4/1"]
]

define :parse_osc do |address|
  v = get_event(address).to_s.split(",")[6]
  if v != nil
    return v[3..-2].split("/")
  else
    return ["error"]
  end
end

# e. g. /osc/looper/t/rec/3/1
live_loop :touchosc_multis do
  use_real_time
  adr   = "/osc/looper/*/*/*/*"
  data  = sync adr
  seg   = parse_osc adr
  label = seg[2].to_s + "_" + seg[3].to_s + "_" + seg[4].to_s + "_" + seg[5].to_s
  set label.to_sym, data[0]
  
  msg "var (multi): ", label
  msg "sync (multi): ", data
end

live_loop :touchosc_metro do
  use_real_time
  adr   = "/osc/looper/*/*"
  data  = sync adr
  seg   = parse_osc adr
  label = seg[2].to_s + "_" + seg[3].to_s
  set label.to_sym, data[0]
  
  msg "var (single): ", label
  msg "sync (single): ", data
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
    
    msg "---> ctrl handle: ", ctrl
    msg "---> opt: ", opt
    msg "---> data: ", data[0]
    
  end
  msg "var (tracks): ", label
  msg "sync (tracks): ", data
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
# 'sample "~/.sonic-pi/store/default/cached_samples/track[1..4].wav"' resp.
# Synchronisation of all additional live_loops with: sync: :play_track1[..4]

# Dynamically builds as much play back live_loops as configurated
# if recording toggle true:
# 1. send cue and start metronome on loop run in advance (fix: will also run
# during recording as toggle is still true as long as the recording hasn't
# finished so use modulo and let metro only be audible _before_ recording
# 2. play recorded track[n] sample already contains if t[n]_play == true.
#
# FIXME:
# Not sure if we need time_warp fix but it is a tool for fine-tuning any
# latency issues; if not needed it can be set to 0 in the configuration section
define :build_playback_loop do |idx|
  
  # FIXME: idx.to_int needed?
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
define :build_recording_loop do |idx|
  
  # for easy access to recording buffer name and live audio
  track_sample = buffer[get(:track_conf)[idx][0], get(get(:track_conf)[idx][1])]
  
  # FIXME: idx.to_int needed?
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
tfb = buffer[:tfb, 8]

# TODO: We need 10 Loops because we have 10 amp buttons


#
# ... 8 more loops (please automate the loop generation ...)
#




live_loop :record_fb do
  stop
  with_fx :record, buffer: tfb, pre_amp: get(:fb_amp), pre_mix: 1 do
    sample tfb, amp: 1
    live_audio :audio_fb
  end
  sleep get(:fb_track_len)
end

# (Re)Play Tracks
live_loop :play_fb do
  stop
  sample tfb, amp: 1
  sleep get(:fb_track_len)
end
