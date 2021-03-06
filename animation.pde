// Copyright (C) 2015 evolveTD Copyright Holders

// create a new instance of this class
// add frames to it
// set the amount of ticks that it should play in
// run to your heart's delight

class Animation {
  ArrayList<PImage> frames;
  int duration; // in ticks
  int timer;
  boolean setduration;
  boolean looping;
  int tempduration;
  
  Animation () {
    frames = new ArrayList<PImage>();
    setduration = false;
    looping = false;
    duration = 1;
    timer = 0;
    animations.add(this);
  }
  
  void update() { // automatically updated every timestep that the program is running
    if (timer < duration-1) timer++;
    else if (setduration) {
      duration = tempduration;
      if (looping) timer = 0;
      else timer = duration-1; // this is to make sure the duration is never <= the timer, which would cause a out of bounds exception in the arraylist in currentFrame()
      setduration = false;
    }
    else if (looping) timer = 0;
  }
  
  void addFrame(PImage in) {
    frames.add(in);
    duration = (3*frames.size()); // at most 3 ticks per frame
    reset();
  }
  
  void reset() {
    looping = false;
    timer = duration-1;
  }
  
  void beginLooping() {
    reset();
    timer = 0;
    looping = true;
  }
  
  void play() {
    timer = 0;
  }
  
  void setDuration(int d) {
    tempduration = d;
    setduration = true;
  }
  
  void setDuration(int d, boolean ticksperframe) {
    tempduration = (d*frames.size());
    setduration = true;
  }
  
  boolean active() {
    return (timer < duration-1);
  }
  
  PImage currentFrame() {
    if (frames.size() == 0) return null;
    int index = (((int)(timer/((float)duration/frames.size())))+1);
    if (index == frames.size()) return frames.get(0);
    else return frames.get(index);
  }
  
  int currentFrameIndex() {
    if (frames.size() == 0) return 0;
    int index = (((int)(timer/((float)duration/frames.size())))+1);
    if (index == frames.size()) return 0;
    else return index;
  }
}
